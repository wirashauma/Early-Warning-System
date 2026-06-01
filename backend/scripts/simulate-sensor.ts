import * as dotenv from 'dotenv';
import { PrismaClient, SensorType, SensorConnectivity } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import axios from 'axios';

dotenv.config();

const connectionString = process.env.DATABASE_URL;
if (!connectionString) {
  console.error('DATABASE_URL not found in environment variables');
  process.exit(1);
}

const pool = new Pool({ connectionString });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

const API_URL = 'http://localhost:4101/api/iot/ingest';

async function main() {
  console.log('🚀 Starting Sensor Hardware Spoofing Simulation...');

  // Log active thresholds
  const thresholds = await prisma.threshold.findMany();
  console.log('📊 Active Thresholds in Database:', JSON.stringify(thresholds));

  // 1. Ensure we have a test user with notificationEmail: true
  let testUser = await prisma.user.findFirst({
    where: { email: 'simulated-user@ews.com' },
  });

  if (!testUser) {
    testUser = await prisma.user.create({
      data: {
        email: 'simulated-user@ews.com',
        password: 'securePassword123',
        name: 'Simulated EWS User',
        role: 'USER',
        notificationEmail: true,
        isActive: true,
      },
    });
    console.log(`✅ Created simulated test user: ${testUser.email} (notificationEmail: true)`);
  } else {
    testUser = await prisma.user.update({
      where: { id: testUser.id },
      data: { notificationEmail: true, isActive: true },
    });
    console.log(`✅ Verified simulated test user: ${testUser.email} has notificationEmail: true`);
  }

  // 2. Ensure we have a rainfall sensor
  let rainSensor = await prisma.sensor.findFirst({
    where: { type: SensorType.RAINFALL, isActive: true },
  });

  if (!rainSensor) {
    rainSensor = await prisma.sensor.create({
      data: {
        sensorId: 'RAIN-SIM-999',
        name: 'Simulated Rainfall Sensor Ciliwung',
        type: SensorType.RAINFALL,
        latitude: -6.2,
        longitude: 106.8,
        batteryLevel: 98,
        connectivity: SensorConnectivity.ONLINE,
        isActive: true,
      },
    });
    console.log(`✅ Created mock rainfall sensor: ${rainSensor.sensorId}`);
  } else {
    console.log(`✅ Using existing rainfall sensor: ${rainSensor.sensorId}`);
  }

  // 3. Ensure we have a water level sensor
  let waterSensor = await prisma.sensor.findFirst({
    where: { type: SensorType.WATER_LEVEL, isActive: true },
  });

  if (!waterSensor) {
    waterSensor = await prisma.sensor.create({
      data: {
        sensorId: 'WTR-SIM-999',
        name: 'Simulated Water Level Sensor Manggarai',
        type: SensorType.WATER_LEVEL,
        latitude: -6.22,
        longitude: 106.83,
        batteryLevel: 85,
        connectivity: SensorConnectivity.ONLINE,
        isActive: true,
      },
    });
    console.log(`✅ Created mock water level sensor: ${waterSensor.sensorId}`);
  } else {
    console.log(`✅ Using existing water level sensor: ${waterSensor.sensorId}`);
  }

  // 4. Run Sequential Ingestions
  const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

  // --- STEP 1: Sending Normal Water Level (3.0 cm) ---
  console.log('\n--- STEP 1: Sending Normal Water Level (3.0 cm) ---');
  console.log('👉 EXPECTED: Ingested successfully, status NORMAL (Green).');
  try {
    const res = await axios.post(API_URL, {
      sensorId: waterSensor.sensorId,
      waterLevel: 3.0,
      batteryLevel: 85,
      connectivity: 'ONLINE',
    });
    console.log('Response Status:', res.status);
    console.log('Ingest Result:', JSON.stringify(res.data.data));
  } catch (err: any) {
    console.error('Step 1 Ingest failed:', err.response?.data || err.message);
  }

  console.log('⏳ Sleeping 10 seconds to avoid spamming...');
  await sleep(10000);

  // --- STEP 2: Sending Waspada / Kuning Water Level (6.0 cm) ---
  console.log('\n--- STEP 2: Sending Waspada / Kuning Water Level (6.0 cm) ---');
  console.log('👉 EXPECTED: Status WARNING (Yellow) -> Automated FCM & Email Alert Broadcast!');
  try {
    const res = await axios.post(API_URL, {
      sensorId: waterSensor.sensorId,
      waterLevel: 6.0,
      batteryLevel: 85,
      connectivity: 'ONLINE',
    });
    console.log('Response Status:', res.status);
    console.log('Ingest Result:', JSON.stringify(res.data.data));
  } catch (err: any) {
    console.error('Step 2 Ingest failed:', err.response?.data || err.message);
  }

  console.log('⏳ Sleeping 10 seconds to avoid spamming...');
  await sleep(10000);

  // --- STEP 3: Sending Siaga / Orange Water Level (10.0 cm) ---
  console.log('\n--- STEP 3: Sending Siaga / Orange Water Level (10.0 cm) ---');
  console.log('👉 EXPECTED: Status ALERT (Orange) -> Automated FCM & Email Alert Broadcast!');
  try {
    const res = await axios.post(API_URL, {
      sensorId: waterSensor.sensorId,
      waterLevel: 10.0,
      batteryLevel: 84,
      connectivity: 'ONLINE',
    });
    console.log('Response Status:', res.status);
    console.log('Ingest Result:', JSON.stringify(res.data.data));
  } catch (err: any) {
    console.error('Step 3 Ingest failed:', err.response?.data || err.message);
  }

  console.log('⏳ Sleeping 10 seconds to avoid spamming...');
  await sleep(10000);

  // --- STEP 4: Sending Bahaya / Merah Water Level (15.0 cm) ---
  console.log('\n--- STEP 4: Sending Bahaya / Merah Water Level (15.0 cm) ---');
  console.log('👉 EXPECTED: Status DANGER (Red) -> Automated FCM & Email Alert Broadcast!');
  try {
    const res = await axios.post(API_URL, {
      sensorId: waterSensor.sensorId,
      waterLevel: 15.0,
      batteryLevel: 84,
      connectivity: 'ONLINE',
    });
    console.log('Response Status:', res.status);
    console.log('Ingest Result:', JSON.stringify(res.data.data));
  } catch (err: any) {
    console.error('Step 4 Ingest failed:', err.response?.data || err.message);
  }

  console.log('\n🏁 Simulation steps executed. Please check your backend terminal logs and frontend dashboard to verify FCM alerts!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
    await pool.end();
  });
