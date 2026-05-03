# 🌐 Frontend Documentation (Next.js)

## Tech Stack

| Teknologi | Fungsi |
|-----------|--------|
| Next.js (App Router) | React Framework |
| TypeScript | Type Safety |
| Tailwind CSS | Styling |
| Socket.IO Client | Real-time Data |
| Google Maps API | Peta Lokasi Sensor |
| Chart.js / Recharts | Grafik Ketinggian Air |
| Axios | HTTP Client |
| Zustand / Context API | State Management |

## Struktur Folder

```
frontend/
├── src/
│   ├── app/
│   │   ├── layout.tsx              # Root layout
│   │   ├── page.tsx                # Landing / Public Dashboard
│   │   ├── globals.css             # Global styles
│   │   ├── dashboard/
│   │   │   └── page.tsx            # Real-time water level dashboard (Public)
│   │   ├── map/
│   │   │   └── page.tsx            # Sensor location map
│   │   ├── emergency/
│   │   │   └── page.tsx            # Emergency contacts
│   │   ├── education/
│   │   │   └── page.tsx            # Flood education & FAQ
│   │   ├── admin/
│   │   │   ├── layout.tsx          # Admin layout (with auth guard)
│   │   │   ├── login/
│   │   │   │   └── page.tsx        # Admin login
│   │   │   ├── dashboard/
│   │   │   │   └── page.tsx        # Admin overview dashboard
│   │   │   ├── sensors/
│   │   │   │   └── page.tsx        # Sensor management
│   │   │   ├── thresholds/
│   │   │   │   └── page.tsx        # Threshold settings
│   │   │   ├── alerts/
│   │   │   │   └── page.tsx        # Broadcast alert system
│   │   │   ├── reports/
│   │   │   │   └── page.tsx        # Data logs & reporting
│   │   │   └── users/
│   │   │       └── page.tsx        # User management
│   │   └── not-found.tsx           # 404 page
│   ├── components/
│   │   ├── ui/                     # Reusable UI components
│   │   │   ├── Button.tsx
│   │   │   ├── Card.tsx
│   │   │   ├── Badge.tsx
│   │   │   ├── Modal.tsx
│   │   │   └── StatusIndicator.tsx # 🟢🟡🔴 Status badge
│   │   ├── charts/
│   │   │   ├── WaterLevelChart.tsx
│   │   │   └── RainfallChart.tsx
│   │   ├── maps/
│   │   │   └── SensorMap.tsx       # Google Maps with sensor markers
│   │   ├── dashboard/
│   │   │   ├── WaterLevelGauge.tsx  # Indikator visual termometer air
│   │   │   ├── RainfallCard.tsx
│   │   │   └── AlertBanner.tsx
│   │   └── layout/
│   │       ├── Navbar.tsx
│   │       ├── Sidebar.tsx         # Admin sidebar
│   │       └── Footer.tsx
│   ├── hooks/
│   │   ├── useWebSocket.ts         # WebSocket connection hook
│   │   ├── useWaterLevel.ts        # Water level data hook
│   │   └── useAuth.ts              # Authentication hook
│   ├── lib/
│   │   ├── api.ts                  # Axios instance & API functions
│   │   ├── socket.ts               # Socket.IO client setup
│   │   └── utils.ts                # Helper functions
│   ├── types/
│   │   ├── water-level.ts          # Water level types
│   │   ├── sensor.ts               # Sensor types
│   │   ├── alert.ts                # Alert types
│   │   └── user.ts                 # User types
│   └── constants/
│       └── index.ts                # Status colors, API URLs, etc.
├── public/
│   ├── icons/                      # App icons
│   └── images/                     # Static images
├── next.config.ts
├── tailwind.config.ts
├── tsconfig.json
└── package.json
```

## Halaman Publik (User/Masyarakat)

### 1. Dashboard (`/dashboard`)
- **Real-Time Water Level**: Grafik garis (line chart) menampilkan perubahan ketinggian air per sensor.
- **Water Level Gauge**: Indikator visual mirip termometer yang menunjukkan level air saat ini.
- **Status Indicator**: Badge berwarna (Hijau/Kuning/Merah) menampilkan status keamanan.
- **Rainfall Card**: Informasi curah hujan terkini dengan klasifikasi intensitas.

### 2. Peta Sensor (`/map`)
- Integrasi Google Maps API.
- Marker untuk setiap sensor di sepanjang aliran sungai.
- Popup info saat klik marker menampilkan data terkini sensor.

### 3. Kontak Darurat (`/emergency`)
- Daftar nomor telepon penting (BPBD, SAR, Ambulans).
- Tombol "Click to Call" untuk panggilan langsung (mobile-friendly).

### 4. Edukasi Banjir (`/education`)
- Panduan apa yang harus dilakukan saat status "Merah".
- FAQ seputar banjir dan sistem peringatan dini.

## Halaman Admin (Petugas)

### 1. Login (`/admin/login`)
- Form login email & password.
- Redirect ke dashboard admin setelah berhasil login.

### 2. Admin Dashboard (`/admin/dashboard`)
- Overview jumlah sensor aktif/offline.
- Status terkini semua titik pemantauan.
- Alert terbaru.

### 3. Sensor Management (`/admin/sensors`)
- Tabel daftar sensor dengan status baterai & konektivitas.
- Tombol tambah/edit/hapus sensor.

### 4. Threshold Settings (`/admin/thresholds`)
- Form pengaturan ambang batas ketinggian air per status.
- Preview perubahan sebelum disimpan.

### 5. Broadcast Alert (`/admin/alerts`)
- Form komposisi pesan alert.
- Pilihan channel notifikasi (Push/WhatsApp/Email).
- Riwayat broadcast sebelumnya.

### 6. Reports (`/admin/reports`)
- Filter berdasarkan periode dan tipe data.
- Preview data dalam bentuk tabel.
- Tombol download PDF/Excel.

### 7. User Management (`/admin/users`)
- CRUD petugas lapangan.
- Pengaturan role dan permission.

## Environment Variables

```env
# .env.local
NEXT_PUBLIC_API_URL=http://localhost:3001/api
NEXT_PUBLIC_WS_URL=ws://localhost:3001
NEXT_PUBLIC_GOOGLE_MAPS_API_KEY=your_google_maps_api_key
```

## Scripts

```bash
npm run dev          # Start development server (port 3000)
npm run build        # Build for production
npm run start        # Start production server
npm run lint         # Run ESLint
```
