import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let music = MusicController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = makeMainMenu()
    }

    // Called every time the user right-clicks (or long-presses) the Dock icon,
    // so the now-playing info is always fresh.
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu()

        guard music.isRunning else {
            menu.addItem(item("Open Music", #selector(openMusic)))
            return menu
        }

        if let track = music.currentTrack() {
            menu.addItem(disabled(track.name))
            menu.addItem(disabled("\(track.artist) — \(track.album)"))
        } else {
            menu.addItem(disabled("Nothing playing"))
        }
        menu.addItem(.separator())

        let playPause = music.playerState() == .playing ? "Pause" : "Play"
        menu.addItem(item(playPause, #selector(togglePlayPause)))
        menu.addItem(item("Next Track", #selector(nextTrack)))
        menu.addItem(item("Previous Track", #selector(previousTrack)))
        return menu
    }

    // Keep running with no windows; the Dock menu is the whole UI.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    @objc private func togglePlayPause() { music.playPause() }
    @objc private func nextTrack() { music.nextTrack() }
    @objc private func previousTrack() { music.previousTrack() }
    @objc private func openMusic() { music.launch() }

    private func item(_ title: String, _ action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    private func disabled(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    private func makeMainMenu() -> NSMenu {
        let mainMenu = NSMenu()
        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit DockTune",
                        action: #selector(NSApplication.terminate(_:)),
                        keyEquivalent: "q")
        appItem.submenu = appMenu
        return mainMenu
    }
}
