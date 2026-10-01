# DockTune

An Apple Music card in your Mac's menu bar, built on the Music app. Free:
no Apple Developer account needed. Click the ♪ at the top right of the screen
and a card drops down where you can:

- search Apple Music and click a song to open its station in Music
- see what's playing: cover, title, artist, album, a progress bar you can
  drag, and previous, play/pause and next
- favorite the current song, or add it to one of your playlists
- see library songs you played in the last two weeks; click one to start its
  station, or use its ⋯ menu to play it or add it to a playlist

What the free version can't do, because Music doesn't let other apps do it:

- show Music's Up Next list
- start a station without you seeing Music: Start Station opens the station
  in Music, and you may need to press Play there once
- add search results (songs not in your library) to a playlist

## Get it on your Mac

```sh
mkdir -p ~/Desktop/code && cd ~/Desktop/code
git clone https://github.com/doctorschmoctor/DockTune.git
open DockTune/DockTune.xcodeproj
```

Already cloned? `cd ~/Desktop/code/DockTune && git pull`.

## Build and run

Requirements: macOS 14+, Xcode 16+.

1. Open `DockTune.xcodeproj` and press ⌘R. It's signed to run locally, so no
   developer account is needed.
2. Click ♪ in the menu bar. When macOS asks "DockTune wants to control Music",
   click OK. If you dismissed it, turn it on in System Settings › Privacy &
   Security › Automation.

## How it's put together

- `DockTune/DockTuneApp.swift` puts the card in the menu bar (`MenuBarExtra`).
  `LSUIElement` keeps DockTune out of the Dock.
- `DockTune/MusicApp.swift` talks to the Music app with AppleScript.
- `DockTune/Catalog.swift` searches Apple Music with Apple's free iTunes Search
  API and opens a song's station (`ra.<song ID>`) in Music.
- `DockTune/MusicModel.swift` holds the card's state and refreshes it every
  second while the card is open.
- `DockTune/Views/` holds the card itself.
