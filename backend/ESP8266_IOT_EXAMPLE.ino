#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>
#include <ArduinoJson.h>

// ============================================================================
// FLOOD GUARD EWS - ESP8266 IoT Sensor Data Ingestion
// ============================================================================
// This example demonstrates how to send sensor readings every 5 seconds
// to the backend API endpoint POST /iot/ingest
//
// Supported readings in a single request:
// - Water Level (cm) via waterSensorId
// - Rainfall (mm/hour) via rainSensorId  
// - Flow Rate (l/min) via flowSensorId
// ============================================================================

// WiFi Configuration
const char* SSID = "YOUR_WIFI_SSID";
const char* PASSWORD = "YOUR_WIFI_PASSWORD";

// Backend Configuration
const char* API_HOST = "http://192.168.1.100:3001"; // Change to your backend IP/domain
const char* API_ENDPOINT = "/api/iot/ingest";

// Sensor IDs - MUST match sensors created in admin panel
const char* WATER_SENSOR_ID = "EWS-US-001";    // Ultrasonic water level sensor
const char* RAIN_SENSOR_ID = "EWS-RF-002";     // Rain gauge sensor
const char* FLOW_SENSOR_ID = "EWS-FL-001";     // Flow rate sensor

// ============================================================================
// GLOBAL VARIABLES
// ============================================================================
WiFiClient wifiClient;
HTTPClient http;
unsigned long lastSendTime = 0;
const unsigned long SEND_INTERVAL = 5000; // Send every 5 seconds (milliseconds)

// ============================================================================
// SETUP
// ============================================================================
void setup() {
  Serial.begin(115200);
  delay(100);

  Serial.println("\n\n");
  Serial.println("========================================");
  Serial.println("Flood Guard EWS - ESP8266 Sensor Node");
  Serial.println("========================================");

  // Initialize GPIO pins for your sensors (example)
  // pinMode(WATER_SENSOR_PIN, INPUT);
  // pinMode(RAIN_SENSOR_PIN, INPUT);
  // pinMode(FLOW_SENSOR_PIN, INPUT);

  // Connect to WiFi
  connectToWiFi();
}

// ============================================================================
// MAIN LOOP
// ============================================================================
void loop() {
  // Check if it's time to send data
  unsigned long currentTime = millis();
  if (currentTime - lastSendTime >= SEND_INTERVAL) {
    lastSendTime = currentTime;

    // Read sensor values (replace with actual sensor reading logic)
    float waterLevel = readWaterLevel();      // Returns cm
    float rainfall = readRainfall();          // Returns mm/hour
    float flowRate = readFlowRate();          // Returns l/min
    float batteryPercent = readBatteryLevel(); // Returns 0-100

    // Send data to backend
    sendSensorData(waterLevel, rainfall, flowRate, batteryPercent);
  }

  // Keep WiFi connection alive
  if (WiFi.status() != WL_CONNECTED) {
    connectToWiFi();
  }

  delay(100);
}

// ============================================================================
// WIFI CONNECTION
// ============================================================================
void connectToWiFi() {
  Serial.println("\n[WiFi] Connecting...");
  WiFi.mode(WIFI_STA);
  WiFi.begin(SSID, PASSWORD);

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 30) {
    delay(500);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n[WiFi] Connected!");
    Serial.print("[WiFi] IP: ");
    Serial.println(WiFi.localIP());
  } else {
    Serial.println("\n[WiFi] Failed to connect. Will retry...");
  }
}

// ============================================================================
// SENSOR READING FUNCTIONS
// ============================================================================

/**
 * Read water level from ultrasonic sensor
 * Replace with your actual sensor reading logic
 * @return Water level in cm
 */
float readWaterLevel() {
  // TODO: Implement your actual ultrasonic sensor reading
  // Example: Use NewPing library or raw GPIO timing
  
  // For demo, return random value between 10-150 cm
  return random(100, 1500) / 10.0;
}

/**
 * Read rainfall from rain gauge sensor
 * Replace with your actual sensor reading logic
 * @return Rainfall in mm/hour
 */
float readRainfall() {
  // TODO: Implement your actual rain gauge reading
  // Example: Count pulses, convert to mm based on bucket size
  
  // For demo, return random value between 0-50 mm/hour
  return random(0, 500) / 10.0;
}

/**
 * Read flow rate sensor
 * Replace with your actual sensor reading logic
 * @return Flow rate in l/min
 */
float readFlowRate() {
  // TODO: Implement your actual flow rate sensor reading
  // Example: Count pulses from flow meter, convert to l/min
  
  // For demo, return random value between 0-20 l/min
  return random(0, 200) / 10.0;
}

/**
 * Read battery voltage and convert to percentage
 * @return Battery percentage (0-100)
 */
float readBatteryLevel() {
  // TODO: Implement actual battery reading via ADC
  // Example:
  // int rawValue = analogRead(A0);
  // float voltage = rawValue * (3.3 / 1023.0) * 2; // voltage divider factor
  // float percentage = map(voltage, 3.0, 4.2, 0, 100); // Assume LiPo
  
  // For demo, return random value between 30-100%
  return random(30, 100);
}

// ============================================================================
// SEND SENSOR DATA TO BACKEND
// ============================================================================
void sendSensorData(float waterLevel, float rainfall, float flowRate, float battery) {
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("[IoT] WiFi not connected, skipping send");
    return;
  }

  // Create JSON payload
  StaticJsonDocument<256> doc;
  doc["waterSensorId"] = WATER_SENSOR_ID;
  doc["waterLevel"] = round(waterLevel * 100) / 100.0; // Round to 2 decimals
  
  doc["rainSensorId"] = RAIN_SENSOR_ID;
  doc["rainfall"] = round(rainfall * 100) / 100.0;
  
  doc["flowSensorId"] = FLOW_SENSOR_ID;
  doc["flowRate"] = round(flowRate * 100) / 100.0;
  
  doc["batteryLevel"] = round(battery);
  doc["connectivity"] = "ONLINE";
  doc["recordedAt"] = getISOTimestamp();

  // Serialize to string
  String payload;
  serializeJson(doc, payload);

  Serial.println("\n[IoT] Sending sensor data...");
  Serial.print("[IoT] Payload: ");
  Serial.println(payload);

  // Send HTTP POST request
  String url = String(API_HOST) + API_ENDPOINT;
  http.begin(wifiClient, url);
  http.addHeader("Content-Type", "application/json");

  int httpResponseCode = http.POST(payload);

  if (httpResponseCode > 0) {
    String response = http.getString();
    Serial.print("[IoT] Response Code: ");
    Serial.println(httpResponseCode);
    Serial.print("[IoT] Response: ");
    Serial.println(response);

    if (httpResponseCode == 200 || httpResponseCode == 201) {
      Serial.println("[IoT] ✓ Data sent successfully!");
    } else {
      Serial.println("[IoT] ✗ Unexpected response code");
    }
  } else {
    Serial.print("[IoT] ✗ Error: ");
    Serial.println(http.errorToString(httpResponseCode));
  }

  http.end();
}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

/**
 * Get current time as ISO 8601 string
 * Note: Requires NTP time synchronization for accurate timestamp
 * @return ISO timestamp string
 */
String getISOTimestamp() {
  // For demo, return a placeholder
  // In production, use configTime() with NTP server:
  // configTime(0, 0, "pool.ntp.org", "time.nist.gov");
  
  time_t now = time(nullptr);
  struct tm timeinfo = *localtime(&now);
  char buffer[30];
  strftime(buffer, sizeof(buffer), "%Y-%m-%dT%H:%M:%SZ", &timeinfo);
  return String(buffer);
}

// ============================================================================
// SETUP TIME SYNC (Optional but recommended)
// ============================================================================
void setupNTP() {
  // Synchronize time with NTP server for accurate timestamps
  configTime(7 * 3600, 0, "pool.ntp.org"); // UTC+7 (Indonesia time)
  Serial.println("[NTP] Syncing time...");
  time_t now = time(nullptr);
  int attempts = 0;
  while (now < 24 * 3600 && attempts < 30) {
    delay(500);
    Serial.print(".");
    now = time(nullptr);
    attempts++;
  }
  Serial.println();
  Serial.println("[NTP] Time synced");
}

// ============================================================================
// COMPLETE REQUEST EXAMPLE (Using curl for testing)
// ============================================================================
/*
curl -X POST http://192.168.1.100:3001/api/iot/ingest \
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

Response (Success - 201):
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
*/
