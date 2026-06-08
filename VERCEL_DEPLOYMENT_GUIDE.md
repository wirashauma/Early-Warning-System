# 🚀 Panduan Deployment: Vercel (Frontend) & Hugging Face Spaces (Backend)

Dokumen ini berisi panduan konfigurasi lengkap untuk menghubungkan aplikasi frontend Next.js di **Vercel** dengan backend NestJS di **Hugging Face Spaces (Docker)**.

---

## 📌 Bagaimana Arsitektur Ini Bekerja
1. **Frontend (Vercel)**:
   - Request API client-side dikirim ke path relatif `/api/...` (misalnya `/api/sensors`).
   - Vercel Serverless Function menggunakan fitur `rewrites` di [next.config.ts](file:///d:/Folder%20Project%20Howarts/Early-Warning-System/frontend/next.config.ts) untuk mem-proxy request `/api/*` secara internal ke URL backend Hugging Face Spaces (`BACKEND_API_URL`).
   - Hal ini menghindari masalah **CORS** di sisi browser karena browser hanya berkomunikasi dengan domain Vercel.
2. **Backend (Hugging Face Spaces)**:
   - Berjalan sebagai Docker container (menggunakan [backend/Dockerfile](file:///d:/Folder%20Project%20Howarts/Early-Warning-System/backend/Dockerfile)) pada port internal `7860`.
   - Mengakses database PostgreSQL secara langsung di **Supabase**.

---

## ⚠️ PENTING: Pengaturan Hugging Face Space
Agar backend di Hugging Face Spaces dapat diakses oleh Vercel:
1. **Space Visibility harus PUBLIC**:
   Jika Space diset ke *Private*, Hugging Face akan memasang dinding autentikasi (redirect 302/login screen), sehingga proxy dari Vercel akan diblokir dengan error *401 Unauthorized* atau *302 Found*.
2. **Space Sleep/Idle (Free Tier)**:
   Secara default, Space gratis akan "tidur" setelah beberapa jam tidak ada aktivitas. Request pertama setelah tidur akan memakan waktu 10-30 detik untuk men-spin up container kembali.

---

## 1. Konfigurasi Environment Variables di Vercel (Frontend)

Masuk ke **Vercel Dashboard → Project → Settings → Environment Variables** dan tambahkan variabel berikut:

| Nama Variabel | Nilai Contoh / Deskripsi |
|---|---|
| `NEXT_PUBLIC_API_URL` | `/api` (Tetap gunakan ini agar proxy Next.js bekerja) |
| `BACKEND_API_URL` | `https://wira123-ews-backend.hf.space` (Ganti dengan subdomain Space kamu) |
| `NEXT_PUBLIC_WS_URL` | `wss://wira123-ews-backend.hf.space` (Wajib protokol `wss` untuk secure WebSocket) |
| `NEXT_PUBLIC_PRIMARY_SENSOR_ID` | `EWS-RF-002` |
| `NEXT_PUBLIC_FLOW_SENSOR_ID` | `EWS-FL-001` |
| `NEXT_PUBLIC_GOOGLE_MAPS_API_KEY` | `AIzaSyDSfvMlRB7soewujF-SduY1osX2dZPrK9w` |
| `NEXT_PUBLIC_FIREBASE_API_KEY` | `AIzaSyAbTrWQwwc-S2pQmDlz-oAQqJWXayR8VtA` |
| `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN` | `ews-aplication.firebaseapp.com` |
| `NEXT_PUBLIC_FIREBASE_PROJECT_ID` | `ews-aplication` |
| `NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET` | `ews-aplication.firebasestorage.app` |
| `NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID` | `235513471209` |
| `NEXT_PUBLIC_FIREBASE_APP_ID` | `1:235513471209:web:48e337cb4cf5cdcbe79078` |
| `NEXT_PUBLIC_FIREBASE_VAPID_KEY` | *[VAPID Key hasil generate dari Firebase Console]* |
| `NEXT_PUBLIC_SUPABASE_URL` | `https://iizjtnuydhwrggsmtood.supabase.co` |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | *[Anon key dari Supabase dashboard]* |

---

## 2. Konfigurasi Environment Variables di Hugging Face Spaces (Backend)

Karena file [backend/.env](file:///d:/Folder%20Project%20Howarts/Early-Warning-System/backend/.env) masuk dalam `.gitignore` dan tidak di-push ke Hugging Face, Anda **wajib** mengisi variabel berikut di **Hugging Face Space → Settings → Variables and Secrets**:

### A. Secrets (Gunakan tipe **Secret**)
| Nama Secret | Deskripsi / Nilai |
|---|---|
| `DATABASE_URL` | `postgresql://postgres.iizjtnuydhwrggsmtood:databaseews2026@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres?pgbouncer=true` |
| `DIRECT_URL` | `postgresql://postgres.iizjtnuydhwrggsmtood:databaseews2026@aws-1-ap-southeast-1.pooler.supabase.com:5432/postgres` |
| `JWT_SECRET` | `EwsProduksi2026!Secr3tK3ySuperAmanBanget998877` |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Konten lengkap file [firebase-service-account.json](file:///d:/Folder%20Project%20Howarts/Early-Warning-System/backend/config/firebase-service-account.json) yang diformat dalam **satu baris** (tanpa newline) |

### B. Variables (Gunakan tipe **Variable**)
| Nama Variable | Deskripsi / Nilai |
|---|---|
| `NODE_ENV` | `production` |
| `PORT` | `7860` (Wajib untuk Hugging Face Spaces agar port routingnya sesuai) |
| `FIREBASE_PROJECT_ID` | `ews-aplication` |
| `FCM_DEFAULT_TOPIC` | `ews-alerts` |
| `ALLOWED_ORIGINS` | `https://ews-floodguard.vercel.app` (Ganti dengan domain Vercel Anda) |
| `ALLOW_NGROK_ORIGINS` | `false` |

---

## 3. Cara Push / Update Backend ke Hugging Face Spaces

Karena Hugging Face Space adalah repository git terpisah dan backend kita berada di subfolder `backend`, gunakan perintah berikut di terminal root proyek untuk men-deploy perubahan backend saja:

```bash
# Push perubahan backend ke Hugging Face
git subtree push --prefix=backend hf main
```

*Catatan: Pastikan Anda sudah melakukan `git commit` di branch `main` lokal Anda sebelum menjalankan perintah di atas.*

---

## 4. Konfigurasi Firebase Authorized Domains (Wajib)
Jika tombol **Google Sign-In** mengalami error auth:
1. Buka [Firebase Console](https://console.firebase.google.com/) → Project `ews-aplication`
2. Buka **Authentication** → **Settings** → **Authorized domains**
3. Tambahkan domain Vercel Anda (misalnya `ews-floodguard.vercel.app`).

