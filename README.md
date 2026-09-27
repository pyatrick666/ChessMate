# ChessMate — Flutter Chess App

ChessMate is a complete Flutter chess application built for Android, iOS, web and desktop-capable Flutter environments. It combines a clean Material 3 interface with a legal chess rules engine and a custom minimax AI.

## Features

- Human vs AI mode
- Human vs Human mode
- Easy, Medium and Hard AI difficulty
- Minimax search with alpha-beta pruning
- Piece-square-table evaluation
- Legal chess moves, check, checkmate and draw detection
- Move history
- Undo and new-game controls
- Board orientation switch
- Light and dark themes
- Responsive Flutter UI
- Unit and widget tests
- Simple beginner-friendly project structure

## Technology

- Flutter / Dart
- Provider for state management
- `chess: ^0.8.1` for legal move generation, FEN/PGN support and game state

## Run the application

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

For a release APK:
```bash
flutter build apk --release
```

## AI notes

The AI evaluates material plus positional bonuses from piece-square tables. Alpha-beta pruning reduces the number of positions explored by minimax. Difficulty controls search depth:

- Easy: depth 1
- Medium: depth 2
- Hard: depth 3

The app is intended as an educational coursework/demo chess application rather than a replacement for a tournament engine such as Stockfish.

## Submission checklist

Before submitting or demonstrating the project, run:

```bash
flutter pub get
flutter analyze
flutter test
```

Then verify the home screen, game flow, legal moves, AI response, undo, settings, board orientation and dark theme.

## Credits / licensing

ChessMate application code is supplied as an educational project. The `chess` dependency remains under its own published license and should be retained through normal package dependency management.
