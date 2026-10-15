# Elektronika IM-02 — Nu, Pogodi!

A SwiftUI iPhone recreation of the 1984 Soviet LCD egg-catching game. The whole console appears in landscape, with touch targets directly over the photographed buttons and discrete LCD element changes.

## Build and test

Requires Xcode 27 and an iOS simulator or device running iOS 18 or later.

```sh
xcodebuild -project 'Elektronika IM-02 — Nu, Pogodi.xcodeproj' \
  -scheme 'Elektronika IM-02 — Nu, Pogodi' \
  -destination 'platform=iOS Simulator,id=<installed-simulator-UUID>' \
  CODE_SIGNING_ALLOWED=NO build
swift test
```

To regenerate processed art from the supplied reference, install Pillow, NumPy, and OpenCV in a development virtual environment and run `python Tools/generate_assets.py` from the repository root.

`Package.swift` compiles the same Domain and Application sources for fast macOS unit tests. The Xcode project compiles those sources with the iOS app.

## Controls

- **Игра А / Игра Б:** start or restart either mode. Hold while not playing to preview that mode's local best score.
- **Four large red buttons:** choose the matching egg tray instantly.
- **Время:** leave a game or time setting and show the clock; stop a sounding alarm.
- **Upper recessed button beside bell:** enter alarm time setting and enable the alarm.
- **Lower recessed button beside musical note:** enter current time setting. Hold to mute or unmute effects.
- **While setting time:** left upper/lower selects AM/PM, right upper increments hour, right lower increments minute. Press **Время** to finish.

## Layout

- `Domain/`: deterministic rules and state.
- `Application/`: game session/use cases.
- `Infrastructure/`: synthesized sound.
- `Presentation/`: view model, scaled console, and switchable LCD.
- `Resources/` and `Assets.xcassets/`: processed artwork.
- `Tests/`: unit tests for movement, catches, misses, game modes, milestones, state and determinism.
- `Documentation/`: [research](Documentation/ORIGINAL_GAME_RESEARCH.md) and [architecture](Documentation/ARCHITECTURE.md).

## Known limits

Gameplay oscillator intervals, spawn sequence, hare timing, and sound pitches are calibrated approximations because the manual does not specify them. Wolf/hare/chick graphics are partial extractions or redraws rather than complete electrode scans. The supplied casing art is 2:1 whereas the manual specifies 112×67 mm; its shape is preserved without distortion, so the face proportions differ from a measured device. The alarm depends on the app remaining active. See the research notes for evidence and remaining comparison work.
# Elektronika-IM-02-Nu-Pogodi
