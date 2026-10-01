import SwiftUI

/// Apple Music search results. Clicking a song opens its station in Music.
struct SearchResults: View {
    @EnvironmentObject var model: MusicModel

    var body: some View {
        if model.searchResults.isEmpty {
            Text("No songs found.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(model.searchResults) { song in
                        SongRow(
                            title: song.trackName,
                            subtitle: song.artistName,
                            cover: Cover(image: nil, url: song.artworkURL(size: 100), size: 36),
                            duration: song.duration,
                            onTap: { model.startStation(from: song) }
                        ) {
                            StationButton { model.startStation(from: song) }
                        }
                    }
                }
            }
        }
    }
}

/// Library songs played recently. Clicking one starts its station;
/// the menu can play just that song or add it to a playlist.
struct RecentList: View {
    @EnvironmentObject var model: MusicModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Recently Played")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
            if model.recentlyPlayed.isEmpty {
                Text("Songs from your library that you've played lately show up here.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(model.recentlyPlayed) { track in
                            SongRow(
                                title: track.title,
                                subtitle: track.artist,
                                cover: Cover(image: nil, url: nil, size: 36),
                                duration: nil,
                                onTap: { Task { await model.startStation(title: track.title, artist: track.artist) } }
                            ) {
                                StationButton { Task { await model.startStation(title: track.title, artist: track.artist) } }
                                Menu {
                                    Button("Play Song") { model.play(track) }
                                    Divider()
                                    ForEach(model.playlists, id: \.self) { name in
                                        Button("Add to \(name)") { model.add(track, toPlaylist: name) }
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                }
                                .menuStyle(.button)
                                .buttonStyle(.plain)
                                .menuIndicator(.hidden)
                                .fixedSize()
                            }
                        }
                    }
                }
            }
        }
    }
}

struct StationButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) { Image(systemName: "dot.radiowaves.left.and.right") }
            .buttonStyle(.plain)
            .help("Start Station")
    }
}

/// Adds the current song (track nil) or a library song to one of your playlists.
struct PlaylistMenu: View {
    @EnvironmentObject var model: MusicModel
    let track: MusicApp.LibraryTrack?

    var body: some View {
        Menu {
            if model.playlists.isEmpty {
                Text("No playlists")
            }
            ForEach(model.playlists, id: \.self) { name in
                Button(name) { model.add(track, toPlaylist: name) }
            }
        } label: {
            Image(systemName: "text.badge.plus")
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Add to Playlist")
    }
}

struct SongRow<Actions: View>: View {
    let title: String
    let subtitle: String
    let cover: Cover
    let duration: TimeInterval?
    let onTap: () -> Void
    @ViewBuilder let actions: () -> Actions
    @State var isHovering = false

    var body: some View {
        HStack(spacing: 10) {
            cover
            VStack(alignment: .leading, spacing: 1) {
                Text(title).lineLimit(1)
                Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 0)
            if isHovering {
                actions()
            } else if let duration {
                Text(formatTime(duration))
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
