# 🔌 API Specification

## Base URL
```
Development: http://localhost:3001/api
Production:  https://api.ews.example.com/api
```

## Authentication
Menggunakan JWT (JSON Web Token) Bearer Authentication untuk endpoint yang memerlukan autentikasi.

```
Authorization: Bearer <access_token>
```

---

## Endpoints

### 1. Auth Module

#### POST `/api/auth/login`
Login untuk Admin/Petugas.

**Request Body:**
```json
{
  "email": "admin@ews.com",
  "password": "securepassword"
}
```

**Response (200):**
```json
{
  "statusCode": 200,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
    "user": {
      "id": "uuid",
      "email": "admin@ews.com",
      "name": "Admin EWS",
      "role": "ADMIN"
    }
  }
}
```

#### POST `/api/auth/refresh`
Refresh access token.

**Request Body:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
}
```

#### POST `/api/auth/logout`
🔒 **Auth Required**

---

### 2. Water Level Module

#### GET `/api/water-levels/current`
Mendapatkan data ketinggian air terbaru dari semua sensor. *(Public)*

**Response (200):**
```json
{
  "statusCode": 200,
  "data": [
    {
      "id": "uuid",
      "sensorId": "SENSOR-001",
      "sensorName": "Sensor Hulu Sungai A",
      "waterLevel": 2.5,
      "unit": "meter",
      "status": "NORMAL",
      "latitude": -6.9175,
      "longitude": 107.6191,
      "recordedAt": "2026-02-23T10:30:00Z"
    }
  ]
}
```

#### GET `/api/water-levels/history?sensorId={id}&startDate={date}&endDate={date}`
Data historis ketinggian air. *(Public)*

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| sensorId | string | Yes | ID sensor |
| startDate | ISO 8601 | Yes | Tanggal mulai |
| endDate | ISO 8601 | Yes | Tanggal akhir |
| interval | string | No | `hourly`, `daily`, `weekly` (default: `hourly`) |

#### GET `/api/water-levels/:sensorId/latest`
Data terbaru dari sensor spesifik. *(Public)*

---

### 3. Rainfall Module

#### GET `/api/rainfall/current`
Data curah hujan terkini dari semua sensor. *(Public)*

**Response (200):**
```json
{
  "statusCode": 200,
  "data": [
    {
      "id": "uuid",
      "sensorId": "RAIN-001",
      "sensorName": "Sensor Curah Hujan A",
      "rainfall": 15.2,
      "unit": "mm/hour",
      "intensity": "MODERATE",
      "latitude": -6.9175,
      "longitude": 107.6191,
      "recordedAt": "2026-02-23T10:30:00Z"
    }
  ]
}
```

**Rainfall Intensity Classification:**
| Intensity | Range (mm/hour) |
|-----------|-----------------|
| LIGHT | 0 - 5 |
| MODERATE | 5 - 20 |
| HEAVY | > 20 |

---

### 4. Sensor Management Module 🔒

#### GET `/api/sensors`
Daftar semua sensor beserta status kesehatan. 🔒 **Auth Required**

**Response (200):**
```json
{
  "statusCode": 200,
  "data": [
    {
      "id": "uuid",
      "sensorId": "SENSOR-001",
      "name": "Sensor Hulu Sungai A",
      "type": "WATER_LEVEL",
      "latitude": -6.9175,
      "longitude": 107.6191,
      "batteryLevel": 85,
      "connectivity": "ONLINE",
      "lastActiveAt": "2026-02-23T10:30:00Z",
      "installedAt": "2025-01-15T00:00:00Z"
    }
  ]
}
```

#### POST `/api/sensors`
Tambah sensor baru. 🔒 **Auth Required**

#### PUT `/api/sensors/:id`
Update informasi sensor. 🔒 **Auth Required**

#### DELETE `/api/sensors/:id`
Hapus sensor. 🔒 **Auth Required**

---

### 5. Threshold Settings Module 🔒

#### GET `/api/thresholds`
Mendapatkan pengaturan ambang batas saat ini. 🔒 **Auth Required**

**Response (200):**
```json
{
  "statusCode": 200,
  "data": {
    "waterLevel": {
      "normal": { "min": 0, "max": 3.0 },
      "warning": { "min": 3.0, "max": 5.0 },
      "danger": { "min": 5.0, "max": null }
    },
    "rainfall": {
      "light": { "min": 0, "max": 5 },
      "moderate": { "min": 5, "max": 20 },
      "heavy": { "min": 20, "max": null }
    }
  }
}
```

#### PUT `/api/thresholds`
Update pengaturan ambang batas. 🔒 **Auth Required**

---

### 6. Alert Module

#### GET `/api/alerts/active`
Mendapatkan alert aktif saat ini. *(Public)*

#### POST `/api/alerts/broadcast`
Kirim notifikasi massal. 🔒 **Auth Required**

**Request Body:**
```json
{
  "title": "PERINGATAN BANJIR",
  "message": "Ketinggian air Sungai A telah mencapai level bahaya. Segera lakukan evakuasi.",
  "severity": "DANGER",
  "channels": ["PUSH", "WHATSAPP", "EMAIL"],
  "targetArea": "Kecamatan X"
}
```

#### GET `/api/alerts/history?page={page}&limit={limit}`
Riwayat alert. 🔒 **Auth Required**

---

### 7. Report Module 🔒

#### GET `/api/reports/generate?type={type}&startDate={date}&endDate={date}&format={format}`
Generate laporan. 🔒 **Auth Required**

**Query Parameters:**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| type | string | Yes | `water_level`, `rainfall`, `combined` |
| startDate | ISO 8601 | Yes | Tanggal mulai |
| endDate | ISO 8601 | Yes | Tanggal akhir |
| format | string | Yes | `pdf`, `excel` |

**Response:** File download (binary)

---

### 8. User Management Module 🔒

#### GET `/api/users`
Daftar semua petugas. 🔒 **Auth Required (SUPER_ADMIN)**

#### POST `/api/users`
Tambah petugas baru. 🔒 **Auth Required (SUPER_ADMIN)**

#### PUT `/api/users/:id`
Update data petugas. 🔒 **Auth Required (SUPER_ADMIN)**

#### DELETE `/api/users/:id`
Hapus petugas. 🔒 **Auth Required (SUPER_ADMIN)**

---

### 9. Emergency Contacts Module

#### GET `/api/emergency-contacts`
Daftar kontak darurat. *(Public)*

**Response (200):**
```json
{
  "statusCode": 200,
  "data": [
    {
      "id": "uuid",
      "name": "BPBD Kota Bandung",
      "phone": "022-123456",
      "category": "BPBD",
      "isActive": true
    },
    {
      "id": "uuid",
      "name": "SAR Nasional",
      "phone": "115",
      "category": "SAR",
      "isActive": true
    }
  ]
}
```

---

### 10. Location/Map Module

#### GET `/api/locations/sensors`
Daftar lokasi semua sensor untuk ditampilkan di peta. *(Public)*

**Response (200):**
```json
{
  "statusCode": 200,
  "data": [
    {
      "sensorId": "SENSOR-001",
      "name": "Sensor Hulu Sungai A",
      "type": "WATER_LEVEL",
      "latitude": -6.9175,
      "longitude": 107.6191,
      "status": "NORMAL",
      "currentValue": 2.5
    }
  ]
}
```

---

## WebSocket Events

### Connection
```
ws://localhost:3001/ws
```

### Events (Server → Client)

| Event | Description | Payload |
|-------|-------------|---------|
| `water-level:update` | Update ketinggian air real-time | `{ sensorId, waterLevel, status, recordedAt }` |
| `rainfall:update` | Update curah hujan real-time | `{ sensorId, rainfall, intensity, recordedAt }` |
| `alert:new` | Alert baru dari sistem | `{ id, title, message, severity, createdAt }` |
| `sensor:status` | Perubahan status sensor | `{ sensorId, connectivity, batteryLevel }` |

---

## Error Response Format

```json
{
  "statusCode": 400,
  "message": "Validation error message",
  "error": "Bad Request"
}
```

## HTTP Status Codes

| Code | Description |
|------|-------------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |
| 500 | Internal Server Error |
