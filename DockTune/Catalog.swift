import AppKit

/// Apple Music catalog lookups through Apple's free iTunes Search API
/// (no developer account needed), plus opening stations in the Music app.
enum Catalog {
    struct Song: Decodable, Identifiable, Hashable {
        let trackId: Int
        let trackName: String
        let artistName: String
        let collectionName: String?
        let artworkUrl100: String?
        let trackTimeMillis: Int?

        var id: Int { trackId }
        var duration: TimeInterval? { trackTimeMillis.map { Double($0) / 1000 } }

        func artworkURL(size: Int) -> URL? {
            artworkUrl100.flatMap { URL(string: $0.replacingOccurrences(of: "100x100", with: "\(size)x\(size)")) }
        }
    }

    private struct Response: Decodable {
        let results: [Song]
    }

    static var country: String {
        Locale.current.region?.identifier.lowercased() ?? "us"
    }

    static func search(_ term: String, limit: Int = 25) async throws -> [Song] {
        var components = URLComponents(string: "https://itunes.apple.com/search")!
        components.queryItems = [
            .init(name: "term", value: term),
            .init(name: "media", value: "music"),
            .init(name: "entity", value: "song"),
            .init(name: "limit", value: String(limit)),
            .init(name: "country", value: country),
        ]
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        return try JSONDecoder().decode(Response.self, from: data).results
    }

    /// Finds the catalog version of a song you know by title and artist.
    static func match(title: String, artist: String) async throws -> Song? {
        try await search("\(title) \(artist)", limit: 5).first {
            $0.artistName.localizedCaseInsensitiveContains(artist) || artist.localizedCaseInsensitiveContains($0.artistName)
        }
    }

    /// Opens the song's Apple Music station in the Music app without
    /// bringing Music to the front.
    /// Song stations use the ID "ra." followed by the song's catalog ID.
    static func openStation(for song: Song) {
        guard let url = URL(string: "https://music.apple.com/\(country)/station/station/ra.\(song.trackId)"),
              let music = NSWorkspace.shared.urlForApplication(withBundleIdentifier: MusicApp.bundleID)
        else { return }
        let running = NSRunningApplication.runningApplications(withBundleIdentifier: MusicApp.bundleID).first
        let musicWasVisible = running.map { !$0.isHidden } ?? false
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        configuration.addsToRecentItems = false
        NSWorkspace.shared.open([url], withApplicationAt: music, configuration: configuration) { app, _ in
            // Music can still show its window when it handles a link, so hide
            // it again, unless you already had Music open on screen.
            guard !musicWasVisible else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { app?.hide() }
        }
    }
}
