import SwiftUI

@main
struct DockTuneApp: App {
    @StateObject private var model = MusicModel()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(model)
                .frame(width: 400, height: 400)
        } label: {
            Image(systemName: "music.note")
        }
        .menuBarExtraStyle(.window)
    }
}
