# Color Library

English · [简体中文](README_zh.md)

Turn colors from the real world into a personal visual journal. A native SwiftUI iOS MVP that runs entirely on device, with no server, account, or third-party runtime dependencies.

## Getting started

Open `ColorLibrary.xcodeproj` in Xcode, select the **ColorLibrary** scheme and an iPhone simulator, then click Run. The deployment target is iOS 17. The project uses Swift 6 and requires Xcode 16 or later.

To run on a physical device, select your own Development Team under Signing & Capabilities. The repository does not include personal signing settings.

The project configuration lives in `project.yml`. After adding or removing files, you can regenerate the Xcode project with [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
xcodegen generate
```

The generated Xcode project is committed, so XcodeGen is not required to open and run the app.

## MVP scope

- **Live color capture**: Samples the center of the rear camera image, filters local highlights and very dark noise, and combines per-channel medians with temporal smoothing in OKLab. Supports exposure and white balance locking, with HEX and RGB values.
- **Photo palettes**: Imports a photo through the system photo picker or captures a snapshot of the camera video feed. Converts the image to sRGB and clusters colors by OKLab distance, returning up to five main colors with approximate area proportions. Solid-color images produce a single color instead of padding the palette.
- **Local library**: Saves names, collections, color values, dates, and photo copies. Supports search, single-color/palette filters, name and collection editing, and deletion.
- **Share cards**: Combines the photo, color strip, HEX values, and title into a native layout, rendered as a 1038-pixel-wide image and exported through the system share sheet.
- **Offline examples**: Two AI-generated photographs are clearly labeled as examples and do not prepopulate the user's library. Tapping one runs the real extraction algorithm.

Semantic color naming, surface color estimation, P3 output, aesthetic statistics, cloud sync, design tokens, and commercial color libraries are outside the first release's core workflow.

## Color accuracy and privacy

Values describe the sRGB colors in the current image, not calibrated surface colors. Lighting, HDR, white balance, and exposure all affect the result. Photo import handles EXIF orientation and maps wide-gamut content to sRGB; out-of-gamut colors may be clipped. Palette proportions are estimates from downsampled clustering. The MVP saves 720p video-frame snapshots, not full-resolution still photographs.

The photo picker provides only the photos the user selects, without requiring access to the entire library. Camera permission is requested only when entering the capture screen. Share cards leave the device only through an explicit user action in the system share sheet. The app itself makes no network requests and includes no advertising or analytics SDKs.

The library is stored in the app sandbox at `Documents/ColorLibrary`. The sole metadata source is `library.json`, and photos are stored by UUID. Metadata is written atomically before in-memory state is updated; deletion commits the metadata change before removing the photo. An unreadable metadata file is never overwritten with an empty library. Uninstalling the app deletes local collections, and share cards are not restorable database backups.

## Code structure

```text
Sources/ColorKit/        sRGB / OKLab, extraction, stable sampling, library models and persistence
Tests/ColorKitTests/     Algorithm and storage tests runnable across platforms
ColorLibrary/
  App/                  App entry point and about screen
  Capture/              Camera resources, image processing, import and save flows
  Library/              Library home, details, editing and filters
  Sharing/              Share card layout and system share sheet
  Design/               Small shared visual components
  Resources/            Offline assets, app icon and privacy manifest
ColorLibraryTests/      Image decoding and share rendering tests
ColorLibraryUITests/    End-to-end simulator tests
```

Camera resources are accessed only on a single serial queue, while UI state belongs to MainActor. Image downsampling and clustering run in background tasks. Collection lists, counts, and single-color/palette types are derived from saved entries rather than duplicated as separate state.

## Validation

The app builds successfully, and all 16 tests passed: 7 core tests, 7 image tests, and 2 UI tests. See the [validation record](docs/validation.md) (in Chinese) for execution details and physical-device testing still required.

```sh
swift test
xcodebuild -project ColorLibrary.xcodeproj -scheme ColorLibrary \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -derivedDataPath build -parallel-testing-enabled NO test CODE_SIGNING_ALLOWED=NO
```

UI tests use isolated UUID directories and do not clear the user's regular library. The import/example, save, relaunch-and-load, and sharing flows remain available in a simulator without a camera.

Physical-device checks are still needed for first-time camera permission approval and denial, exposure locking, capture stability under real lighting, backgrounding and camera interruption recovery, and saving photos through the system share sheet. Simulator tests do not replace hardware validation.

## Design and assets

Actual app output: [Home](docs/screenshots/home.png) · [Share preview](docs/screenshots/share-preview.png) · [Exported card](docs/screenshots/share-card.png).

The interface combines warm off-white surfaces, dark green accents, and photo-journal cards. The app icon is generated deterministically by `scripts/make-app-icon.swift`. The two sample photographs were generated with the built-in imagegen tool; prompts and asset paths are documented in the [asset notes](docs/assets.md) (in Chinese).

Color conversion uses the [OKLab matrices published by Björn Ottosson](https://bottosson.github.io/posts/oklab/). Camera capture uses [AVFoundation](https://developer.apple.com/documentation/avfoundation/avcapturesession), and photo import uses the system PhotosPicker.
