# ChessMate ♟️

**ChessMate** is a Flutter-based Android chess application created and developed by **Pratik Poudel**.

I built ChessMate to create a simple, clean and playable chess experience while practising practical software development concepts including application design, state management, algorithms, game logic, testing and Android development.

## 👨‍💻 About Me

**Pratik Poudel**  
Student Developer | Flutter & Dart

I created ChessMate as a personal software project to practise and demonstrate my skills in:

- Flutter and Dart development
- Mobile application UI design
- State management
- Algorithm implementation
- Chess and game logic
- Testing and debugging
- Android application development

## ♟️ About ChessMate

ChessMate lets users play chess against a computer, against another person on the same device, or online using private multiplayer rooms.

### Main features

- **Vs AI** mode
- **2 Players** mode
- **Online Multiplayer** mode
- Private room creation and 6-character room codes
- Real-time multiplayer moves over WebSockets
- Server-side legal move validation
- Automatic reconnection after temporary network/server disconnects
- **Easy, Medium and Hard** AI difficulty
- Legal chess move validation
- Check and checkmate detection
- Draw and stalemate detection
- Custom chess AI
- Undo and new-game functionality
- Board orientation
- Light and dark themes
- Settings
- How to Play section
- Full-screen gameplay
- Developer support options
- Google AdMob advertising
- Responsive portrait-friendly chessboard layout

## 🧠 Chess AI

The computer opponent uses a custom implementation built for ChessMate:

- **Minimax**
- **Alpha-beta pruning**
- **Piece-square-table (PST) evaluation**

The AI searches possible moves and evaluates chess positions to select a move for the computer.

The chess package is used for the underlying chess rules and legal move generation, while the AI decision-making system is implemented separately in ChessMate.

## 🌐 Online Multiplayer

ChessMate includes a standalone Node.js WebSocket multiplayer server in `server/`.

The online multiplayer system supports:

- Private room creation and joining
- 6-character room codes
- White/Black player assignment
- Server-authoritative legal move validation
- Turn enforcement
- Synchronized FEN game state
- Checkmate, stalemate and draw state
- Resignation
- Draw offers and acceptance
- Rematch requests
- Opponent connection status
- Temporary disconnect detection
- Reconnection using a room reconnect token
- Automatic client reconnect with increasing retry delays
- A 30-second reconnect window for interrupted sessions

### Production server

The production WebSocket endpoint is:

    wss://chessmate-online.onrender.com

The online lobby is configured to use this endpoint by default.

Because the production service uses a free hosting plan, the server may take a few seconds to wake after inactivity. The lobby displays a connection/wake message while establishing the connection.

### Run the multiplayer server locally

    cd server
    npm install
    npm start

The server listens on port `8080` by default. Set the `PORT` environment variable to use another port.

For local testing, point the online lobby at a WebSocket endpoint such as:

    ws://localhost:8080

## 🛠️ Tools & Technologies I Implemented

### Flutter & Dart

Used to build the Android application and its user interface.

### Provider

Used for application state management, including game state and settings.

### Chess package

Version: 0.8.1

Used for chess rules, legal move generation, board state and game-status handling.

### Custom Minimax + Alpha-beta AI

Implemented specifically for ChessMate to provide the computer opponent.

### Piece-square tables

Implemented as part of the AI evaluation system to consider piece positioning when evaluating moves.

### Google Mobile Ads

Version: 9.1.0

Implemented three AdMob formats:

- Banner Ads
- App Open Ads
- Interstitial Ads

Debug builds use Google's test ad IDs, while release builds use the configured production ad IDs.

### Material 3

Used for the application's modern Flutter interface and reusable UI components.

### Android

Configured ChessMate as an Android application and release APK.

### GitHub Actions

Used to automate project verification and Android release builds.

The workflow runs:

1. Flutter dependency installation
2. Flutter analysis
3. Flutter tests
4. Release APK build
5. APK artifact upload
6. GitHub Release creation

## 💰 Developer Support

ChessMate includes optional manual support methods for the developer:

- **eSewa**
- **Khalti**
- **Bank transfer**

These are manual support/donation options. They are **not an automated in-app payment gateway**.

## 🧪 Testing

The project includes Flutter tests for application functionality.

Before releasing changes, I use:

    flutter analyze
    flutter test

The GitHub Actions release workflow also builds the release APK, uploads the APK artifact and creates a GitHub Release.

> **Multiplayer testing note:** Automated Flutter builds verify the client code, but full online multiplayer and network-recovery behaviour should still be manually tested using two physical devices connected to the production server.

## 📁 Project Structure

    ChessMate/
    ├── lib/
    │   ├── engines/       # Custom chess AI
    │   ├── models/        # Application models
    │   ├── providers/     # Game and settings state
    │   ├── screens/       # Application screens
    │   ├── widgets/       # Chessboard, pieces, ads and UI widgets
    │   └── main.dart      # Application entry point
    ├── test/              # Flutter tests
    ├── android/           # Android configuration
    ├── server/             # Node.js WebSocket multiplayer server
    └── .github/
        └── workflows/     # Automated Android build/release

## 👤 Developer

**Pratik Poudel**

ChessMate is my project, and this repository contains the source code and implementation work behind the application.

---

**ChessMate ♟️ — Built with Flutter, Dart, algorithms, and a passion for chess.**

## Online Multiplayer Server

ChessMate now includes a standalone WebSocket server under `server/`.

### Run locally

```bash
cd server
npm install
npm start
```

The server listens on port `8080` by default. Set `PORT` to use another port.

The server is authoritative for:
- room creation and joining
- White/Black assignment
- legal move validation
- turn enforcement
- FEN/game state
- checkmate/stalemate/draw state
- resignation events
- draw offers
- rematches
- disconnect notifications

For local development, the server can be started with `npm start` and the lobby can be pointed at a local `ws://` endpoint. Production builds use the hosted `wss://chessmate-online.onrender.com` endpoint by default.

### Production status

The current `main` branch has a successful automated release build, including Flutter analysis, tests, release APK compilation, artifact upload and GitHub Release publishing.
