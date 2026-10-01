import AppKit

/// Drives the Music app over Apple Events (AppleScript).
/// The first call makes macOS ask "DockTune wants to control Music".
enum MusicApp {
    static let bundleID = "com.apple.Music"

    struct NowPlaying: Equatable {
        var isPlaying: Bool
        var title: String
        var artist: String
        var album: String
        var duration: TimeInterval
        var position: TimeInterval
        var persistentID: String
        var isFavorite: Bool
    }

    struct LibraryTrack: Identifiable, Hashable {
        var id: String // Music's persistent ID
        var title: String
        var artist: String
        var album: String
    }

    static var isRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).isEmpty
    }

    // MARK: Now playing

    static func nowPlaying() throws -> NowPlaying? {
        let output = try run("""
        set US to character id 31
        tell application "Music"
            if player state is stopped then return ""
            set t to current track
            set fav to false
            try
                set fav to favorited of t
            end try
            return (player state as string) & US & (name of t) & US & (artist of t) & US & (album of t) ¬
                & US & ((duration of t) * 1000 div 1) & US & ((player position) * 1000 div 1) ¬
                & US & (persistent ID of t) & US & (fav as string)
        end tell
        """).stringValue ?? ""
        let f = output.components(separatedBy: "\u{1F}")
        guard f.count == 8 else { return nil }
        return NowPlaying(
            isPlaying: f[0] == "playing",
            title: f[1],
            artist: f[2],
            album: f[3],
            duration: (Double(f[4]) ?? 0) / 1000,
            position: (Double(f[5]) ?? 0) / 1000,
            persistentID: f[6],
            isFavorite: f[7] == "true"
        )
    }

    /// The current track's embedded cover. Streamed songs often have none.
    static func currentArtwork() -> NSImage? {
        guard let data = try? run(#"tell application "Music" to return data of artwork 1 of current track"#).data else {
            return nil
        }
        return NSImage(data: data)
    }

    static func playPause() throws { try run(#"tell application "Music" to playpause"#) }
    static func nextTrack() throws { try run(#"tell application "Music" to next track"#) }
    static func previousTrack() throws { try run(#"tell application "Music" to previous track"#) }

    static func seek(to seconds: TimeInterval) throws {
        try run(#"tell application "Music" to set player position to \#(Int(seconds))"#)
    }

    static func setFavorite(_ favorite: Bool) throws {
        try run(#"tell application "Music" to set favorited of current track to \#(favorite)"#)
    }

    // MARK: Library

    /// Library songs played in the last two weeks, most recent first.
    static func recentlyPlayed(limit: Int = 25) throws -> [LibraryTrack] {
        let output = try run("""
        set US to character id 31
        set RS to character id 30
        set out to ""
        tell application "Music"
            set cutoff to (current date) - 14 * days
            repeat with t in (every track of library playlist 1 whose played date > cutoff)
                set out to out & (persistent ID of t) & US & (name of t) & US & (artist of t) ¬
                    & US & (album of t) & US & ((played date of t) - cutoff) & RS
            end repeat
        end tell
        return out
        """).stringValue ?? ""
        let rows = output.split(separator: "\u{1E}").map { $0.components(separatedBy: "\u{1F}") }
        return rows
            .filter { $0.count == 5 }
            .sorted { (Int($0[4]) ?? 0) > (Int($1[4]) ?? 0) }
            .prefix(limit)
            .map { LibraryTrack(id: $0[0], title: $0[1], artist: $0[2], album: $0[3]) }
    }

    static func play(_ track: LibraryTrack) throws {
        try run(#"tell application "Music" to play (first track of library playlist 1 whose persistent ID is "\#(escape(track.id))")"#)
    }

    /// Your own playlists that songs can be added to (no smart playlists or folders).
    static func playlists() throws -> [String] {
        let list = try run(#"tell application "Music" to return name of every user playlist whose smart is false and special kind is none"#)
        guard list.numberOfItems > 0 else { return [] }
        return (1...list.numberOfItems).compactMap { list.atIndex($0)?.stringValue }
    }

    /// Adds a library track, or the current track when `track` is nil, to a playlist.
    static func add(_ track: LibraryTrack?, toPlaylist name: String) throws {
        let source = track.map { #"(first track of library playlist 1 whose persistent ID is "\#(escape($0.id))")"# }
            ?? "current track"
        try run(#"tell application "Music" to duplicate \#(source) to user playlist "\#(escape(name))""#)
    }

    // MARK: Plumbing

    struct ScriptError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    @discardableResult
    private static func run(_ source: String) throws -> NSAppleEventDescriptor {
        var error: NSDictionary?
        guard let result = NSAppleScript(source: source)?.executeAndReturnError(&error) else {
            let message = error?[NSAppleScript.errorMessage] as? String ?? "Music didn't respond."
            throw ScriptError(message: message)
        }
        return result
    }

    private static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
    }
}
