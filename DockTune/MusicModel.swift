import Foundation
import MusicKit

/// Everything DockTune knows about Apple Music: access, search, recents,
/// playlists, and the station currently queued in the player.
@MainActor
final class MusicModel: ObservableObject {
    @Published private(set) var authorization = MusicAuthorization.currentStatus
    @Published private(set) var canPlayCatalog = true
    @Published private(set) var searchResults: [Song] = []
    @Published private(set) var recentlyPlayed: [Song] = []
    @Published private(set) var playlists: [UserPlaylist] = []
    @Published private(set) var isStartingStation = false
    @Published var errorMessage: String?

    let player = ApplicationMusicPlayer.shared

    // MARK: Access

    func requestAccess() async {
        authorization = await MusicAuthorization.request()
        guard authorization == .authorized else { return }
        await loadAfterAuthorization()
    }

    func loadAfterAuthorization() async {
        guard authorization == .authorized else { return }
        if let subscription = try? await MusicSubscription.current {
            canPlayCatalog = subscription.canPlayCatalogContent
        }
        await loadRecentlyPlayed()
        await loadPlaylists()
    }

    // MARK: Search and recents

    func search(_ term: String) async {
        let term = term.trimmingCharacters(in: .whitespaces)
        guard !term.isEmpty else {
            searchResults = []
            return
        }
        do {
            var request = MusicCatalogSearchRequest(term: term, types: [Song.self])
            request.limit = 20
            let response = try await request.response()
            searchResults = Array(response.songs)
        } catch {
            report(error)
        }
    }

    func loadRecentlyPlayed() async {
        do {
            let url = URL(string: "https://api.music.apple.com/v1/me/recent/played/tracks?limit=20")!
            let response = try await MusicDataRequest(urlRequest: URLRequest(url: url)).response()
            let decoded = try JSONDecoder().decode(SongsResponse.self, from: response.data)
            var seen = Set<MusicItemID>()
            recentlyPlayed = decoded.data.filter { seen.insert($0.id).inserted }
        } catch {
            report(error)
        }
    }

    // MARK: Stations

    /// Plays `song` right away, then queues a station of songs like it:
    /// the artist's top songs mixed with top songs from similar artists.
    func startStation(from song: Song) async {
        isStartingStation = true
        defer { isStartingStation = false }
        do {
            player.queue = ApplicationMusicPlayer.Queue(for: [song])
            try await player.play()

            let mix = await stationSongs(like: song)
            if !mix.isEmpty {
                try await player.queue.insert(mix, position: .tail)
            }
        } catch {
            report(error)
        }
    }

    private func stationSongs(like song: Song) async -> [Song] {
        guard let artist = await catalogArtist(for: song),
              let detailed = try? await artist.with([.topSongs, .similarArtists])
        else { return [] }

        var pool = Array((detailed.topSongs ?? []).prefix(10))
        for similar in (detailed.similarArtists ?? []).prefix(8) {
            if let other = try? await similar.with([.topSongs]) {
                pool += (other.topSongs ?? []).prefix(5)
            }
        }

        var seen: Set<MusicItemID> = [song.id]
        var seenTitles: Set<String> = [song.title.lowercased()]
        let unique = pool.filter { candidate in
            seen.insert(candidate.id).inserted && seenTitles.insert(candidate.title.lowercased()).inserted
        }
        return Array(unique.shuffled().prefix(40))
    }

    /// Recently played items can be library songs, which don't carry catalog
    /// relationships, so fall back to finding the song in the catalog.
    private func catalogArtist(for song: Song) async -> Artist? {
        if let detailed = try? await song.with([.artists]),
           let artist = detailed.artists?.first,
           !artist.id.rawValue.hasPrefix("r.") { // "r." IDs are library artists

            return artist
        }
        var request = MusicCatalogSearchRequest(term: "\(song.title) \(song.artistName)", types: [Song.self])
        request.limit = 1
        guard let match = try? await request.response().songs.first,
              let detailed = try? await match.with([.artists])
        else { return nil }
        return detailed.artists?.first
    }

    // MARK: Playlists and ratings

    func loadPlaylists() async {
        do {
            let url = URL(string: "https://api.music.apple.com/v1/me/library/playlists?limit=100")!
            let response = try await MusicDataRequest(urlRequest: URLRequest(url: url)).response()
            let decoded = try JSONDecoder().decode(UserPlaylistsResponse.self, from: response.data)
            playlists = decoded.data.filter { $0.attributes?.canEdit ?? true }
        } catch {
            report(error)
        }
    }

    /// Adds the song to the playlist without touching what's playing.
    func add(_ song: Song, to playlist: UserPlaylist) async {
        let body: [String: Any] = ["data": [["id": song.id.rawValue, "type": song.libraryAwareType]]]
        await send("POST", "v1/me/library/playlists/\(playlist.id)/tracks", body: body)
    }

    func love(_ song: Song) async {
        let body: [String: Any] = ["type": "rating", "attributes": ["value": 1]]
        await send("PUT", "v1/me/ratings/\(song.libraryAwareType)/\(song.id.rawValue)", body: body)
    }

    private func send(_ method: String, _ path: String, body: [String: Any]) async {
        do {
            var request = URLRequest(url: URL(string: "https://api.music.apple.com/\(path)")!)
            request.httpMethod = method
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            _ = try await MusicDataRequest(urlRequest: request).response()
        } catch {
            report(error)
        }
    }

    private func report(_ error: Error) {
        errorMessage = error.localizedDescription
    }
}

// MARK: - Apple Music API payloads

/// Skips items that aren't songs (recently played can include music videos).
struct SongsResponse: Decodable {
    let data: [Song]

    private enum CodingKeys: String, CodingKey { case data }

    private struct MaybeSong: Decodable {
        let song: Song?
        init(from decoder: Decoder) throws { song = try? Song(from: decoder) }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        data = try container.decode([MaybeSong].self, forKey: .data).compactMap(\.song)
    }
}

struct UserPlaylistsResponse: Decodable {
    let data: [UserPlaylist]
}

struct UserPlaylist: Decodable, Identifiable, Hashable {
    struct Attributes: Decodable, Hashable {
        let name: String
        let canEdit: Bool?
    }

    let id: String
    let attributes: Attributes?

    var name: String { attributes?.name ?? "Untitled Playlist" }
}

extension Song {
    /// Library song IDs start with "i."; everything else is a catalog song.
    var libraryAwareType: String {
        id.rawValue.hasPrefix("i.") ? "library-songs" : "songs"
    }
}

extension MusicPlayer.Queue.Entry {
    var song: Song? {
        switch item {
        case .song(let song): return song
        default: return nil
        }
    }
}
