# 🌊 Rainfall-Induced Flood Early Warning System (EWS)

Sistem Peringatan Dini Banjir Berbasis Curah Hujan untuk Manajemen Sungai.

## 📁 Project Structure

```
Early-Warning-System/
├── frontend/       → Next.js Web Application (TypeScript, Tailwind CSS)
├── backend/        → NestJS REST API Server (TypeScript, Prisma, PostgreSQL)
├── mobile/         → Flutter Mobile Application (Dart, Android/iOS)
└── docs/           → Project Documentation
```

## 🚀 Quick Start

### Prerequisites
- Node.js >= 18
- Flutter SDK >= 3.x
- PostgreSQL >= 14
- Redis >= 7

### Frontend (Next.js)
```bash
cd frontend
npm install
npm run dev
# → http://localhost:4100
```

### Backend (NestJS)
```bash
cd backend
npm install
cp .env.example .env   # Configure your environment
npm run start:dev
# → http://localhost:4101
```

### Mobile (Flutter)
```bash
cd mobile
flutter pub get
flutter run
```

## 👥 Role Pengguna

### User (Masyarakat Umum) — Tanpa Login
- ✅ Real-Time Water Level Dashboard
- ✅ Status Indicators (🟢 Normal / 🟡 Waspada / 🔴 Bahaya)
- ✅ Rainfall Intensity Data
- ✅ Location Map (Google Maps)
- ✅ Emergency Contacts
- ✅ Flood Education / FAQ

### Admin (Petugas River Management) — Login Required
- 🔒 Secure Login & Authentication
- 🔒 Sensor Management
- 🔒 Threshold Settings
- 🔒 Broadcast Alert System (Push/WhatsApp/Email)
- 🔒 Data Logs & Reporting (PDF/Excel)
- 🔒 User Management

## 🛠️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Next.js, TypeScript, Tailwind CSS |
| Backend | NestJS, TypeScript, Prisma, PostgreSQL |
| Mobile | Flutter, Dart |
| Real-Time | WebSocket (Socket.IO) |
| IoT | MQTT Protocol |
| Maps | Google Maps API |
| Notifications | Firebase FCM, WhatsApp API, SMTP |

## 📚 Documentation

Lihat folder [docs/](./docs/) untuk dokumentasi lengkap:
- [Overview](./docs/overview.md) — Gambaran umum sistem
- [Architecture](./docs/architecture.md) — Arsitektur & diagram
- [API Specification](./docs/api-spec.md) — REST API endpoints
- [Frontend Docs](./docs/frontend.md) — Dokumentasi Next.js
- [Backend Docs](./docs/backend.md) — Dokumentasi NestJS
- [Mobile Docs](./docs/mobile.md) — Dokumentasi Flutter
- [Database Schema](./docs/database.md) — ERD & Prisma schema
- [Deployment Guide](./docs/deployment.md) — Docker & CI/CD

## 📄 License

MIT
