import SwiftUI

@main
struct DockTuneApp: App {
    @StateObject private var model = MusicModel()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(model)
                .frame(width: 360, height: 580)
        } label: {
            Image(systemName: "music.note")
        }
        .menuBarExtraStyle(.window)
    }
}
