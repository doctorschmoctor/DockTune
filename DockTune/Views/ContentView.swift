import AppKit
import MusicKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: MusicModel
    @State private var searchText = ""
    @State private var tab = Tab.upNext

    enum Tab: String, CaseIterable {
        case upNext = "Up Next"
        case recent = "Recently Played"
    }

    var body: some View {
        VStack(spacing: 0) {
            if model.authorization == .authorized {
                player
            } else {
                AccessView()
            }
            Divider()
            footer
        }
        .task { await model.loadAfterAuthorization() }
    }

    private var player: some View {
        VStack(spacing: 12) {
            SearchField(text: $searchText)
                .padding([.horizontal, .top], 12)

            if let message = model.errorMessage {
                ErrorBanner(message: message) { model.errorMessage = nil }
                    .padding(.horizontal, 12)
            }
            if !model.canPlayCatalog {
                Text("Playing songs needs an Apple Music subscription.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if searchText.isEmpty {
                NowPlayingView()
                    .padding(.horizontal, 12)
                Picker("", selection: $tab) {
                    ForEach(Tab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(.horizontal, 12)

                switch tab {
                case .upNext: UpNextView()
                case .recent: SongList(songs: model.recentlyPlayed, emptyText: "Nothing played recently.")
                }
            } else {
                SongList(songs: model.searchResults, emptyText: "No songs found.")
            }
        }
        .task(id: searchText) {
            // Wait for a pause in typing before searching.
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await model.search(searchText)
        }
    }

    private var footer: some View {
        HStack {
            if model.isStartingStation {
                ProgressView().controlSize(.small)
                Text("Starting station…").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Quit DockTune") { NSApp.terminate(nil) }
                .buttonStyle(.borderless)
                .font(.caption)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

private struct AccessView: View {
    @EnvironmentObject private var model: MusicModel

    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "music.note.list")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text("DockTune needs access to Apple Music.")
            if model.authorization == .notDetermined {
                Button("Allow Access") { Task { await model.requestAccess() } }
                    .buttonStyle(.borderedProminent)
            } else {
                Text("Turn it on in System Settings › Privacy & Security › Media & Apple Music.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

private struct SearchField: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Search Apple Music", text: $text)
                .textFieldStyle(.plain)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct ErrorBanner: View {
    let message: String
    let dismiss: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            Text(message).font(.caption).foregroundStyle(.red)
            Spacer()
            Button(action: dismiss) { Image(systemName: "xmark") }
                .buttonStyle(.plain)
                .font(.caption)
        }
    }
}
