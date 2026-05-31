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
   - Salin `.env.example` ke `.env` (file `.env` lokal sudah otomatis di-ignore oleh Git):
     ```bash
     cp .env.example .env
     ```
   - *Catatan:* `.env.example` sudah terkonfigurasi dengan database development bersama (Supabase) secara default, sehingga Anda bisa langsung menjalankannya tanpa konfigurasi tambahan!
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
   - `http://localhost:4101/api/health/db` (Port default backend adalah 4101)

## 3) Frontend (Next.js)
1. Masuk ke folder frontend:
   ```bash
   cd frontend
   npm install
   ```
2. Buat file env:
   - Salin `.env.example` ke `.env`:
     ```bash
     cp .env.example .env
     ```
   - *Catatan:* `.env.example` sudah berisi Maps Key, Firebase, dan konfigurasi API default yang langsung mengarah ke backend lokal.
3. Jalankan frontend:
   ```bash
   npm run dev
   ```
4. Buka web:
   - `http://localhost:4000` (Port default frontend adalah 4000)

## 4) IoT (Arduino / NodeMCU)
1. Set WiFi dan endpoint di Arduino:
   - `API_URL` harus mengarah ke backend: `http://<IP_BACKEND>:4101/api/iot/ingest`
2. Sensor id harus sesuai dengan yang di database (contoh: `EWS-RF-002`).
3. Pastikan serial monitor menampilkan HTTP 201 untuk ingest.

## 5) Verifikasi Sinkronisasi
Cek data live:
- `http://localhost:4101/api/rainfall/current`
- `http://localhost:4101/api/rainfall/history?sensorId=EWS-RF-002&startDate=2026-05-12T00:00:00.000Z&endDate=2026-05-12T23:59:59.000Z&interval=hourly`

Web melakukan polling setiap 5 detik, jadi nilai di UI harus mengikuti data terakhir dari Arduino.

## 6) Troubleshooting Singkat
- UI tidak update: pastikan frontend sukses jalan dan env mengarah ke IP backend.
- CORS error: set `ALLOWED_ORIGINS` di backend `.env`, lalu restart backend.
- Data kosong: pastikan sensorId yang dikirim Arduino ada di database dan aktif.

## 7) (Opsional) Mobile
1. Masuk ke folder mobile:
   ```bash
   cd mobile
   ```
2. Buat file env:
   - Salin `.env.example` ke `.env`:
     ```bash
     cp .env.example .env
     ```
3. Jalankan aplikasi:
   ```bash
   flutter pub get
   flutter run
   ```
