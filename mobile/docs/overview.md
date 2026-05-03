# 🌊 Rainfall-Induced Flood Early Warning System (EWS)

## Gambaran Umum

Sistem Peringatan Dini Banjir Berbasis Curah Hujan (EWS) adalah platform terintegrasi yang dirancang untuk memantau ketinggian air sungai secara real-time dan memberikan peringatan dini kepada masyarakat serta petugas pengelola sungai (River Management) guna meminimalkan dampak banjir.

## Tujuan Sistem

1. **Monitoring Real-Time** — Memantau ketinggian air sungai dan intensitas curah hujan secara langsung melalui sensor IoT.
2. **Peringatan Dini Otomatis** — Mengirimkan notifikasi/alert kepada masyarakat ketika ambang batas keamanan terlampaui.
3. **Manajemen Data** — Menyimpan data historis untuk analisis tren dan laporan berkala.
4. **Edukasi Masyarakat** — Menyediakan panduan evakuasi dan kontak darurat yang mudah diakses.

## Role Pengguna

### 1. User (Masyarakat Umum)
Akses publik tanpa perlu login. Fokus pada penyampaian informasi cepat dan mudah dipahami.

| Fitur | Deskripsi |
|-------|-----------|
| Real-Time Water Level Dashboard | Grafik/indikator visual ketinggian air sungai saat ini |
| Status Indicators | Kode warna: 🟢 Normal, 🟡 Waspada, 🔴 Bahaya/Evakuasi |
| Rainfall Intensity Data | Informasi curah hujan terkini (Ringan, Sedang, Lebat) |
| Location Map | Peta (Google Maps API) titik-titik sensor di aliran sungai |
| Emergency Contacts | Daftar nomor telepon penting (BPBD, SAR, Ambulans) |
| Flood Education/FAQ | Panduan tindakan saat status berubah menjadi "Merah" |

### 2. Admin (Petugas River Management)
Akses khusus dengan autentikasi. Fokus pada pengelolaan sistem dan penyebaran peringatan.

| Fitur | Deskripsi |
|-------|-----------|
| Secure Login | Autentikasi akses petugas pengelola sungai |
| Sensor Management | Monitoring kesehatan perangkat (baterai, konektivitas IoT) |
| Threshold Settings | Pengaturan ambang batas ketinggian air untuk tiap status |
| Broadcast Alert System | Kirim notifikasi massal (Push/WhatsApp/Email) |
| Data Logs & Reporting | Unduh laporan bulanan (PDF/Excel) riwayat data |
| User Management | Kelola akun petugas lapangan |

## Tech Stack

| Layer | Teknologi |
|-------|-----------|
| Frontend (Web) | Next.js, TypeScript, Tailwind CSS |
| Backend (API) | NestJS, TypeScript, PostgreSQL, Prisma |
| Mobile | Flutter, Dart |
| Real-Time | WebSocket (Socket.IO) |
| Maps | Google Maps API |
| Notification | Firebase Cloud Messaging, WhatsApp API, Email (SMTP) |
| IoT Integration | MQTT Protocol |
| Deployment | Docker, Nginx, CI/CD |

## Status Level

```
┌──────────────────────────────────────────────────┐
│  🟢 NORMAL (Hijau)                               │
│  Ketinggian air: < 3 meter                       │
│  Aksi: Tidak ada tindakan khusus                 │
├──────────────────────────────────────────────────┤
│  🟡 WASPADA (Kuning) — Be Ready                  │
│  Ketinggian air: 3 - 5 meter                     │
│  Aksi: Siaga, pantau terus perkembangan          │
├──────────────────────────────────────────────────┤
│  🔴 BAHAYA (Merah) — Take Action                 │
│  Ketinggian air: > 5 meter                       │
│  Aksi: EVAKUASI SEGERA                           │
└──────────────────────────────────────────────────┘
```

> **Catatan:** Ambang batas default di atas dapat dikonfigurasi oleh Admin melalui fitur Threshold Settings.
