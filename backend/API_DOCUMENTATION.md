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
