#include <ESP8266WiFi.h>
#include <ESP8266HTTPClient.h>

#define RAIN_DIGITAL_PIN    D1
#define RAIN_ANALOG_PIN     A0
#define WATER_FLOW_PIN      D2
#define ULTRASONIC_TRIG_PIN D5
#define ULTRASONIC_ECHO_PIN D6

const char* WIFI_SSID      = "Orange_kost_4G";
const char* WIFI_PASSWORD  = "Anara@2712";
const char* API_URL        = "http://192.168.1.12:3001/api/iot/ingest";
const char* RAIN_SENSOR_ID = "EWS-RF-002";
const char* FLOW_SENSOR_ID = "EWS-FL-001";
const char* WATER_SENSOR_ID = "EWS-US-001";

// Kalibrasi (ubah setelah lihat nilai A0)
const int   RAIN_ANALOG_DRY = 900;  // kering
const int   RAIN_ANALOG_WET = 200;  // basah
const float RAIN_MM_PER_HOUR_MAX = 50.0;

// Kalibrasi waterflow (contoh YF-S201 = 450 pulses per liter)
const float FLOW_PULSES_PER_LITER = 450.0;

// Tinggi maksimum air (jarak sensor ke dasar, cm)
const float TANK_HEIGHT_CM = 17.0;

// Ultrasonic timeout (microseconds)
const unsigned long ULTRASONIC_TIMEOUT_US = 30000;

const unsigned long SEND_INTERVAL_MS = 5000;
unsigned long previousMillis = 0;

volatile unsigned long flowPulseCount = 0;

void IRAM_ATTR onFlowPulse() {
  flowPulseCount++;
}

void connectWiFi() {
  if (WiFi.status() == WL_CONNECTED) return;
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  unsigned long start = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - start < 15000) {
    delay(250);
  }
}

float clampFloat(float v, float lo, float hi) {
  if (v < lo) return lo;
  if (v > hi) return hi;
  return v;
}

float readUltrasonicCm() {
  digitalWrite(ULTRASONIC_TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(ULTRASONIC_TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(ULTRASONIC_TRIG_PIN, LOW);

  unsigned long duration = pulseIn(ULTRASONIC_ECHO_PIN, HIGH, ULTRASONIC_TIMEOUT_US);
  if (duration == 0) return -1.0;

  float distanceCm = (duration * 0.0343f) / 2.0f;
  return distanceCm;
}

const char* getWaterStatus(float levelCm) {
  if (levelCm < 4.25f) return "Hijau";   // Normal
  if (levelCm < 8.50f) return "Kuning";  // Waspada
  if (levelCm < 12.75f) return "Oranye"; // Siaga
  return "Merah";                        // Bahaya
}

void setup() {
  Serial.begin(115200);
  pinMode(RAIN_DIGITAL_PIN, INPUT_PULLUP);
  pinMode(WATER_FLOW_PIN, INPUT_PULLUP);
  pinMode(ULTRASONIC_TRIG_PIN, OUTPUT);
  pinMode(ULTRASONIC_ECHO_PIN, INPUT);
  attachInterrupt(digitalPinToInterrupt(WATER_FLOW_PIN), onFlowPulse, RISING);

  connectWiFi();
  Serial.println("SISTEM MONITORING RAIN GAUGE + WATERFLOW + ULTRASONIC");
}

void loop() {
  connectWiFi();

  unsigned long now = millis();
  if (now - previousMillis >= SEND_INTERVAL_MS) {
    int rainDigital = digitalRead(RAIN_DIGITAL_PIN);
    int rainAnalog  = analogRead(RAIN_ANALOG_PIN);

    bool rainDetected = (rainDigital == LOW);

    float rainfallMm = 0.0;
    if (rainDetected) {
      float denom = (float)(RAIN_ANALOG_DRY - RAIN_ANALOG_WET);
      if (denom > 0.0) {
        float ratio = (RAIN_ANALOG_DRY - rainAnalog) / denom;
        ratio = clampFloat(ratio, 0.0, 1.0);
        rainfallMm = ratio * RAIN_MM_PER_HOUR_MAX;
      }
    }

    unsigned long pulses;
    noInterrupts();
    pulses = flowPulseCount;
    flowPulseCount = 0;
    interrupts();

    float intervalSec = (now - previousMillis) / 1000.0;
    float flowVolumeL = 0.0;
    float flowRateLpm = 0.0;

    if (intervalSec > 0.0) {
      flowVolumeL = pulses / FLOW_PULSES_PER_LITER;
      flowRateLpm = (flowVolumeL / intervalSec) * 60.0;
    }

    float distanceCm = readUltrasonicCm();
    float waterLevelCm = -1.0;
    const char* waterStatus = "UNKNOWN";

    if (distanceCm > 0.0) {
      waterLevelCm = clampFloat(TANK_HEIGHT_CM - distanceCm, 0.0, TANK_HEIGHT_CM);
      waterStatus = getWaterStatus(waterLevelCm);
    }

    String payload = "{";
    payload += "\"rainSensorId\":\"" + String(RAIN_SENSOR_ID) + "\",";
    payload += "\"rainfall\":" + String(rainfallMm, 2) + ",";
    payload += "\"waterSensorId\":\"" + String(WATER_SENSOR_ID) + "\",";
    if (waterLevelCm >= 0.0) {
      payload += "\"waterLevel\":" + String(waterLevelCm, 2) + ",";
    } else {
      payload += "\"waterLevel\":null,";
    }
    payload += "\"flowSensorId\":\"" + String(FLOW_SENSOR_ID) + "\",";
    payload += "\"flowRate\":" + String(flowRateLpm, 2);
    payload += "}";

    if (WiFi.status() == WL_CONNECTED) {
      WiFiClient client;
      HTTPClient http;

      http.begin(client, API_URL);
      http.addHeader("Content-Type", "application/json");

      int httpCode = http.POST(payload);
      String response = http.getString();

      Serial.println("\n========================");
      Serial.print("POST "); Serial.println(API_URL);
      Serial.print("HTTP Code: "); Serial.println(httpCode);
      Serial.print("Response: "); Serial.println(response);
      Serial.print("RAIN DIGITAL (D1): "); Serial.println(rainDigital);
      Serial.print("RAIN ANALOG (A0): "); Serial.println(rainAnalog);
      Serial.print("RAINFALL (mm/h): "); Serial.println(rainfallMm);
      Serial.print("FLOW PULSES: "); Serial.println(pulses);
      Serial.print("FLOW RATE (L/min): "); Serial.println(flowRateLpm, 2);
      Serial.print("FLOW VOLUME (L): "); Serial.println(flowVolumeL, 3);
      Serial.print("ULTRASONIC DIST (cm): "); Serial.println(distanceCm, 2);
      Serial.print("WATER LEVEL (cm): "); Serial.println(waterLevelCm, 2);
      Serial.print("WATER STATUS: "); Serial.println(waterStatus);
      Serial.println("========================");

      http.end();
    } else {
      Serial.println("WiFi belum terhubung, data tidak terkirim.");
    }

    previousMillis = now;
  }
}
