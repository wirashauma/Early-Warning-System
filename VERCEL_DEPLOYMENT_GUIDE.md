# 🚀 Panduan Deployment Vercel + Firebase

## ⚠️ Langkah WAJIB yang harus dilakukan MANUAL (tidak bisa dari kode)

---

## 1. Tambahkan Domain Vercel ke Firebase Authorized Domains

**Ini penyebab error `auth/unauthorized-domain`.**

1. Buka [Firebase Console](https://console.firebase.google.com/) → Project `ews-aplication`
2. Pergi ke **Authentication** → **Settings** → **Authorized domains**
3. Klik **Add domain** dan tambahkan:
   - `ews-floodguard.vercel.app` (ganti dengan URL Vercel kamu yang sebenarnya)
   - Jika pakai custom domain, tambahkan juga

---

## 2. Dapatkan VAPID Key untuk FCM Web Push

**Ini penyebab FCM tidak mendapatkan token push notification.**

1. Buka [Firebase Console](https://console.firebase.google.com/) → Project `ews-aplication`
2. Pergi ke **Project Settings** (ikon ⚙️) → tab **Cloud Messaging**
3. Scroll ke bagian **Web configuration** → **Web Push certificates**
4. Klik **Generate key pair** jika belum ada, atau salin **Key pair** yang sudah ada
5. Copy nilai **Key pair** tersebut (dimulai dengan `B...`)

---

## 3. Konfigurasi Environment Variables di Vercel

Di **Vercel Dashboard** → Project → **Settings** → **Environment Variables**, tambahkan semua variabel berikut:

### Frontend Environment Variables (wajib semua ada di Vercel)

| Variable | Value |
|----------|-------|
| `NEXT_PUBLIC_API_URL` | `/api` |
| `NEXT_PUBLIC_WS_URL` | `wss://URL-BACKEND-KAMU` |
| `NEXT_PUBLIC_PRIMARY_SENSOR_ID` | `EWS-RF-002` |
| `NEXT_PUBLIC_FLOW_SENSOR_ID` | `EWS-FL-001` |
| `NEXT_PUBLIC_FIREBASE_API_KEY` | `AIzaSyAbTrWQwwc-S2pQmDlz-oAQqJWXayR8VtA` |
| `NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN` | `ews-aplication.firebaseapp.com` |
| `NEXT_PUBLIC_FIREBASE_PROJECT_ID` | `ews-aplication` |
| `NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET` | `ews-aplication.firebasestorage.app` |
| `NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID` | `235513471209` |
| `NEXT_PUBLIC_FIREBASE_APP_ID` | `1:235513471209:web:48e337cb4cf5cdcbe79078` |
| `NEXT_PUBLIC_FIREBASE_VAPID_KEY` | **[VAPID Key dari langkah 2]** |
| `NEXT_PUBLIC_GOOGLE_MAPS_API_KEY` | `AIzaSyDSfvMlRB7soewujF-SduY1osX2dZPrK9w` |
| `NEXT_PUBLIC_SUPABASE_URL` | `https://iizjtnuydhwrggsmtood.supabase.co` |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | `[anon key supabase]` |
| `BACKEND_API_URL` | `https://URL-BACKEND-KAMU` (tanpa trailing slash) |

> **Catatan:** `BACKEND_API_URL` adalah variabel server-side (tanpa `NEXT_PUBLIC_`), dipakai oleh `next.config.ts` untuk proxy `/api/*` ke backend.

---

## 4. Konfigurasi Environment Variables di Backend Hosting (Railway/Render/Fly.io)

Tambahkan variabel berikut di dashboard hosting backend:

| Variable | Value |
|----------|-------|
| `NODE_ENV` | `production` |
| `PORT` | `7860` (atau sesuai hosting) |
| `DATABASE_URL` | `[pooler URL supabase dengan pgbouncer=true]` |
| `DIRECT_URL` | `[direct URL supabase]` |
| `JWT_SECRET` | `[JWT secret panjang dan acak]` |
| `FIREBASE_PROJECT_ID` | `ews-aplication` |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | `[konten JSON dari backend/.env — satu baris]` |
| `FCM_DEFAULT_TOPIC` | `ews-alerts` |
| `ALLOWED_ORIGINS` | `https://ews-floodguard.vercel.app` |
| `ALLOW_NGROK_ORIGINS` | `false` |

> **Penting:** `FIREBASE_SERVICE_ACCOUNT_JSON` sudah tersedia di `backend/.env` (sudah diisi dengan credentials yang ada). Copy nilai tersebut ke dashboard hosting backend.

---

## 5. Update URL di Kode Jika URL Vercel Berbeda

Jika URL Vercel frontend kamu **bukan** `https://ews-floodguard.vercel.app`, update di:

1. `backend/src/main.ts` → array `defaultOrigins` (baris ~33)
2. `backend/.env` → variabel `ALLOWED_ORIGINS`

---

## ✅ Checklist Final Sebelum Deploy

- [ ] Domain Vercel sudah ditambahkan ke Firebase Authorized Domains
- [ ] VAPID Key sudah didapatkan dan ditambahkan ke Vercel env vars
- [ ] Semua `NEXT_PUBLIC_FIREBASE_*` sudah ada di Vercel env vars
- [ ] `BACKEND_API_URL` sudah diisi di Vercel env vars
- [ ] `FIREBASE_SERVICE_ACCOUNT_JSON` sudah diisi di backend hosting
- [ ] `ALLOWED_ORIGINS` di backend hosting sudah berisi URL frontend Vercel
- [ ] URL Vercel di `defaultOrigins` (main.ts) sudah benar
