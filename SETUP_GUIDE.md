# Project Setup Guide (EWS)

Panduan singkat untuk men-setup project agar backend, frontend, dan IoT berjalan sinkron.

## 1) Prasyarat
- Node.js >= 18
- PostgreSQL >= 14 (atau Supabase)
- (Opsional) Flutter SDK >= 3.x
- (Opsional) Redis >= 7

## 2) Backend (NestJS + Prisma)
1. Masuk ke folder backend:
   ```bash
   cd backend
   npm install
   ```
2. Buat file env:
   - Salin `.env.example` ke `.env`, lalu isi:
     - `DATABASE_URL`
     - `DIRECT_URL`
     - `FIREBASE_PROJECT_ID`
     - `FIREBASE_SERVICE_ACCOUNT_PATH`
     - `FCM_DEFAULT_TOPIC`
     - (Opsional) `ALLOWED_ORIGINS` contoh: `http://localhost:3000,http://192.168.1.19:3000`
3. Generate dan migrate:
   ```bash
   npm run prisma:generate
   npm run prisma:migrate:dev -- --name init
   ```
4. Seed data (opsional):
   ```bash
   npm run prisma:seed
   ```
5. Jalankan backend:
   ```bash
   npm run start:dev
   ```
6. Cek health:
   - `http://localhost:3001/api/health/db`

## 3) Frontend (Next.js)
1. Masuk ke folder frontend:
   ```bash
   cd frontend
   npm install
   ```
2. Pastikan `.env` terisi:
   ```env
   NEXT_PUBLIC_API_URL="/api"
   NEXT_PUBLIC_WS_URL="ws://192.168.1.19:3001"
   NEXT_PUBLIC_PRIMARY_SENSOR_ID="EWS-RF-002"
   ```
   Ganti IP sesuai host backend.
3. Jalankan frontend:
   ```bash
   npm run dev
   ```
4. Buka web:
   - `http://localhost:4100`

## 4) IoT (Arduino / NodeMCU)
1. Set WiFi dan endpoint di Arduino:
   - `API_URL` harus mengarah ke backend: `http://<IP_BACKEND>:4101/api/iot/ingest`
2. Sensor id harus sesuai dengan yang di database (contoh: `EWS-RF-002`).
3. Pastikan serial monitor menampilkan HTTP 201 untuk ingest.

## 5) Verifikasi Sinkronisasi
Cek data live:
- `http://<IP_BACKEND>:4101/api/rainfall/current`
- `http://<IP_BACKEND>:4101/api/rainfall/history?sensorId=EWS-RF-002&startDate=2026-05-12T00:00:00.000Z&endDate=2026-05-12T23:59:59.000Z&interval=hourly`

Web melakukan polling setiap 5 detik, jadi nilai di UI harus mengikuti data terakhir dari Arduino.

## 6) Troubleshooting Singkat
- UI tidak update: pastikan frontend sukses jalan dan env mengarah ke IP backend.
- CORS error: set `ALLOWED_ORIGINS` di backend `.env`, lalu restart backend.
- Data kosong: pastikan sensorId yang dikirim Arduino ada di database dan aktif.

## 7) (Opsional) Mobile
```bash
cd mobile
flutter pub get
flutter run
```
