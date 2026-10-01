import SwiftUI

struct NowPlayingView: View {
    @EnvironmentObject var model: MusicModel

    var body: some View {
        if let track = model.nowPlaying {
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    Cover(image: model.artwork, url: nil, size: 72)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title).font(.headline).lineLimit(1)
                        Text(track.artist).foregroundStyle(.secondary).lineLimit(1)
                        Text(track.album).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    Button { model.toggleFavorite() } label: {
                        Image(systemName: track.isFavorite ? "star.fill" : "star")
                    }
                    .buttonStyle(.plain)
                    .help("Favorite")
                    PlaylistMenu(track: nil)
                }
                ProgressBar(position: track.position, duration: track.duration) { model.seek(to: $0) }
                HStack(spacing: 28) {
                    Button { model.previous() } label: { Image(systemName: "backward.fill") }
                    Button { model.playPause() } label: {
                        Image(systemName: track.isPlaying ? "pause.fill" : "play.fill").font(.title)
                    }
                    Button { model.next() } label: { Image(systemName: "forward.fill") }
                }
                .buttonStyle(.plain)
                .font(.title2)
            }
        } else {
            Text("Search for a song or pick one you played recently to start a station.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 72)
        }
    }
}

struct ProgressBar: View {
    let position: TimeInterval
    let duration: TimeInterval
    let seek: (TimeInterval) -> Void

    var body: some View {
        VStack(spacing: 2) {
            Slider(
                value: Binding(get: { min(position, duration) }, set: seek),
                in: 0...max(duration, 1)
            )
            .controlSize(.small)
            HStack {
                Text(formatTime(position))
                Spacer()
                Text("-" + formatTime(max(duration - position, 0)))
            }
            .font(.caption2.monospacedDigit())
            .foregroundStyle(.secondary)
        }
    }
}

func formatTime(_ seconds: TimeInterval) -> String {
    let total = Int(seconds.rounded(.down))
    return String(format: "%d:%02d", total / 60, total % 60)
}

/// Album art from either an image Music gave us or a catalog URL.
struct Cover: View {
    let image: NSImage?
    let url: URL?
    let size: CGFloat

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image).resizable().scaledToFill()
            } else if let url {
                AsyncImage(url: url) { $0.resizable().scaledToFill() } placeholder: { placeholder }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size > 50 ? 8 : 4))
    }

    private var placeholder: some View {
        Image(systemName: "music.note")
            .foregroundStyle(.secondary)
            .frame(width: size, height: size)
            .background(.quaternary)
    }
}
