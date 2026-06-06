---
title: EWS Backend
emoji: 🚀
colorFrom: blue
colorTo: green
sdk: docker
pinned: false
---


# Backend EWS (NestJS + Prisma + Supabase PostgreSQL)

Backend untuk sistem Early Warning banjir, dibangun dengan:

- **NestJS 11** (REST API)
- **Prisma ORM**
- **Supabase PostgreSQL**

## 1) Prasyarat

- Node.js >= 18
- Akun Supabase + project database aktif

## 2) Instalasi

```bash
npm install
```

## 3) Konfigurasi Environment

File berikut sudah tersedia:

- `.env.example`
- `.env`

Lengkapi value berikut di `.env`:

- `DATABASE_URL` → koneksi pooler Supabase (runtime query)
- `DIRECT_URL` → koneksi direct host Supabase (untuk migrate)
- `FIREBASE_PROJECT_ID` → project id Firebase
- `FIREBASE_SERVICE_ACCOUNT_PATH` → path file service-account JSON Firebase Admin SDK
- `FCM_DEFAULT_TOPIC` → topik default untuk push notification alert

## 3.1) Setup Firebase Admin SDK

1. Letakkan file service-account di:

```bash
backend/config/firebase-service-account.json
```

2. Pastikan file tersebut tidak di-commit (sudah di-ignore oleh `.gitignore`).

3. Endpoint `POST /alerts/broadcast` akan:

- menyimpan data alert ke database,
- mengirim push notification FCM ke topic default (`FCM_DEFAULT_TOPIC`) jika channel alert mengandung `push`, `fcm`, `webpush`, atau `mobile`.

Jika `targetArea` diisi, topic otomatis menjadi `FCM_DEFAULT_TOPIC-{targetArea-slug}`.

4. Client web/mobile perlu subscribe token FCM ke topic via endpoint:

```http
POST /alerts/subscribe
Content-Type: application/json

{
  "token": "FCM_DEVICE_TOKEN",
  "targetArea": "kecamatan-bandung-kulon"
}
```

## 4) Prisma Workflow

Generate client:

```bash
npm run prisma:generate
```

Buat dan jalankan migration (development):

```bash
npm run prisma:migrate:dev -- --name init
```

Deploy migration (production/staging):

```bash
npm run prisma:migrate:deploy
```

Buka Prisma Studio:

```bash
npm run prisma:studio
```

Seed data awal (sensor, thresholds, emergency contacts, akun user/admin):

```bash
npm run prisma:seed
```

Akun hasil seed untuk login cepat:

- `superadmin@ews.com` / `Superadmin123!`
- `admin@ews.com` / `Admin123!`
- `admin2@ews.com` / `AdminOps123!`
- `officer@ews.com` / `Field12345!`
- `user1@ews.com` / `User12345!`
- `user2@ews.com` / `User12345!`
- `user3@ews.com` / `User12345!`

## 5) Menjalankan Aplikasi

Mode development:

```bash
npm run start:dev
```

Server default berjalan di:

- `http://localhost:3001`

## 6) Endpoint Validasi Koneksi Database

Untuk cek apakah Prisma berhasil konek ke Supabase PostgreSQL:

- `GET /health/db`

Response sukses:

```json
{
  "status": "ok",
  "database": "connected"
}
```

## 7) Testing

```bash
npm run test
npm run test:e2e
```

## Catatan

Skema database berada di `prisma/schema.prisma` dan sudah meng-cover entitas utama EWS (users, sensors, water/rain logs, thresholds, alerts, emergency contacts).
