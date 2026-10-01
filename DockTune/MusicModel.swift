import AppKit

/// State for the menu bar card: what's playing, search, recents and playlists.
@MainActor
final class MusicModel: ObservableObject {
    @Published private(set) var nowPlaying: MusicApp.NowPlaying?
    @Published private(set) var artwork: NSImage?
    @Published private(set) var searchResults: [Catalog.Song] = []
    @Published private(set) var recentlyPlayed: [MusicApp.LibraryTrack] = []
    @Published private(set) var playlists: [String] = []
    @Published var message: String?

    private var artworkTrackID: String?

    // MARK: Now playing

    /// Called about once a second while the card is open.
    func refresh() async {
        guard MusicApp.isRunning else {
            nowPlaying = nil
            artwork = nil
            return
        }
        let current = try? MusicApp.nowPlaying()
        if current != nowPlaying { nowPlaying = current }

        if let current, current.persistentID != artworkTrackID {
            artworkTrackID = current.persistentID
            artwork = MusicApp.currentArtwork()
            if artwork == nil { artwork = await catalogArtwork(for: current) }
        }
    }

    private func catalogArtwork(for track: MusicApp.NowPlaying) async -> NSImage? {
        guard let match = try? await Catalog.match(title: track.title, artist: track.artist),
              let url = match.artworkURL(size: 300),
              let response = try? await URLSession.shared.data(from: url)
        else { return nil }
        return NSImage(data: response.0)
    }

    func playPause() { perform(MusicApp.playPause) }
    func next() { perform(MusicApp.nextTrack) }
    func previous() { perform(MusicApp.previousTrack) }
    func seek(to seconds: TimeInterval) { perform { try MusicApp.seek(to: seconds) } }

    func toggleFavorite() {
        guard let nowPlaying else { return }
        perform { try MusicApp.setFavorite(!nowPlaying.isFavorite) }
    }

    // MARK: Search, recents, playlists

    func search(_ term: String) async {
        let term = term.trimmingCharacters(in: .whitespaces)
        guard !term.isEmpty else {
            searchResults = []
            return
        }
        do {
            searchResults = try await Catalog.search(term)
        } catch {
            message = error.localizedDescription
        }
    }

    func loadLibrary() {
        guard MusicApp.isRunning else { return }
        recentlyPlayed = (try? MusicApp.recentlyPlayed()) ?? []
        playlists = (try? MusicApp.playlists()) ?? []
    }

    func play(_ track: MusicApp.LibraryTrack) { perform { try MusicApp.play(track) } }

    /// Adds `track`, or the current song when nil, to a playlist without changing what's playing.
    func add(_ track: MusicApp.LibraryTrack?, toPlaylist name: String) {
        perform { try MusicApp.add(track, toPlaylist: name) }
        if message == nil { message = "Added to \(name)." }
    }

    // MARK: Stations

    func startStation(from song: Catalog.Song) {
        Catalog.openStation(for: song)
        message = "Opened the \(song.trackName) station in Music. Press Play there if it doesn't start."
    }

    func startStation(title: String, artist: String) async {
        do {
            guard let song = try await Catalog.match(title: title, artist: artist) else {
                message = "Couldn't find \(title) on Apple Music."
                return
            }
            startStation(from: song)
        } catch {
            message = error.localizedDescription
        }
    }

    private func perform(_ action: () throws -> Void) {
        do {
            message = nil
            try action()
            Task { await refresh() }
        } catch {
            message = error.localizedDescription
        }
    }
}
