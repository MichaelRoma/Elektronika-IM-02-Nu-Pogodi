# Architecture

## Layers

`Domain/GameEngine.swift` owns value state, rules, a seeded PRNG, collision resolution, scoring, misses, mode restrictions, and difficulty. It imports only Foundation and has no wall-clock calls. Its `advance(seconds:)` accepts elapsed time; `advance(ticks:)` supports focused tests.

`Application/GameSession.swift` is the thin interface for starting, resetting, pressing, and advancing a game. It contains no view logic. A future handheld game can provide its own session and state while reusing the presentation shell, timer, sound service, and persistence pattern where suitable.

`Infrastructure/BeepAudio.swift` synthesizes and plays short PCM sounds through AVFoundation. `GameViewModel` owns the monotonic scheduling loop, local clock and alarm, and UserDefaults high scores. No infrastructure service is called from `GameEngine`.

`Presentation/ConsoleView.swift` scales the complete console and overlays buttons at fixed artwork coordinates. `LCDSegments.swift` assigns stable IDs and glass coordinates to eggs, wolf positions, misses, and hare. `LCDView.swift` switches the matching assets on or off and renders score digits as seven discrete strokes. Egg positions and wolf changes have no interpolated animation.

Dependencies point inward: Presentation → Application → Domain. Infrastructure is called by Presentation; Domain never imports SwiftUI, UIKit, Core Graphics, or AVFoundation.

## Timing and state

The app runs one async task. During gameplay it sleeps up to 250 ms, then sends measured monotonic elapsed time to the session. The domain consumes whole logical ticks and retains the remainder, independent of render frames. SwiftUI updates only on state or clock changes. The loop is cancelled while the scene is inactive, avoiding burst catch-up after backgrounding.

Each egg has one lane and integer step 0…4. At each tick an egg advances one step; on the next tick after step 4 it is caught or missed. Hare visibility affects miss size. A fixed seed gives a reproducible spawn order. `GameRules` centralizes values still requiring hardware calibration.

The view model publishes `GameState`. It translates event values to audio and persists best scores. The source of local time and calendar formatting stays outside the domain. The two recessed console buttons enter alarm/current time setting; the large controls then operate as in the manual.

## Assets

The source front view is in `References/`. `Tools/generate_assets.py` produces master PNGs in app `Resources/`; copies in `Assets.xcassets` are compiled for runtime. `console` is a case photo/print backing. `lcd_background` is a separate static glass/scenery layer. `wolf_right` and `egg` are switchable LCD cutouts. Digit, chick, hare, and rail shapes are code-defined LCD graphics.
