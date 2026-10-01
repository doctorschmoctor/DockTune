import MusicKit
import SwiftUI

struct NowPlayingView: View {
    @EnvironmentObject private var model: MusicModel
    @ObservedObject private var state = ApplicationMusicPlayer.shared.state
    @ObservedObject private var queue = ApplicationMusicPlayer.shared.queue

    var body: some View {
        if let entry = queue.currentEntry {
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    Cover(artwork: entry.artwork, size: 72)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.title).font(.headline).lineLimit(1)
                        Text(entry.subtitle ?? "").foregroundStyle(.secondary).lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    if let song = entry.song {
                        SongActions(song: song, showsStation: false)
                    }
                }
                ProgressBar(duration: entry.song?.duration ?? 0)
                controls
            }
        } else {
            Text("Search for a song or pick one you played recently to start a station.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 72)
        }
    }

    private var controls: some View {
        HStack(spacing: 28) {
            Button { Task { try? await model.player.skipToPreviousEntry() } } label: {
                Image(systemName: "backward.fill")
            }
            Button { togglePlayback() } label: {
                Image(systemName: state.playbackStatus == .playing ? "pause.fill" : "play.fill")
                    .font(.title)
            }
            Button { Task { try? await model.player.skipToNextEntry() } } label: {
                Image(systemName: "forward.fill")
            }
        }
        .buttonStyle(.plain)
        .font(.title2)
    }

    private func togglePlayback() {
        if state.playbackStatus == .playing {
            model.player.pause()
        } else {
            Task { try? await model.player.play() }
        }
    }
}

private struct ProgressBar: View {
    let duration: TimeInterval
    let player = ApplicationMusicPlayer.shared

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { _ in
            let elapsed = min(player.playbackTime, max(duration, 0))
            VStack(spacing: 2) {
                Slider(
                    value: Binding(get: { elapsed }, set: { player.playbackTime = $0 }),
                    in: 0...max(duration, 1)
                )
                .controlSize(.small)
                HStack {
                    Text(format(elapsed))
                    Spacer()
                    Text("-" + format(max(duration - elapsed, 0)))
                }
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
            }
        }
    }

    private func format(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded(.down))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

struct Cover: View {
    let artwork: Artwork?
    let size: CGFloat

    var body: some View {
        Group {
            if let artwork {
                ArtworkImage(artwork, width: size, height: size)
            } else {
                Image(systemName: "music.note")
                    .frame(width: size, height: size)
                    .background(.quaternary)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: size > 50 ? 8 : 4))
    }
}
