import 'dotenv/config';
import { PrismaPg } from '@prisma/adapter-pg';
import {
  EmergencyCategory,
  PrismaClient,
  RainfallIntensity,
  SensorConnectivity,
  SensorType,
  UserRole,
  WaterLevelStatus,
} from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { Pool } from 'pg';

const connectionString =
  process.env.DATABASE_URL ??
  'postgresql://postgres:postgres@localhost:5432/postgres';

const pool = new Pool({ connectionString });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function upsertUsers() {
  const users = [
    {
      email: 'admin@ews.com',
      name: 'Admin EWS',
      password: 'Admin123!',
      role: UserRole.ADMIN,
      institution: 'BPBD Kota',
      phone: '6281110000001',
    },
    {
      email: 'admin2@ews.com',
      name: 'Admin Operasional EWS',
      password: 'AdminOps123!',
      role: UserRole.ADMIN,
      institution: 'BPBD Kota',
      phone: '6281110000002',
    },
    {
      email: 'user1@ews.com',
      name: 'User Warga 1',
      password: 'User12345!',
      role: UserRole.USER,
      institution: 'Warga Padang Barat',
      phone: '6281110000003',
    },
    {
      email: 'user2@ews.com',
      name: 'User Warga 2',
      password: 'User12345!',
      role: UserRole.USER,
      institution: 'Warga Padang Utara',
      phone: '6281110000004',
    },
    {
      email: 'user3@ews.com',
      name: 'User Warga 3',
      password: 'User12345!',
      role: UserRole.USER,
      institution: 'Warga Nanggalo',
      phone: '6281110000007',
    },
  ];

  for (const user of users) {
    const hashedPassword = await bcrypt.hash(user.password, 10);
    await prisma.user.upsert({
      where: { email: user.email },
      create: {
        email: user.email,
        name: user.name,
        password: hashedPassword,
        role: user.role,
        institution: user.institution,
        phone: user.phone,
        isActive: true,
      },
      update: {
        name: user.name,
        password: hashedPassword,
        role: user.role,
        institution: user.institution,
        phone: user.phone,
        isActive: true,
      },
    });
  }
}

async function upsertSensors() {
  // Bersihkan data lama agar hanya berisi 3 sensor baru
  await prisma.waterLevelLog.deleteMany({});
  await prisma.rainfallLog.deleteMany({});
  await prisma.flowRateLog.deleteMany({});
  await prisma.sensor.deleteMany({});

  const sensors = [
    {
      sensorId: 'EWS-US-001',
      name: 'Node Kost Orange',
      type: SensorType.WATER_LEVEL,
      latitude: -0.95,
      longitude: 100.37,
      batteryLevel: 100,
      connectivity: SensorConnectivity.ONLINE,
    },
    {
      sensorId: 'EWS-RF-002',
      name: 'Rain Gauge Kost Orange',
      type: SensorType.RAINFALL,
      latitude: -0.95,
      longitude: 100.37,
      batteryLevel: 100,
      connectivity: SensorConnectivity.ONLINE,
    },
    {
      sensorId: 'EWS-FL-001',
      name: 'Water Flow Kost Orange',
      type: SensorType.FLOW_RATE,
      latitude: -0.95,
      longitude: 100.37,
      batteryLevel: 100,
      connectivity: SensorConnectivity.ONLINE,
    },
  ];

  for (const sensor of sensors) {
    await prisma.sensor.upsert({
      where: { sensorId: sensor.sensorId },
      create: {
        ...sensor,
        isActive: true,
        installedAt: new Date(),
        lastActiveAt: new Date(),
      },
      update: {
        ...sensor,
        isActive: true,
        lastActiveAt: new Date(),
      },
    });
  }
}

async function upsertThresholds() {
  await prisma.threshold.upsert({
    where: { type: 'water_level' },
    create: {
      type: 'water_level',
      normalMin: 0,
      normalMax: 150,
      warningMin: 151,
      warningMax: 220,
      dangerMin: 221,
      dangerMax: null,
    },
    update: {
      normalMin: 0,
      normalMax: 150,
      warningMin: 151,
      warningMax: 220,
      dangerMin: 221,
      dangerMax: null,
    },
  });

  await prisma.threshold.upsert({
    where: { type: 'rainfall' },
    create: {
      type: 'rainfall',
      normalMin: 0,
      normalMax: 5,
      warningMin: 5.1,
      warningMax: 20,
      dangerMin: 20.1,
      dangerMax: null,
    },
    update: {
      normalMin: 0,
      normalMax: 5,
      warningMin: 5.1,
      warningMax: 20,
      dangerMin: 20.1,
      dangerMax: null,
    },
  });
}

async function upsertEmergencyContacts() {
  const contacts = [
    {
      name: 'BPBD Kota Padang',
      phone: '117',
      category: EmergencyCategory.BPBD,
    },
    {
      name: 'Basarnas',
      phone: '115',
      category: EmergencyCategory.SAR,
    },
    {
      name: 'Ambulans',
      phone: '118',
      category: EmergencyCategory.AMBULANCE,
    },
    {
      name: 'Polisi',
      phone: '110',
      category: EmergencyCategory.POLICE,
    },
    {
      name: 'RS Umum Daerah',
      phone: '119',
      category: EmergencyCategory.HOSPITAL,
    },
  ];

  for (const contact of contacts) {
    const existing = await prisma.emergencyContact.findFirst({
      where: {
        name: contact.name,
        phone: contact.phone,
      },
    });

    if (existing) {
      await prisma.emergencyContact.update({
        where: { id: existing.id },
        data: {
          category: contact.category,
          isActive: true,
        },
      });
    } else {
      await prisma.emergencyContact.create({
        data: {
          ...contact,
          isActive: true,
        },
      });
    }
  }
}

async function seedSensorLogs() {
  const waterSensors = await prisma.sensor.findMany({
    where: {
      isActive: true,
      type: SensorType.WATER_LEVEL,
    },
    select: {
      id: true,
      sensorId: true,
    },
  });

  const rainfallSensors = await prisma.sensor.findMany({
    where: {
      isActive: true,
      type: SensorType.RAINFALL,
    },
    select: {
      id: true,
      sensorId: true,
    },
  });

  const flowSensors = await prisma.sensor.findMany({
    where: {
      isActive: true,
      type: SensorType.FLOW_RATE,
    },
    select: {
      id: true,
      sensorId: true,
    },
  });

  if (waterSensors.length > 0) {
    await prisma.waterLevelLog.deleteMany({
      where: {
        sensorId: {
          in: waterSensors.map((sensor) => sensor.id),
        },
      },
    });
  }

  if (rainfallSensors.length > 0) {
    await prisma.rainfallLog.deleteMany({
      where: {
        sensorId: {
          in: rainfallSensors.map((sensor) => sensor.id),
        },
      },
    });
  }

  if (flowSensors.length > 0) {
    await prisma.flowRateLog.deleteMany({
      where: {
        sensorId: {
          in: flowSensors.map((sensor) => sensor.id),
        },
      },
    });
  }

  for (const [sensorIndex, sensor] of waterSensors.entries()) {
    const rows = Array.from({ length: 24 }, (_, idx) => {
      // Menyesuaikan simulasi pembacaan agar mendekati tangki setinggi 17 cm (TANK_HEIGHT_CM)
      // Nilai waterLevel di database kita simpan dalam cm dari dasar tangki
      const waterLevel = 12.0 - (idx % 4) * 1.5; // Mengisi antara 7.5 cm s/d 12.0 cm
      const status =
        waterLevel >= 15.0
          ? WaterLevelStatus.DANGER
          : waterLevel >= 12.0
            ? WaterLevelStatus.WARNING
            : WaterLevelStatus.NORMAL;

      return {
        sensorId: sensor.id,
        waterLevel,
        status,
        unit: 'cm',
        recordedAt: new Date(Date.now() - (24 - idx) * 60 * 60 * 1000),
      };
    });

    await prisma.waterLevelLog.createMany({ data: rows });
  }

  for (const [sensorIndex, sensor] of rainfallSensors.entries()) {
    const rows = Array.from({ length: 24 }, (_, idx) => {
      const rainfall = 1.2 + sensorIndex * 2 + (idx % 4) * 0.8;
      const intensity =
        rainfall > 20
          ? RainfallIntensity.HEAVY
          : rainfall > 5
            ? RainfallIntensity.MODERATE
            : RainfallIntensity.LIGHT;

      return {
        sensorId: sensor.id,
        rainfall,
        intensity,
        unit: 'mm/hour',
        recordedAt: new Date(Date.now() - (24 - idx) * 60 * 60 * 1000),
      };
    });

    await prisma.rainfallLog.createMany({ data: rows });
  }

  for (const [sensorIndex, sensor] of flowSensors.entries()) {
    const rows = Array.from({ length: 24 }, (_, idx) => {
      const flowRate = 8.5 + sensorIndex * 4 + (idx % 5) * 1.2;
      return {
        sensorId: sensor.id,
        flowRate,
        unit: 'L/min',
        recordedAt: new Date(Date.now() - (24 - idx) * 60 * 60 * 1000),
      };
    });

    await prisma.flowRateLog.createMany({ data: rows });
  }
}

async function main() {
  await upsertUsers();
  await upsertSensors();
  await upsertThresholds();
  await upsertEmergencyContacts();

  console.log(
    'Seed selesai: users, sensors, thresholds, dan emergency contacts berhasil dibuat (data logs dibiarkan kosong).',
  );
  console.log('Akun cepat login:');
  console.log('- admin@ews.com / Admin123!');
  console.log('- admin2@ews.com / AdminOps123!');
  console.log('- user1@ews.com / User12345!');
  console.log('- user2@ews.com / User12345!');
  console.log('- user3@ews.com / User12345!');
}

void main()
  .catch((error) => {
    console.error('Seed gagal:', error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
    await pool.end();
  });
