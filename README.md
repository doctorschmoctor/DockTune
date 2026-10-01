# DockTune

A tiny macOS app that puts Apple Music controls in its Dock icon's menu.
Right-click (or click and hold) the DockTune icon in the Dock to see what's
playing and to Play/Pause, skip to the Next Track or go to the Previous Track.

## Get it on your Mac

```sh
mkdir -p ~/Desktop/code && cd ~/Desktop/code
git clone https://github.com/doctorschmoctor/DockTune.git
open DockTune/DockTune.xcodeproj
```

## Build and run

Requirements: macOS 14+, Xcode 16+.

1. Open `DockTune.xcodeproj`.
2. Press ⌘R. The app is ad-hoc signed ("Sign to Run Locally"), so no Apple
   developer account is needed. To use your own team, pick it under
   Signing & Capabilities.
3. Right-click DockTune in the Dock. The first time it talks to Music, macOS
   asks "DockTune wants to control Music"; click OK. If you dismissed it, turn
   it back on in System Settings › Privacy & Security › Automation.

## How it works

- `DockTune/main.swift` starts a plain AppKit app with a Dock icon and no windows.
- `DockTune/AppDelegate.swift` builds the menu in `applicationDockMenu(_:)`,
  which macOS calls each time the Dock menu opens, so it is always current.
- `DockTune/MusicController.swift` drives the Music app with AppleScript
  (`NSAppleScript`). It checks Music is running first so opening the menu
  never launches Music by itself.
- `Config/Info.plist` holds the Automation prompt text and
  `Config/DockTune.entitlements` grants Apple Events under the hardened runtime.
  The app is not sandboxed.
