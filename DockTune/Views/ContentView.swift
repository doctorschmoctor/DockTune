import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: MusicModel
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 12) {
            SearchField(text: $searchText)
                .padding([.horizontal, .top], 12)

            if searchText.isEmpty {
                NowPlayingView()
                    .padding(.horizontal, 12)
                Divider()
                RecentList()
            } else {
                SearchResults()
            }

            if let message = model.message {
                MessageBar(text: message) { model.message = nil }
            }
            Divider()
            HStack {
                Spacer()
                Button("Quit DockTune") { NSApp.terminate(nil) }
                    .buttonStyle(.borderless)
                    .font(.caption)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .task {
            model.loadLibrary()
            while !Task.isCancelled {
                await model.refresh()
                try? await Task.sleep(for: .seconds(1))
            }
        }
        .task(id: searchText) {
            // Wait for a pause in typing before searching.
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            await model.search(searchText)
        }
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

private struct MessageBar: View {
    let text: String
    let dismiss: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            Text(text).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Button(action: dismiss) { Image(systemName: "xmark") }
                .buttonStyle(.plain)
                .font(.caption)
        }
        .padding(.horizontal, 12)
    }
}
