import AppKit

/// Talks to the Music app over Apple Events (AppleScript).
/// The first call triggers macOS's "DockTune wants to control Music" prompt.
final class MusicController {
    static let bundleID = "com.apple.Music"

    enum PlayerState: String {
        case playing, paused, stopped, unknown
    }

    struct Track {
        let name: String
        let artist: String
        let album: String
    }

    var isRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: Self.bundleID).isEmpty
    }

    func launch() {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Self.bundleID) else { return }
        NSWorkspace.shared.openApplication(at: url, configuration: .init())
    }

    func playerState() -> PlayerState {
        guard let raw = run(#"tell application "Music" to return player state as string"#) else {
            return .unknown
        }
        return PlayerState(rawValue: raw) ?? .unknown
    }

    func currentTrack() -> Track? {
        let script = """
        tell application "Music"
            if player state is stopped then return ""
            set t to current track
            return (name of t) & linefeed & (artist of t) & linefeed & (album of t)
        end tell
        """
        guard let output = run(script), !output.isEmpty else { return nil }
        let parts = output.components(separatedBy: "\n")
        guard parts.count == 3 else { return nil }
        return Track(name: parts[0], artist: parts[1], album: parts[2])
    }

    func playPause() { run(#"tell application "Music" to playpause"#) }
    func nextTrack() { run(#"tell application "Music" to next track"#) }
    func previousTrack() { run(#"tell application "Music" to previous track"#) }

    @discardableResult
    private func run(_ source: String) -> String? {
        var error: NSDictionary?
        let result = NSAppleScript(source: source)?.executeAndReturnError(&error)
        if let error {
            NSLog("DockTune AppleScript error: %@", error)
            return nil
        }
        return result?.stringValue
    }
}
