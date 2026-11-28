<div align="center">

# ♟️ ChessMate

**A production-grade multiplayer chess platform — Flutter mobile app + Next.js web client + Node.js backend**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Next.js](https://img.shields.io/badge/Next.js-14-000000?logo=nextdotjs)](https://nextjs.org)
[![Node.js](https://img.shields.io/badge/Node.js-20-339933?logo=nodedotjs)](https://nodejs.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-4169E1?logo=postgresql)](https://postgresql.org)
[![Docker](https://img.shields.io/badge/Docker-2496ED?logo=docker)](https://docker.com)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub_Actions-2088FF?logo=githubactions)](https://github.com/features/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

[Live Web App](https://chessmate.pratikpoudel.info.np) · [Download APK](<link>) · [Case Study](https://pratikpoudel.info.np/projects/chessmate) · [Demo Video](<Loom link>)

![ChessMate banner](docs/banner.png)

</div>

---

## 📖 Overview

ChessMate is a cross-platform multiplayer chess platform built as a portfolio project to demonstrate end-to-end product engineering — from mobile UI to backend API to CI/CD to real users.

**In production since <Month Year>** · **<50+> registered users** · **<X> games played** · **99.x% uptime**

### Why this exists
I wanted to go beyond "it works on my machine." ChessMate is what happened when I took a college project and productionized it: containerized backend, automated CI/CD, real users, real metrics, and a web companion app that reuses the same API.

---

## ✨ Features

### Gameplay
- ♟️ Full chess rules engine (castling, en passant, promotion, checkmate)
- 🤖 AI opponents with adjustable difficulty (Stockfish integration)
- 👥 Local 2-player mode
- 🌐 Real-time online multiplayer (WebSockets)
- 💬 In-game real-time chat
- 🏆 ELO rating system + global leaderboard
- 🎯 Matchmaking queue
- 👀 Spectator mode
- 🏟️ Tournament mode *(in progress)*

### Platform
- 📱 Flutter mobile app (Android)
- 💻 Next.js web client (same backend)
- 🔔 Push notifications (FCM)
- 👤 Auth (email + JWT)
- 🛠️ Admin dashboard (users, games, reports)

---

## 🏗️ Architecture

```
┌─────────────────┐     ┌─────────────────┐
│  Flutter App    │     │  Next.js Web    │
│  (Android)      │     │  (Vercel)       │
└────────┬────────┘     └────────┬────────┘
         │                        │
         └──────────┬─────────────┘
                    │ HTTPS / WSS
         ┌──────────▼──────────┐
         │   Node.js API       │
         │   (Express + WS)    │
         │   Dockerized        │
         │   Deployed: Render  │
         └──────────┬──────────┘
                    │
         ┌──────────▼──────────┐
         │   PostgreSQL        │
         │   (Supabase)        │
         └─────────────────────┘
```

![Architecture diagram](docs/architecture.png)

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Mobile | Flutter, Dart |
| Web | Next.js 14, TypeScript, Tailwind CSS |
| Backend | Node.js, Express, Socket.IO |
| Database | PostgreSQL (Supabase) |
| Auth | JWT |
| Chess Engine | Stockfish |
| Notifications | Firebase Cloud Messaging |
| Containerization | Docker |
| CI/CD | GitHub Actions |
| Deployment | Render (API), Vercel (Web), Supabase (DB) |
| Monitoring | <UptimeRobot / Sentry> |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.x
- Node.js 20+
- Docker & Docker Compose
- A Supabase project (free tier works)

### 1. Clone
```bash
git clone https://github.com/<your-username>/chessmate.git
cd chessmate
```

### 2. Backend
```bash
cd backend
cp .env.example .env      # fill in DATABASE_URL, JWT_SECRET, FCM_KEY
docker compose up --build
# API running at http://localhost:3000
```

### 3. Web client
```bash
cd web
cp .env.example .env.local
npm install
npm run dev
# Web running at http://localhost:3001
```

### 4. Mobile app
```bash
cd mobile
flutter pub get
flutter run
```

---

## 🧪 Testing

```bash
# Backend
cd backend && npm test          # Jest, <60>% coverage

# Web
cd web && npm test              # Vitest

# Mobile
cd mobile && flutter test
```

Every pull request runs the full test suite via GitHub Actions before merge.

---

## 🔄 CI/CD Pipeline

`.github/workflows/ci.yml` runs on every push/PR:

1. **Lint** — ESLint (backend/web), `flutter analyze` (mobile)
2. **Test** — Jest, Vitest, Flutter test
3. **Build** — Docker image + Flutter APK
4. **Deploy** — on `main` merge → Render (backend) + Vercel (web)
5. **Release** — tag `v*` → attach APK to GitHub Release

Average pipeline time: **<5 minutes**.

---

## 📊 Metrics (last 30 days)

| Metric | Value |
|---|---|
| Registered users | <50+> |
| Games played | <X> |
| Daily active users (avg) | <X> |
| API p95 latency | <200> ms |
| Uptime | <99.x>% |
| Test coverage (backend) | <60>% |

---

## 🗺️ Roadmap

- [x] Core chess engine
- [x] AI opponents (Stockfish)
- [x] Online multiplayer + chat
- [x] ELO + leaderboard
- [x] Next.js web client
- [x] CI/CD + Docker
- [ ] Tournament mode
- [ ] Friends + private matches
- [ ] Mobile in-app purchases (cosmetics)
- [ ] Internationalization (EN/NE)

---

## 📸 Screenshots

| Mobile | Web | Admin |
|---|---|---|
| ![mobile](docs/screens/mobile.png) | ![web](docs/screens/web.png) | ![admin](docs/screens/admin.png) |

---

## 🤝 Contributing

Issues and PRs welcome. Please open an issue first to discuss significant changes.

---

## 📄 License

MIT © <Year> Pratik Poudel

---

## 🙏 Acknowledgements

- [Stockfish](https://stockfishchess.org/) for the chess engine
- [chess.js](https://github.com/jhlywa/chess.js) for move validation
- [Supabase](https://supabase.com) for the free Postgres tier
- Everyone who played early builds and filed bugs 🙌

---

<div align="center">

**Built with ❤️ by [Pratik Poudel](https://pratikpoudel.info.np)**

[Portfolio](https://pratikpoudel.info.np) · [LinkedIn](https://www.linkedin.com/in/pratik-poudel-dev/) · [GitHub](https://github.com/<your-username>)

</div>
