# IoT Sensor Data Ingestion API

Complete guide for integrating ESP8266 and other IoT devices with the Flood Guard EWS backend.

## Overview

The IoT Ingest endpoint provides a single HTTP endpoint to receive sensor readings from IoT devices and safely store them in the database with automatic validation, status calculation, and sensor metadata updates.

**Endpoint:** `POST /api/iot/ingest`  
**Authentication:** None required (unsecured for IoT device compatibility)  
**Rate Limit:** Recommended 1 request per 5 seconds per device (adaptive based on device capability)

---

## API Contract

### Request

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

### Request Fields

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `waterSensorId` | string | Conditional* | Sensor ID from admin panel (must exist and be WATER_LEVEL type) |
| `waterLevel` | number | Conditional* | Water level in **centimeters** (cm). Must be ≥ 0 |
| `rainSensorId` | string | Conditional* | Sensor ID from admin panel (must exist and be RAINFALL type) |
| `rainfall` | number | Conditional* | Rainfall in **mm/hour**. Must be ≥ 0 |
| `flowSensorId` | string | Conditional* | Sensor ID from admin panel (must exist and be FLOW_RATE type) |
| `flowRate` | number | Conditional* | Flow rate in **l/min** (liters per minute). Must be ≥ 0 |
| `batteryLevel` | number | Optional | Battery percentage (0-100). If provided, updates sensor's battery level |
| `connectivity` | string | Optional | One of: `ONLINE`, `OFFLINE`, `MAINTENANCE`. Default: `ONLINE` |
| `recordedAt` | string (ISO8601) | Optional | Timestamp when reading was taken. Format: `2026-05-17T10:30:00Z`. If omitted, server uses current time |
| `sensorId` | string | Deprecated | Legacy field (single sensor). Use specific `waterSensorId`/`rainSensorId`/`flowSensorId` instead |

**\* Conditional:** At least ONE of (waterLevel, rainfall, flowRate) must be provided. The sensor ID for the reading type can be either the specific field (e.g., `waterSensorId`) or the generic `sensorId` field (for backward compatibility).

### Response (Success - HTTP 201)

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

### Response Fields

| Field | Type | Notes |
|-------|------|-------|
| `recordedAt` | string | ISO timestamp when the reading was recorded |
| `water.status` | string | Calculated status: `NORMAL`, `WARNING`, `ALERT`, `DANGER` (based on thresholds) |
| `rainfall.intensity` | string | Calculated intensity: `LIGHT`, `MODERATE`, `HEAVY` (based on thresholds) |
| `flowRate.unit` | string | Always `l/min` |

---

## Error Responses

### 400 Bad Request - Missing Required Data

```json
{
  "status": "error",
  "message": "At least one of: waterLevel, rainfall, or flowRate must be provided",
  "statusCode": 400
}
```

### 400 Bad Request - Invalid Value

```json
{
  "status": "error",
  "message": "Validation failed",
  "errors": ["waterLevel must be >= 0", "batteryLevel must be <= 100"],
  "statusCode": 400
}
```

### 400 Bad Request - Invalid Date

```json
{
  "status": "error",
  "message": "recordedAt tidak valid.",
  "statusCode": 400
}
```

### 404 Not Found - Sensor Does Not Exist

```json
{
  "status": "error",
  "message": "Sensor water level tidak ditemukan.",
  "statusCode": 404
}
```

**Note:** Sensor must:
- Exist in the admin panel (created via Admin → Manajemen Sensor IoT)
- Have the correct type (WATER_LEVEL, RAINFALL, or FLOW_RATE)
- Have `isActive = true`

### 500 Internal Server Error

```json
{
  "status": "error",
  "message": "Internal server error",
  "statusCode": 500
}
```

---

## Data Storage & Processing

### Automatic Operations on Success

When data is successfully ingested, the backend automatically:

1. **Validates** sensor existence and type
2. **Calculates Status/Intensity** based on configured thresholds
3. **Stores Log Entry** in appropriate table:
   - `water_level_logs` for water level readings
   - `rainfall_logs` for rainfall readings
   - `flow_rate_logs` for flow rate readings
4. **Updates Sensor Metadata:**
   - `lastActiveAt` = current/provided timestamp
   - `connectivity` = provided value or default ONLINE
   - `batteryLevel` = rounded integer (if provided)

### Units & Formats

| Reading | Unit | Database Column |
|---------|------|-----------------|
| Water Level | **cm** (centimeters) | `water_level` |
| Rainfall | **mm/hour** | `rainfall` |
| Flow Rate | **l/min** (liters/minute) | `flow_rate` |
| Battery | **%** (percentage) | `battery_level` |

### Status/Intensity Calculation

**Water Level Status** (based on `threshold.type = 'water_level'`):
- DANGER: waterLevel >= `dangerMin` (default: 221 cm)
- WARNING: waterLevel >= `warningMin` (default: 151 cm)
- NORMAL: waterLevel < `warningMin`

**Rainfall Intensity** (based on `threshold.type = 'rainfall'`):
- HEAVY: rainfall >= `dangerMin` (default: 20 mm/hr)
- MODERATE: rainfall >= `warningMin` (default: 5 mm/hr)
- LIGHT: rainfall < `warningMin`

---

## Testing with cURL

### Single Water Level Reading

```bash
curl -X POST http://localhost:3001/api/iot/ingest \
  -H "Content-Type: application/json" \
  -d '{
    "waterSensorId": "EWS-US-001",
    "waterLevel": 12.30,
    "batteryLevel": 85,
    "connectivity": "ONLINE"
  }'
```

### All Three Sensors in One Request

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
    "batteryLevel": 85,
    "connectivity": "ONLINE",
    "recordedAt": "2026-05-17T10:30:00Z"
  }'
```

### Testing Error Scenario (Missing Sensor ID)

```bash
curl -X POST http://localhost:3001/api/iot/ingest \
  -H "Content-Type: application/json" \
  -d '{
    "waterLevel": 12.30
  }'

# Response:
# {
#   "status": "error",
#   "message": "waterSensorId atau sensorId wajib diisi.",
#   "statusCode": 400
# }
```

---

## Postman Collection

### Import to Postman

1. Create a new **POST** request
2. URL: `{{base_url}}/iot/ingest` (or `http://localhost:3001/api/iot/ingest`)
3. Headers:
   - `Content-Type: application/json`
4. Body (raw JSON):

```json
{
  "waterSensorId": "EWS-US-001",
  "waterLevel": 12.30,
  "rainSensorId": "EWS-RF-002",
  "rainfall": 25.50,
  "flowSensorId": "EWS-FL-001",
  "flowRate": 5.20,
  "batteryLevel": 85,
  "connectivity": "ONLINE"
}
```

### Postman Environment Variables

```
base_url = http://localhost:3001/api
water_sensor_id = EWS-US-001
rain_sensor_id = EWS-RF-002
flow_sensor_id = EWS-FL-001
```

---

## Implementation Guide for IoT Devices

### ESP8266/Arduino Setup

See `ESP8266_IOT_EXAMPLE.ino` in this directory for complete example code.

**Key Steps:**
1. Configure WiFi SSID and password
2. Update `API_HOST` to your backend server IP/domain
3. Verify sensor IDs match those in admin panel
4. Implement sensor reading functions (water level, rainfall, flow rate, battery)
5. Call `sendSensorData()` every 5-60 seconds based on device capability

**Required Libraries:**
- `ESP8266WiFi.h` (built-in)
- `ESP8266HTTPClient.h` (built-in)
- `ArduinoJson.h` (v6.19+) - Install via Arduino Library Manager

### Time Synchronization

For accurate `recordedAt` timestamps, synchronize with NTP:

```cpp
configTime(7 * 3600, 0, "pool.ntp.org"); // UTC+7 (Indonesia)
```

If NTP is unavailable, omit `recordedAt` and server will use current time.

### Recommended Polling Intervals

| Device Type | Polling Interval | Notes |
|-------------|-----------------|-------|
| ESP8266/ESP32 | 5-10 seconds | Good balance for near real-time + device capability |
| Arduino with SD | 30-60 seconds | Slower WiFi/SD access |
| Raspberry Pi | 1-5 seconds | Higher performance capable |
| LoRaWAN Gateway | 60+ seconds | Low power considerations |

---

## Troubleshooting

### "Sensor tidak ditemukan"

**Cause:** Sensor ID does not exist in the database or has wrong type.

**Solution:**
1. Go to **Admin → Manajemen Sensor IoT**
2. Create sensor with ID matching your device (e.g., `EWS-US-001`)
3. Set correct type: `WATER_LEVEL`, `RAINFALL`, or `FLOW_RATE`
4. Ensure checkbox **Aktif** is checked

### "At least one of: waterLevel, rainfall, or flowRate must be provided"

**Cause:** Request body is missing all sensor readings.

**Solution:**
- Ensure your device is actually reading sensor values
- Check for parsing errors (NaN, null, undefined)
- Verify JSON is being serialized correctly

### "recordedAt tidak valid"

**Cause:** `recordedAt` field is not ISO 8601 format.

**Solution:**
- Use format: `2026-05-17T10:30:00Z` (with 'Z' for UTC)
- Or omit `recordedAt` to use server timestamp

### Connection Timeout

**Cause:** Backend server unreachable.

**Solution:**
1. Verify `API_HOST` IP is correct
2. Ping server from device network
3. Check firewall rules
4. Verify backend is running: `docker ps` or `pm2 list`

### HTTP 400 - batteryLevel must be <= 100

**Cause:** Sending battery > 100% or NaN value.

**Solution:**
- Calculate battery percentage correctly (0-100 only)
- Use `round()` or `constrain()` in Arduino code

---

## Database Schema

### water_level_logs Table

```sql
CREATE TABLE water_level_logs (
  id uuid PRIMARY KEY,
  sensor_id uuid NOT NULL,
  water_level float NOT NULL,
  unit varchar(50) DEFAULT 'meter',
  status varchar(50) NOT NULL,
  recorded_at timestamp NOT NULL,
  created_at timestamp DEFAULT NOW()
);
```

### rainfall_logs Table

```sql
CREATE TABLE rainfall_logs (
  id uuid PRIMARY KEY,
  sensor_id uuid NOT NULL,
  rainfall float NOT NULL,
  unit varchar(50) DEFAULT 'mm/hour',
  intensity varchar(50) NOT NULL,
  recorded_at timestamp NOT NULL,
  created_at timestamp DEFAULT NOW()
);
```

### flow_rate_logs Table

```sql
CREATE TABLE flow_rate_logs (
  id uuid PRIMARY KEY,
  sensor_id uuid NOT NULL,
  flow_rate float NOT NULL,
  unit varchar(50) DEFAULT 'l/min',
  recorded_at timestamp NOT NULL,
  created_at timestamp DEFAULT NOW()
);
```

---

## Migration Notes

If you're upgrading from a single-sensor endpoint:

1. Old field `sensorId` still works but is deprecated
2. Use specific `waterSensorId`, `rainSensorId`, `flowSensorId` instead
3. Multiple readings in one request are now supported (all three types)
4. No database migration required; schema is already compatible

---

## Performance Considerations

### Optimization Tips

1. **Batch Requests:** If possible, send multiple readings in single request (all 3 sensor types)
2. **Reduce Frequency:** Sending every 5s vs 1s reduces database load 5x
3. **Connection Pooling:** Backend uses PrismaORM with optimized connection pooling (pool_size: 15)
4. **Stateless Design:** Each request is independent; no session state

### Load Testing

For 100 devices sending every 5 seconds:
- Request Rate: ~20 req/sec
- Database: ~60 writes/sec (3 table types)
- Estimated Load: Minimal on modern hardware (t3.small AWS adequate)

---

## Security Notes

⚠️ **Current Status:** Endpoint is **unauthenticated** (no API key required)

For production, consider:
1. Adding Bearer token authentication
2. Rate limiting per device IP
3. HTTPS enforcement
4. Sensor ID validation/allowlisting

---

## Support

For issues or questions:
- Check logs: `docker logs early-warning-system-backend`
- Verify sensor exists in admin panel
- Test with cURL first before integrating device code
- Enable debug logging in IoT service if needed
