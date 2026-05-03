# 📱 Mobile Documentation (Flutter)

## Tech Stack

| Teknologi | Fungsi |
|-----------|--------|
| Flutter 3.x | Mobile Framework |
| Dart | Programming Language |
| Dio | HTTP Client |
| Provider / Riverpod | State Management |
| Google Maps Flutter | Peta Lokasi Sensor |
| fl_chart | Grafik/Chart |
| Socket.IO Client | Real-time Data |
| Firebase Messaging | Push Notification |
| SharedPreferences | Local Storage |
| url_launcher | Click to Call / Open Links |

## Struktur Folder

```
mobile/
├── lib/
│   ├── main.dart                    # Entry point
│   │
│   ├── app/
│   │   ├── app.dart                 # MaterialApp configuration
│   │   ├── routes.dart              # Route definitions
│   │   └── theme.dart               # App theme (colors, typography)
│   │
│   ├── config/
│   │   ├── api_config.dart          # API base URL & endpoints
│   │   ├── constants.dart           # App constants
│   │   └── environment.dart         # Environment configuration
│   │
│   ├── models/                      # Data Models
│   │   ├── water_level.dart
│   │   ├── rainfall.dart
│   │   ├── sensor.dart
│   │   ├── alert.dart
│   │   ├── emergency_contact.dart
│   │   ├── user.dart
│   │   └── threshold.dart
│   │
│   ├── services/                    # API & External Services
│   │   ├── api_service.dart         # Dio HTTP client
│   │   ├── socket_service.dart      # WebSocket connection
│   │   ├── auth_service.dart        # Authentication
│   │   ├── notification_service.dart # FCM Push Notification
│   │   └── storage_service.dart     # Local storage
│   │
│   ├── providers/                   # State Management
│   │   ├── water_level_provider.dart
│   │   ├── rainfall_provider.dart
│   │   ├── sensor_provider.dart
│   │   ├── alert_provider.dart
│   │   └── auth_provider.dart
│   │
│   ├── screens/                     # Screens / Pages
│   │   ├── splash_screen.dart
│   │   │
│   │   ├── public/                  # User (Masyarakat) Screens
│   │   │   ├── home_screen.dart             # Landing page
│   │   │   ├── dashboard_screen.dart        # Real-time dashboard
│   │   │   ├── water_level_detail_screen.dart
│   │   │   ├── map_screen.dart              # Sensor location map
│   │   │   ├── emergency_screen.dart        # Emergency contacts
│   │   │   └── education_screen.dart        # Flood education/FAQ
│   │   │
│   │   └── admin/                   # Admin Screens
│   │       ├── login_screen.dart
│   │       ├── admin_dashboard_screen.dart
│   │       ├── sensor_management_screen.dart
│   │       ├── threshold_settings_screen.dart
│   │       ├── broadcast_alert_screen.dart
│   │       ├── reports_screen.dart
│   │       └── user_management_screen.dart
│   │
│   ├── widgets/                     # Reusable Widgets
│   │   ├── common/
│   │   │   ├── loading_widget.dart
│   │   │   ├── error_widget.dart
│   │   │   └── empty_state_widget.dart
│   │   ├── status_indicator.dart    # 🟢🟡🔴 Status badge
│   │   ├── water_level_gauge.dart   # Visual gauge widget
│   │   ├── water_level_chart.dart   # Line chart
│   │   ├── rainfall_card.dart
│   │   ├── sensor_card.dart
│   │   ├── alert_banner.dart
│   │   └── emergency_card.dart      # Click to call card
│   │
│   └── utils/
│       ├── helpers.dart             # Utility functions
│       ├── validators.dart          # Form validators
│       └── date_formatter.dart      # Date formatting
│
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/
│
├── android/
├── ios/
├── test/
│   └── widget_test.dart
├── pubspec.yaml
└── README.md
```

## Screens Overview

### Public Screens (Tanpa Login)

| Screen | Route | Deskripsi |
|--------|-------|-----------|
| Home | `/` | Landing page dengan overview status terkini |
| Dashboard | `/dashboard` | Real-time water level & rainfall data |
| Water Level Detail | `/water-level/:id` | Detail data per sensor |
| Map | `/map` | Google Maps dengan lokasi sensor |
| Emergency | `/emergency` | Kontak darurat dengan click-to-call |
| Education | `/education` | Panduan & FAQ banjir |

### Admin Screens (Login Required)

| Screen | Route | Deskripsi |
|--------|-------|-----------|
| Login | `/admin/login` | Login petugas |
| Admin Dashboard | `/admin/dashboard` | Overview sistem |
| Sensor Management | `/admin/sensors` | Kelola sensor |
| Threshold Settings | `/admin/thresholds` | Atur ambang batas |
| Broadcast Alert | `/admin/alerts` | Kirim notifikasi massal |
| Reports | `/admin/reports` | Generate & download laporan |
| User Management | `/admin/users` | Kelola akun petugas |

## Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # HTTP & API
  dio: ^5.x
  
  # State Management
  provider: ^6.x
  # atau riverpod: ^2.x
  
  # Maps
  google_maps_flutter: ^2.x
  
  # Charts
  fl_chart: ^0.x
  
  # WebSocket
  socket_io_client: ^2.x
  
  # Firebase
  firebase_core: ^2.x
  firebase_messaging: ^14.x
  
  # Local Storage
  shared_preferences: ^2.x
  
  # Utilities
  url_launcher: ^6.x          # Click to call
  intl: ^0.x                  # Date formatting
  flutter_local_notifications: ^17.x
  
  # UI
  shimmer: ^3.x               # Loading skeleton
  cached_network_image: ^3.x
```

## Environment Configuration

```dart
// lib/config/environment.dart
class Environment {
  static const String apiBaseUrl = 'http://10.0.2.2:3001/api'; // Android Emulator
  // static const String apiBaseUrl = 'http://localhost:3001/api'; // iOS Simulator
  static const String wsUrl = 'ws://10.0.2.2:3001';
  static const String googleMapsApiKey = 'YOUR_API_KEY';
}
```

## Theming & Colors

```dart
// Status Colors
static const Color normalColor = Color(0xFF4CAF50);    // Hijau
static const Color warningColor = Color(0xFFFFC107);    // Kuning
static const Color dangerColor = Color(0xFFF44336);     // Merah
```

## Scripts

```bash
flutter run                   # Run app (debug)
flutter run --release         # Run app (release)
flutter build apk             # Build Android APK
flutter build ios              # Build iOS
flutter test                   # Run tests
flutter analyze                # Static analysis
```

## Push Notification Setup

1. Buat project di Firebase Console.
2. Tambahkan `google-services.json` (Android) ke `android/app/`.
3. Tambahkan `GoogleService-Info.plist` (iOS) ke `ios/Runner/`.
4. Konfigurasi FCM di `notification_service.dart`.
