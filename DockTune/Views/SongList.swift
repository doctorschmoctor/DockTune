import MusicKit
import SwiftUI

/// Search results and recently played. Clicking a song starts a station from it.
struct SongList: View {
    @EnvironmentObject var model: MusicModel
    let songs: [Song]
    let emptyText: String

    var body: some View {
        if songs.isEmpty {
            Text(emptyText)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(songs) { song in
                        SongRow(title: song.title, subtitle: song.artistName, artwork: song.artwork, duration: song.duration) {
                            Task { await model.startStation(from: song) }
                        } actions: {
                            SongActions(song: song, showsStation: true)
                        }
                    }
                }
            }
        }
    }
}

/// Songs queued after the current one. Clicking one jumps to it.
struct UpNextView: View {
    @EnvironmentObject private var model: MusicModel
    @ObservedObject private var queue = ApplicationMusicPlayer.shared.queue

    private var upcoming: [MusicPlayer.Queue.Entry] {
        let entries = Array(queue.entries)
        guard let current = queue.currentEntry,
              let index = entries.firstIndex(where: { $0.id == current.id })
        else { return entries }
        return Array(entries[(index + 1)...])
    }

    var body: some View {
        if upcoming.isEmpty {
            Text("Songs from your station will show up here.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(upcoming) { entry in
                        SongRow(title: entry.title, subtitle: entry.subtitle ?? "", artwork: entry.artwork, duration: entry.song?.duration) {
                            queue.currentEntry = entry
                            Task { try? await model.player.play() }
                        } actions: {
                            if let song = entry.song {
                                SongActions(song: song, showsStation: true)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct SongRow<Actions: View>: View {
    let title: String
    let subtitle: String
    let artwork: Artwork?
    let duration: TimeInterval?
    let onTap: () -> Void
    @ViewBuilder let actions: () -> Actions
    @State var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            Cover(artwork: artwork, size: 36)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).lineLimit(1)
                Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 0)
            if isHovering {
                actions()
            } else if let duration {
                Text(String(format: "%d:%02d", Int(duration) / 60, Int(duration) % 60))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(isHovering ? Color.primary.opacity(0.06) : .clear)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onHover { isHovering = $0 }
    }
}

/// The "…" menu on a song: add to a playlist, love it, or start a station.
struct SongActions: View {
    @EnvironmentObject var model: MusicModel
    let song: Song
    let showsStation: Bool

    var body: some View {
        Menu {
            if showsStation {
                Button("Start Station") { Task { await model.startStation(from: song) } }
                Divider()
            }
            Menu("Add to Playlist") {
                if model.playlists.isEmpty {
                    Text("No playlists")
                }
                ForEach(model.playlists) { playlist in
                    Button(playlist.name) { Task { await model.add(song, to: playlist) } }
                }
            }
            Button("Love") { Task { await model.love(song) } }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
    }
}
