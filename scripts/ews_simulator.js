/**
 * EWS Flood Guard - IoT Device Telemetry Simulator
 * Mengikuti spesifikasi payload dari kode Node MCU / ESP8266 Arduino IDE
 */

// Konfigurasi Target API (Sesuaikan port dengan backend NestJS Anda)
const API_URL = "http://localhost:4101/api/iot/ingest"; 

const SENSOR_IDS = {
  RAIN: "EWS-RF-002",
  WATER: "EWS-US-001",
  FLOW: "EWS-FL-001"
};

// Batas Maksimal sesuai kalibrasi Arduino IDE (Tinggi wadah 17.0 cm)
const TANK_HEIGHT_CM = 17.0;

// State Awal Simulator
let currentWaterLevel = 2.0;   // Mulai dari 2 cm (Aman / Hijau)
let currentRainfall = 0.0;     // mm/hour
let currentFlowRate = 0.0;     // L/min
let isFlooding = true;         // True = air naik, False = air surut
let cycleCount = 0;

// Fungsi untuk mendapatkan status warna (Sama seperti logika getWaterStatus di Arduino)
function getWaterStatus(level) {
  if (level < 4.25) return "🟢 Hijau (Normal)";
  if (level < 8.50) return "🟡 Kuning (Waspada)";
  if (level < 12.75) return "🟠 Oranye (Siaga)";
  return "🔴 Merah (Bahaya)";
}

// Logika simulasi perubahan data secara dinamis (Skenario Siklus Banjir)
function updateSensorData() {
  cycleCount++;

  if (isFlooding) {
    // Fase Hujan & Air Naik
    currentRainfall = parseFloat((Math.random() * 15 + 25).toFixed(2)); // Hujan deras (25 - 40 mm/h)
    currentFlowRate = parseFloat((Math.random() * 20 + 30).toFixed(2)); // Aliran deras (30 - 50 L/min)
    currentWaterLevel += parseFloat((Math.random() * 1.5 + 0.5).toFixed(2)); // Air naik cepat
    
    // Jika hampir menyentuh batas atas tangki, balikkan menjadi surut
    if (currentWaterLevel >= TANK_HEIGHT_CM - 1.5) {
      currentWaterLevel = TANK_HEIGHT_CM - 1.5;
      isFlooding = false;
      console.log("\n⚠️ [SIMULATOR] Titik tertinggi banjir tercapai! Memasuki fase air surut...");
    }
  } else {
    // Fase Hujan Berhenti & Air Surut
    currentRainfall = parseFloat((Math.random() * 2).toFixed(2));       // Gerimis / Berhenti
    currentFlowRate = parseFloat((Math.random() * 5 + 5).toFixed(2));   // Aliran melambat
    currentWaterLevel -= parseFloat((Math.random() * 1.2 + 0.4).toFixed(2)); // Air surut
    
    // Jika sudah kembali ke kondisi normal, naikkan lagi di siklus berikutnya
    if (currentWaterLevel <= 2.0) {
      currentWaterLevel = 2.0;
      isFlooding = true;
      console.log("\n✨ [SIMULATOR] Air telah sepenuhnya surut. Memulai siklus banjir baru...");
    }
  }

  // Jaga agar nilai water level tetap dalam batas aman clamp float (0 - 17 cm)
  currentWaterLevel = Math.max(0.0, Math.min(currentWaterLevel, TANK_HEIGHT_CM));
}

// Fungsi utama mengirimkan data ke NestJS Backend
async function sendTelemetry() {
  updateSensorData();

  // Struktur Payload persis seperti yang disusun di String payload pada Arduino IDE
  const payload = {
    rainSensorId: SENSOR_IDS.RAIN,
    rainfall: currentRainfall,
    waterSensorId: SENSOR_IDS.WATER,
    waterLevel: parseFloat(currentWaterLevel.toFixed(2)),
    flowSensorId: SENSOR_IDS.FLOW,
    flowRate: currentFlowRate
  };

  console.log(`\n[Siklus #${cycleCount}] Mengirimkan Data Telemetri...`);
  console.log(`| Air: ${payload.waterLevel} cm -> ${getWaterStatus(payload.waterLevel)}`);
  console.log(`| Hujan: ${payload.rainfall} mm/h | Aliran: ${payload.flowRate} L/min`);

  try {
    const response = await fetch(API_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify(payload)
    });

    const status = response.status;
    let resText = "";
    try {
      resText = await response.text();
    } catch (_) {}

    if (status === 200 || status === 201 || status === 210) {
      console.log(`✅ Berhasil! HTTP Code: ${status} | Response: ${resText}`);
    } else {
      console.log(`❌ Gagal! HTTP Code: ${status} | Response: ${resText}`);
    }
  } catch (error) {
    console.error(`🚨 Koneksi Gagal! Apakah Backend NestJS Anda menyala di ${API_URL}?`);
    console.error(`  Error Detail: ${error.message}`);
  }
}

// Mulai jalankan simulasi setiap 5 detik (Menyamakan SEND_INTERVAL_MS = 5000)
console.log("==========================================================");
console.log("🚀 EWS FLOOD GUARD - IOT DEVICE TELEMETRY SIMULATOR RUNNING");
console.log(`Target URL : ${API_URL}`);
console.log("Interval   : 5000ms (5 Detik)");
console.log("==========================================================");

setInterval(sendTelemetry, 5000);
// Jalankan langsung tembakan pertama tanpa menunggu delay 5 detik awal
sendTelemetry();