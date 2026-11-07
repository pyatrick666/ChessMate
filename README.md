# ChessMate

**ChessMate** is an Android chess application built with Flutter and Dart by **Pratik Poudel**. Play against an AI opponent, share one device for a local match, or challenge another player online with room-based multiplayer and real-time chat.

[![Latest Release](https://img.shields.io/github/v/release/pyatrick666/ChessMate?label=latest%20release)](https://github.com/pyatrick666/ChessMate/releases/latest)
[![Build APK](https://github.com/pyatrick666/ChessMate/actions/workflows/build-apk.yml/badge.svg)](https://github.com/pyatrick666/ChessMate/actions/workflows/build-apk.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.47.3-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)

> Screenshots and gameplay images will be added in a later update.

## Overview

ChessMate brings several ways to play chess into one mobile application. The Flutter client integrates a chess engine for AI play and communicates with a separate Node.js WebSocket service for online matches. The project explores chess logic, game-state synchronisation, mobile interface design, and automated Android builds.

## Features

### Game modes
- **Player vs AI:** Easy, Medium, or Hard difficulty.
- **Local 2-player:** play a shared-device match.
- **Online multiplayer:** create a room or join with a room code.

### Chess gameplay
- Legal move handling and move indicators
- Checkmate, stalemate, and draw detection
- Game clocks and timeout results
- Resignation, draw offers, and rematches
- Board orientation options and match result dialogs

### Online play and chat
- Room creation and room-code joining
- Server-authoritative move validation using `chess.js`
- Real-time game-state synchronisation over WebSockets
- Opponent connection status and reconnection support
- Room-based live chat with quick messages, timestamps, and unread counts
- Server-side message validation, room-scoped delivery, and rate limiting

### App experience
- Responsive Flutter interface and theme support
- Online lobby and connection status feedback
- Google AdMob integration and consent/privacy options

## Technology

| Technology | Purpose |
| --- | --- |
| Flutter / Dart | Android app and UI |
| Stockfish | Chess engine integration |
| Provider | Flutter state management |
| `chess` | Client-side chess rules |
| Node.js | Multiplayer server |
| `ws` (WebSocket) | Real-time match and chat |
| `chess.js` | Server-side chess rules and move validation |
| Google Mobile Ads | In-app advertising |
| Render | Multiplayer server hosting |
| GitHub Actions | Automated checks, APK builds, and releases |

## Architecture

```text
Flutter Android App
  ├── Player vs AI ─────── Stockfish
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

The backend lives in `server/`. Active rooms and chat history are held in server memory; chat is intended for the current match, not as a persistent messaging service.

## Download

Download the latest Android build from **[GitHub Releases](https://github.com/pyatrick666/ChessMate/releases/latest)**.

- Release asset: `app-release.apk`
- Current release build targets ARM64 Android devices.
- The APK includes the native Stockfish library and may be relatively large.

Only install APK files from sources you trust.

## Run locally

### Requirements
- Flutter stable (project CI uses Flutter 3.47.3)
- Dart SDK compatible with `pubspec.yaml`
- Android SDK / Android Studio for Android builds
- Git

### Install and run
```bash
git clone https://github.com/pyatrick666/ChessMate.git
cd ChessMate
flutter pub get
flutter run
```

### Run checks
```bash
flutter analyze
flutter test
```

### Build an ARM64 release APK
```bash
flutter build apk --release --target-platform android-arm64
```

## Multiplayer server

The server is a separate Node.js application in `server/`.

```bash
cd server
npm install
npm start
```

The server uses the `PORT` environment variable and defaults to `8080`. Its health endpoint is `http://localhost:8080/health`. For local multiplayer testing, configure the mobile app to use the WebSocket URL of the server you want to test. The production multiplayer service is hosted on Render; free hosting may take time to wake after inactivity.

## Project structure

```text
ChessMate/
├── android/                  # Android platform and build configuration
├── lib/
│   ├── models/               # Game models and settings
│   ├── providers/             # App and game state
│   ├── screens/               # Home, lobby, and game screens
│   ├── services/              # Online services and networking
│   ├── utils/                 # Shared utilities and constants
│   └── widgets/               # Chessboards, pieces, ads, and UI widgets
├── server/                    # Node.js WebSocket multiplayer server
├── test/                      # Flutter tests
└── .github/workflows/         # CI and APK release workflow
```

## Roadmap

- [ ] Player accounts and profiles
- [ ] Matchmaking and player ratings
- [ ] Friends list and match history
- [ ] More board and piece customisation
- [ ] Expanded multiplayer and chat testing

## Developer

**Pratik Poudel** · [GitHub](https://github.com/pyatrick666) · [Portfolio](https://pyatrick666.github.io/Professional-Portfolio/) · [Email](mailto:pyatrick666@gmail.com)

<div align="center">

**Play. Practice. Compete.**

</div>
