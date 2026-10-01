# DockTune

An Apple Music card in your Mac's menu bar. Click the ♪ at the top right of
the screen and a card drops down where you can:

- search Apple Music, or pick something you played recently
- click any song to start a station from it right away
- see the current song's cover, title, artist and a progress bar you can drag,
  with previous, play/pause and next
- see what's up next on the station and jump to any of it
- add a song to one of your playlists (without changing what's playing),
  Love it, or start a new station from it, from the ⋯ menu on each song

DockTune plays music itself through Apple's MusicKit, so the sound comes from
DockTune rather than the Music app. A station is the song you clicked
followed by about 40 songs from that artist and similar artists.

## Get it on your Mac

```sh
mkdir -p ~/Desktop/code && cd ~/Desktop/code
git clone https://github.com/doctorschmoctor/DockTune.git
open DockTune/DockTune.xcodeproj
```

Already cloned? `cd ~/Desktop/code/DockTune && git pull`.

## One-time MusicKit setup

Requirements: macOS 14+, Xcode 16+, an Apple Music subscription, and a paid
Apple Developer Program membership (MusicKit can't be turned on for a free
account).

1. In Xcode, select the DockTune target › Signing & Capabilities and choose
   your Team. Xcode registers the app ID `com.doctorschmoctor.DockTune` for you.
2. At developer.apple.com › Certificates, Identifiers & Profiles ›
   Identifiers, open `com.doctorschmoctor.DockTune`, go to the
   App Services tab, tick **MusicKit**, and save.
3. Press ⌘R. Click ♪ in the menu bar and choose Allow Access.

If search or playback says it can't get a developer token, step 2 hasn't
taken effect yet; it can take a few minutes after saving.

## How it's put together

- `DockTune/DockTuneApp.swift` puts the card in the menu bar (`MenuBarExtra`).
  `LSUIElement` keeps DockTune out of the Dock.
- `DockTune/MusicModel.swift` does access, search, recently played, playlists,
  Love and building stations. Recents, playlists and Love use the Apple Music
  API through `MusicDataRequest`.
- `DockTune/Views/` holds the card: now playing, the song lists and the ⋯ menu.
