# Rubber Band Ball

A small SwiftUI iOS arcade game prototype with a browser-playable web prototype for sharing.

## Current Build

- Four levels
- A rubber band ball that moves one grid tile at a time
- Single joystick control that resolves to up, down, left, or right
- Hold the joystick or arrow/WASD keys to keep advancing tile by tile
- Smooth ball travel between grid spaces
- Spinning rubber band collectibles
- Twenty rubber bands per level
- The ball grows as rubber bands are collected
- Move counter per level
- Restart current level control
- Level progression after collecting every band and reaching the exit
- Final reward scene: "The Rubber Band Ball" dance party with "You won! Have a ball!"

## Run

### Browser Prototype

Open `WebPrototype/index.html` directly in a browser, or serve it locally:

```sh
cd WebPrototype
python3 -m http.server 8000
```

Then open `http://localhost:8000`.

The web prototype mirrors the SwiftUI version and is the easiest build to share through GitHub Pages, Netlify, Vercel, or any static web host.

### iOS App

Open `RubberBandBall.xcodeproj` in Xcode, choose an iPhone simulator, then run the `RubberBandBall` scheme.

This machine is currently pointed at Command Line Tools instead of a full Xcode developer directory, so command-line simulator builds are not available until Xcode is selected with `xcode-select`.

## Next Art And Audio Hooks

- Replace the generated SwiftUI rubber band shapes with custom art.
- Add a `Music` asset and start playback when `VictoryView` appears.
- Replace the placeholder app icon in `Assets.xcassets/AppIcon.appiconset`.
