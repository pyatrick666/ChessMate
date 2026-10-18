# ♟️ ChessMate

**ChessMate** is a Flutter-based Android chess game by **Pratik Poudel**. Play against the computer, play locally with a friend, or challenge another player online with room-based multiplayer and real-time chat.

[![Latest Release](https://img.shields.io/github/v/release/pyatrick666/ChessMate?label=latest%20release)](https://github.com/pyatrick666/ChessMate/releases/latest)
[![Build APK](https://github.com/pyatrick666/ChessMate/actions/workflows/build-apk.yml/badge.svg)](https://github.com/pyatrick666/ChessMate/actions/workflows/build-apk.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.47.3-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)

## 🎮 Game Modes

- **Play vs AI** — choose Easy, Medium, or Hard difficulty and practice against the computer.
- **Local 2-player** — share one device for a face-to-face match.
- **Online multiplayer** — create a room or join a room code to play with another person over the internet.

## ✨ Features

### ♟️ Chess gameplay
- Legal move handling and move indicators
- Checkmate, stalemate, and draw detection
- Game clocks and time-out results
- Resignation, draw offers, and rematches
- Board orientation options
- Win, loss, and draw result dialogs

### 🌐 Online play
- Room creation and room-code joining
- Server-authoritative move validation with `chess.js`
- Real-time game-state synchronisation over WebSockets
- Opponent connection status and automatic reconnection support
- Resign, offer/accept draw, and rematch flow

### 💬 Live match chat
- Collapsible slide-up chat panel designed for mobile screens
- Real-time text messages between the two players in a room
- One-tap quick messages: **Good luck!**, **Well played!**, **Nice move!**, **Good game!**, and **Thanks!**
- Message timestamps and unread-message count
- Messages limited to 280 characters
- Server-side message validation, room-only delivery, and rate limiting
- Chat history limited to the current match and cleared when a rematch starts

### 🎨 App experience
- Responsive Flutter interface
- Theme support
- Online lobby and connection status feedback
- Support Developer options
- Google AdMob integration, including banner, interstitial, and app-open ad components
- Consent and privacy options for advertising

## 🧰 Tech Stack

| Technology | Role |
|---|---|
| Flutter / Dart | Android app and UI |
| Stockfish | Chess engine integration |
| Provider | Flutter state management |
| `chess` | Client-side chess rules and move handling |
| Node.js | Online multiplayer server |
| `ws` (WebSocket) | Real-time game and chat communication |
| `chess.js` | Server-side chess rules and move validation |
| Google Mobile Ads | In-app advertising |
| Render | Multiplayer server hosting |
| GitHub Actions | Automated analysis, tests, APK builds, and releases |

## 🏗️ Architecture

```text
ChessMate Android App (Flutter)
  ├── Vs AI ─────────────── Stockfish
  ├── Local 2-player
  └── Online multiplayer
           │ WebSocket
           ▼
     Node.js server
       ├── Room management
       ├── Authoritative chess state (chess.js)
       ├── Move validation and synchronisation
       ├── Reconnection handling
       └── Room-scoped live chat
```

The multiplayer backend is in the `server/` directory. The server keeps active rooms and their chat history in memory; chat is not intended as a persistent messaging service.

## 📥 Download

Download the latest Android APK from **[GitHub Releases](https://github.com/pyatrick666/ChessMate/releases/latest)**.

- Android APK: `app-release.apk`
- Current release build targets **ARM64 Android devices**.
- The APK includes the native Stockfish library and can therefore be relatively large.

> Install APK files only from a source you trust. Android may ask you to allow installation from your chosen browser or file manager.

## 🚀 Run the Flutter App Locally

### Requirements
- Flutter stable (project CI uses Flutter 3.47.3)
- Dart SDK compatible with `pubspec.yaml`
- Android SDK / Android Studio for Android builds
- Git

### Clone and install dependencies

```bash
git clone https://github.com/pyatrick666/ChessMate.git
cd ChessMate
flutter pub get
```

### Run on a connected device or emulator

```bash
flutter run
```

### Run checks

```bash
flutter analyze
flutter test
```

### Build the ARM64 release APK

```bash
flutter build apk --release --target-platform android-arm64
```

The Android Gradle configuration excludes non-ARM64 Stockfish native libraries from the release APK to reduce its size.

## 🌐 Run the Multiplayer Server Locally

The server is a separate Node.js application in `server/`.

### Requirements
- Node.js and npm

### Install and start

```bash
cd server
npm install
npm start
```

The server listens on the port configured by the `PORT` environment variable (default: `8080`). Its health endpoint is:

```text
http://localhost:8080/health
```

The mobile app must be configured to use the WebSocket URL for the server you want to test. The production multiplayer service is hosted on Render; free hosting may take time to wake after inactivity.



## 🗂️ Project Structure

```text
ChessMate/
├── android/                  # Android platform and build configuration
├── lib/
│   ├── models/                # Game models and settings
│   ├── providers/             # App and game state
│   ├── screens/               # Home, lobby, and game screens
│   ├── services/              # Online services and networking
│   ├── utils/                 # Shared utilities and constants
│   └── widgets/               # Chessboards, pieces, ads, and UI widgets
├── server/                    # Node.js WebSocket multiplayer server
├── test/                      # Flutter tests
├── .github/workflows/         # CI and APK release workflow
├── pubspec.yaml               # Flutter dependencies and app metadata
└── README.md
```

## 🧭 Roadmap

Ideas for future development include:
- [ ] Player accounts and profiles
- [ ] Matchmaking and player ratings
- [ ] Friends and game history
- [ ] Additional board and piece customisation
- [ ] Expanded multiplayer and chat testing

## 👨‍💻 Developer

**Pratik Poudel**

- GitHub: [@pyatrick666](https://github.com/pyatrick666)


## ♟️ Play. Practice. Compete.

Built with Flutter and Dart.
