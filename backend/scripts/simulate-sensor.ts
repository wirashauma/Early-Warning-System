import { PrismaClient, SensorType, SensorConnectivity } from '@prisma/client';
import axios from 'axios';

const prisma = new PrismaClient();
const API_URL = 'http://localhost:4101/api/iot/ingest';

async function main() {
  console.log('🚀 Starting Sensor Hardware Spoofing Simulation...');

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

  // --- RAINFALL STEP 1: Normal Level ---
  console.log('\n--- STEP 1: Sending Normal Rainfall (1.5 mm/hour) ---');
  try {
    const res = await axios.post(API_URL, {
      sensorId: rainSensor.sensorId,
      rainfall: 1.5,
      batteryLevel: 98,
      connectivity: 'ONLINE',
    });
    console.log('Response Status:', res.status);
    console.log('Ingest Result:', JSON.stringify(res.data.data));
  } catch (err: any) {
    console.error('Step 1 Ingest failed:', err.response?.data || err.message);
  }

  await sleep(2000);

  // --- RAINFALL STEP 2: Warning Threshold Trigger ---
  console.log('\n--- STEP 2: Sending Warning Threshold Rainfall (12.0 mm/hour) ---');
  console.log('👉 EXPECTED: Alert warning status + email trigger logged in console!');
  try {
    const res = await axios.post(API_URL, {
      sensorId: rainSensor.sensorId,
      rainfall: 12.0,
      batteryLevel: 97,
      connectivity: 'ONLINE',
    });
    console.log('Response Status:', res.status);
    console.log('Ingest Result:', JSON.stringify(res.data.data));
  } catch (err: any) {
    console.error('Step 2 Ingest failed:', err.response?.data || err.message);
  }

  await sleep(2000);

  // --- RAINFALL STEP 3: Repeated Warning / Anti-Spam Check ---
  console.log('\n--- STEP 3: Re-sending Warning Threshold Rainfall (13.5 mm/hour) within 1-Hour ---');
  console.log('👉 EXPECTED: Event ingested, but email skipped due to anti-spam rate limiting!');
  try {
    const res = await axios.post(API_URL, {
      sensorId: rainSensor.sensorId,
      rainfall: 13.5,
      batteryLevel: 97,
      connectivity: 'ONLINE',
    });
    console.log('Response Status:', res.status);
    console.log('Ingest Result:', JSON.stringify(res.data.data));
  } catch (err: any) {
    console.error('Step 3 Ingest failed:', err.response?.data || err.message);
  }

  await sleep(2000);

  // --- WATER LEVEL STEP 4: Critical Water Level ---
  console.log('\n--- STEP 4: Sending Critical Water Level (235.0 cm) ---');
  console.log('👉 EXPECTED: Danger alert status + email trigger logged for Water Level!');
  try {
    const res = await axios.post(API_URL, {
      sensorId: waterSensor.sensorId,
      waterLevel: 235.0,
      batteryLevel: 84,
      connectivity: 'ONLINE',
    });
    console.log('Response Status:', res.status);
    console.log('Ingest Result:', JSON.stringify(res.data.data));
  } catch (err: any) {
    console.error('Step 4 Ingest failed:', err.response?.data || err.message);
  }

  console.log('\n🏁 Simulation steps executed. Please check your backend terminal logs to verify alerts and email debouncing.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
