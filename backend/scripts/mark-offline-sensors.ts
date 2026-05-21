import * as dotenv from 'dotenv';
import { PrismaClient, SensorConnectivity } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';

dotenv.config();

const SENSOR_OFFLINE_LIMIT_MS = 5 * 60 * 1000; // 5 minutes

async function markOfflineSensors() {
  const connectionString = process.env.DATABASE_URL;

  if (!connectionString) {
    console.error('DATABASE_URL not found in environment variables');
    process.exit(1);
  }

  const pool = new Pool({ connectionString });
  const adapter = new PrismaPg(pool);
  const prisma = new PrismaClient({ adapter });

  console.log('--- EWS Sensor Connectivity Sync ---');
  console.log(`Current Time: ${new Date().toISOString()}`);

  try {
    const offlineThreshold = new Date(Date.now() - SENSOR_OFFLINE_LIMIT_MS);

    // Find sensors to be updated for logging purposes
    const sensorsToMarkOffline = await prisma.sensor.findMany({
      where: {
        isActive: true,
        connectivity: SensorConnectivity.ONLINE,
        OR: [
          { lastActiveAt: { lt: offlineThreshold } },
          { lastActiveAt: null },
        ],
      },
      select: {
        id: true,
        sensorId: true,
        name: true,
        type: true,
        lastActiveAt: true,
      },
    });

    if (sensorsToMarkOffline.length === 0) {
      console.log('✅ All sensors are healthy and online. No action needed.');
      return;
    }

    console.log(`⚠️ Found ${sensorsToMarkOffline.length} inactive sensor(s) to mark OFFLINE:`);
    for (const sensor of sensorsToMarkOffline) {
      const lastActive = sensor.lastActiveAt ? sensor.lastActiveAt.toISOString() : 'Never';
      console.log(` - [${sensor.type}] ${sensor.name} (${sensor.sensorId}) | Last Active: ${lastActive}`);
    }

    // Perform batch update inside transaction for safety
    const updateResult = await prisma.sensor.updateMany({
      where: {
        id: { in: sensorsToMarkOffline.map(s => s.id) },
      },
      data: {
        connectivity: SensorConnectivity.OFFLINE,
      },
    });

    console.log(`✅ Successfully updated ${updateResult.count} sensor(s) status to OFFLINE.`);

  } catch (error: any) {
    console.error('❌ Error executing sensor connectivity sync:', error.message || error);
    process.exitCode = 1;
  } finally {
    await prisma.$disconnect();
    await pool.end();
    console.log('--- Sync Completed ---');
  }
}

markOfflineSensors();
