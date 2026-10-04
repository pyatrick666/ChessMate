# ♟️ ChessMate

> A modern Flutter chess application with AI, local multiplayer, and online multiplayer.

ChessMate is a mobile chess game built with Flutter and Dart. It provides multiple ways to play chess, including playing against an AI opponent, playing locally with another person, and competing online through real-time multiplayer rooms.

---

## ✨ Features

### 🤖 AI Chess

Play against the computer with multiple difficulty levels:

- Easy
- Medium
- Hard
- Stockfish-powered chess engine
- Legal move validation
- Checkmate detection
- Draw detection
- Game timers
- Win/Lose/Draw result dialogs

### 👥 Local Multiplayer

Play a two-player chess match on the same device.

### 🌐 Online Multiplayer

ChessMate includes real-time online multiplayer using WebSockets.

Features include:

- Create game rooms
- Join games using room codes
- Real-time move synchronization
- Server-side game state
- Player connection tracking
- Automatic reconnection
- Resignation
- Draw offers
- Rematches
- Connection status handling

### 🎨 User Interface

- Responsive Flutter interface
- Dark and light themes
- Mobile-friendly chess board
- Board orientation support
- Legal move indicators
- Game status information
- Responsive online lobby
- Loading/wake-up screen for the online server

### 📢 Advertising

ChessMate integrates Google AdMob with:

- Banner ads
- Interstitial ads
- App Open ads
- User consent management
- Privacy options
- Debug/test ad support

---

## 🛠️ Technology Stack

| Technology | Purpose |
|---|---|
| Flutter | Mobile application framework |
| Dart | Application programming language |
| Stockfish | Chess engine |
| chess.js | Server-side chess validation |
| Node.js | Multiplayer backend |
| WebSocket | Real-time communication |
| Provider | Flutter state management |
| Google Mobile Ads | Advertising |
| Render | Multiplayer server hosting |

---

## 🏗️ Architecture

```text
                    ChessMate
                        |
              ┌─────────┴─────────┐
              |                   |
        Flutter Client        Multiplayer Server
              |                   |
       ┌──────┼──────┐        Node.js
       |      |      |           |
      AI    Local  Online     WebSocket
       |             |           |
   Stockfish      Internet    chess.js
