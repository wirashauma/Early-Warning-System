# EWS Flood Guard - API Contract (Mobile & Web)

Dokumentasi ini ditujukan untuk tim pengembangan aplikasi mobile (Flutter/Android/iOS) dan sinkronisasi dengan tim Web.

**Base URL:** `http://<server-ip>:3001/api`
**Format Response:** JSON (Standardized)

---

## Standard Response Format

Seluruh endpoint mengembalikan struktur JSON yang konsisten untuk mempermudah parsing di sisi Mobile (Dio/Retrofit).

### Success Response
```json
{
  "status": "success",
  "message": "Operation successful",
  "data": { ... } // Objek atau Array data
}
```

### Error Response
```json
{
  "status": "error",
  "message": "Pesan error untuk user",
  "errors": ["Detail error 1", "Detail error 2"], // Jika ada validasi gagal
  "statusCode": 400,
  "timestamp": "2024-05-03T08:00:00Z",
  "path": "/api/..."
}
```

---

## 1. Authentication Module

### Login
*   **Method:** `POST`
*   **URL:** `/auth/login`
*   **Body:**
    ```json
    {
      "email": "user@example.com",
      "password": "password123"
    }
    ```
*   **Response Success:** `data` berisi `accessToken`, `refreshToken`, dan objek `user`.

### Get My Profile (Me)
Gunakan saat aplikasi Cold Start untuk validasi session.
*   **Method:** `GET`
*   **URL:** `/auth/me`
*   **Headers:** `Authorization: Bearer <token>`

---

## 2. Water Levels Module

### Current Status
*   **Method:** `GET`
*   **URL:** `/water-levels/current`

### History (PAGINATED)
*   **Method:** `GET`
*   **URL:** `/water-levels/history?sensorId=S01&startDate=2024-05-01&endDate=2024-05-03&page=1&limit=20`
*   **Query Params:**
    *   `sensorId`: ID Sensor (contoh: S01)
    *   `startDate`: ISO Date
    *   `endDate`: ISO Date
    *   `page`: Nomor halaman (Default: 1)
    *   `limit`: Data per halaman (Default: 20)

---

## 2.1 IoT Ingest Module

### Ingest Sensor Data (ESP8266 / IoT Devices)
*   **Method:** `POST`
*   **URL:** `/iot/ingest`
*   **Authentication:** None (public endpoint for IoT devices)
*   **Body (All Sensors):**
    ```json
    {
      "waterSensorId": "EWS-US-001",
      "waterLevel": 12.30,
      "rainSensorId": "EWS-RF-002",
      "rainfall": 25.50,
      "flowSensorId": "EWS-FL-001",
      "flowRate": 5.20,
      "batteryLevel": 85,
      "connectivity": "ONLINE",
      "recordedAt": "2026-05-17T10:30:00Z"
    }
    ```
*   **Notes:**
    * `waterLevel` dalam cm, `rainfall` dalam mm/hour, `flowRate` dalam l/min.
    * Gunakan specific sensor IDs (`waterSensorId`, `rainSensorId`, `flowSensorId`) instead of generic `sensorId`.
    * Minimal satu dari: `waterLevel`, `rainfall`, atau `flowRate` harus ada.
    * `recordedAt` optional; server gunakan current time jika omitted.
    * `batteryLevel` range 0-100%.
    * Response mencakup calculated `status` (water) dan `intensity` (rainfall) based on thresholds.
    * Semua sensor readings dalam satu request di-process secara atomik.

*   **Response Success (201):**
    ```json
    {
      "status": "success",
      "message": "Ingest accepted",
      "data": {
        "recordedAt": "2026-05-17T10:30:00Z",
        "water": {
          "sensorId": "EWS-US-001",
          "waterLevel": 12.30,
          "status": "NORMAL"
        },
        "rainfall": {
          "sensorId": "EWS-RF-002",
          "rainfall": 25.50,
          "intensity": "HEAVY"
        },
        "flowRate": {
          "sensorId": "EWS-FL-001",
          "flowRate": 5.20,
          "unit": "l/min"
        }
      }
    }
    ```

*   **Validation Rules:**
    * `waterLevel`, `rainfall`, `flowRate` must be >= 0
    * `batteryLevel` must be 0-100
    * `connectivity` must be: ONLINE, OFFLINE, or MAINTENANCE
    * At least one sensor reading must be provided
    * Sensor ID must exist in database with correct type (WATER_LEVEL, RAINFALL, FLOW_RATE)

*   **Common Errors:**
    * 400 - "At least one of: waterLevel, rainfall, or flowRate must be provided"
    * 400 - "waterLevel must be >= 0"
    * 400 - "batteryLevel must be <= 100"
    * 404 - "Sensor water level tidak ditemukan" (sensor doesn't exist)

*   **Setup Required:**
    1. Create sensors in Admin → Manajemen Sensor IoT with exact IDs matching device
    2. Set sensor type: WATER_LEVEL, RAINFALL, or FLOW_RATE
    3. Ensure "Aktif" checkbox is checked
    4. Update device `waterSensorId`, `rainSensorId`, `flowSensorId` constants to match

*   **Example ESP8266 Code:**
    * See `ESP8266_IOT_EXAMPLE.ino` in backend directory
    * Full documentation: `IOT_INGEST_GUIDE.md`

*   **Testing with cURL:**
    ```bash
    curl -X POST http://localhost:3001/api/iot/ingest \
      -H "Content-Type: application/json" \
      -d '{
        "waterSensorId": "EWS-US-001",
        "waterLevel": 12.30,
        "rainSensorId": "EWS-RF-002",
        "rainfall": 25.50,
        "flowSensorId": "EWS-FL-001",
        "flowRate": 5.20,
        "batteryLevel": 85
      }'
    ```

---

## 3. Alerts & FCM Module

### Subscribe FCM Token (IDEMPOTENT)
Daftarkan token FCM perangkat. Aman dipanggil berulang kali.
*   **Method:** `POST`
*   **URL:** `/alerts/subscribe`
*   **Body:**
    ```json
    {
      "token": "FCM_TOKEN_DEVICE",
      "targetArea": "Padang Utara"
    }
    ```

### Active Alerts
Peringatan yang sedang aktif (6 jam terakhir).
*   **Method:** `GET`
*   **URL:** `/alerts/active`

### History Alerts (PAGINATED)
*   **Method:** `GET`
*   **URL:** `/alerts/history?page=1&limit=10`

---

## 4. Sensors Module

### List Sensors (PAGINATED)
*   **Method:** `GET`
*   **URL:** `/sensors?page=1&limit=20`

---

## 5. Emergency Module

### List Contacts
*   **Method:** `GET`
*   **URL:** `/emergency-contacts`
