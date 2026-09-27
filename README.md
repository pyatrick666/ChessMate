# ChessMate ♟️

ChessMate is a Flutter chess app for Android with a clean Material 3 interface, legal chess rules, local multiplayer, and a custom minimax AI.

## Features

- **Vs AI** and **2 Players** modes
- **Easy / Medium / Hard** AI difficulty
- Legal move validation
- Check, checkmate, stalemate and draw detection
- Minimax + alpha-beta pruning
- Piece-square-table evaluation
- Full-screen chessboard during games
- Board orientation support
- Undo and new-game controls
- Move history and game status
- Light / dark theme
- Settings and How to Play screens
- Google AdMob integration:
  - Banner ads
  - App Open ads
  - Interstitial ads
- Developer support section with eSewa, Khalti and bank-transfer options
- Unit and widget tests

## Tech stack

- Flutter 3.47.3
- Dart 3.13.x
- Provider
- `chess: ^0.8.1`
- `google_mobile_ads`

The chess rules and move generation are handled by the `chess` package. The AI is a custom educational minimax implementation; it is not intended to replace Stockfish.

## Project structure

```text
lib/
├── engines/       # Chess AI
├── models/        # App models and enums
├── providers/     # Game/settings state
├── screens/       # Home, game, settings, how-to-play, about
├── widgets/       # Chessboard, pieces, ads and reusable UI
└── main.dart
test/              # Unit and widget tests
android/           # Android project configuration
.github/workflows/ # Automated Android release build
```

## Run locally

Install Flutter first, then:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

For Android:

```bash
flutter run -d android
```

## Build a release APK

```bash
flutter build apk --release
```

The generated APK is:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Automated GitHub release

Every push to `main` runs the Android release workflow. The workflow:

1. Installs Flutter and Java 17.
2. Installs dependencies.
3. Runs `flutter analyze`.
4. Runs `flutter test`.
5. Builds the release APK.
6. Uploads the APK as a workflow artifact.
7. Publishes a GitHub Release containing `app-release.apk`.

The latest release can be downloaded from:

**GitHub Releases:** https://github.com/pyatrick666/ChessMate/releases/latest

## AdMob

The app uses Google Mobile Ads. Debug builds use Google's Android test ad unit IDs; release builds use the configured production IDs.

**Important:** never click your own production ads while testing. Use debug builds/test ad units for development and testing.

Before publishing publicly, make sure the AdMob app/account, app-ads.txt requirements (if applicable), privacy disclosures, and consent/privacy requirements are configured for your distribution.

## Developer support

ChessMate includes optional support buttons for eSewa, Khalti and bank transfer. These are manual support options, not an in-app payment gateway.

## Testing checklist

Before a public release, verify:

- Home screen loads
- Vs AI starts correctly
- 2 Players starts correctly
- Easy / Medium / Hard difficulty changes correctly
- Legal moves work
- Check/checkmate/draw states display correctly
- Undo works
- New game works
- Board orientation works
- Theme switching works
- Settings persist correctly
- Ads load or fail gracefully
- Support dialogs open and close correctly
- No crashes when rotating/resizing the screen

Run:

```bash
flutter analyze
flutter test
```

## itch.io

ChessMate is currently distributed as an **Android APK**, so use an itch.io **Downloadable** project rather than the HTML5 browser-game uploader. Upload the release APK from the GitHub Releases page.

Do not upload the Flutter source ZIP as the playable Android build. Keep the source repository linked separately for transparency.

For itch.io, prepare:

- Game/project title: **ChessMate**
- Platform: **Android**
- File: `app-release.apk`
- Version: use the latest GitHub release version
- A short description and feature list
- Screenshots of the home screen and chessboard
- A clear note that the app is an Android APK

If you later create a Flutter Web build, that is a separate distribution. itch.io's HTML5 uploader expects a ZIP containing an `index.html` entry point and the required web assets.

## License

ChessMate is an educational/demo project. Third-party packages retain their respective licenses. Check each dependency's license before redistribution.
