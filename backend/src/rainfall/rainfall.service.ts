import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { SensorType, RainfallIntensity } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

interface HistoryQuery {
  sensorId?: string;
  startDate?: string;
  endDate?: string;
  interval?: 'hourly' | 'daily' | 'weekly';
  page?: string;
  limit?: string;
}

@Injectable()
export class RainfallService {
  constructor(private readonly prisma: PrismaService) {}

  async getCurrent() {
    const sensors = await this.prisma.sensor.findMany({
      where: { type: SensorType.RAINFALL, isActive: true },
      orderBy: { sensorId: 'asc' },
    });

    const currentData = await Promise.all(
      sensors.map(async (sensor) => {
        const latest = await this.prisma.rainfallLog.findFirst({
          where: { sensorId: sensor.id },
          orderBy: { recordedAt: 'desc' },
        });

        if (!latest) {
          return null;
        }

        return {
          id: latest.id,
          sensorId: sensor.sensorId,
          sensorName: sensor.name,
          rainfall: latest.rainfall,
          unit: latest.unit,
          intensity: latest.intensity,
          latitude: sensor.latitude,
          longitude: sensor.longitude,
          recordedAt: latest.recordedAt,
        };
      }),
    );

    return currentData.filter((item) => item !== null);
  }

  async getHistory(query: HistoryQuery) {
    if (!query.sensorId || !query.startDate || !query.endDate) {
      throw new BadRequestException(
        'sensorId, startDate, dan endDate wajib diisi.',
      );
    }

    const startDate = new Date(query.startDate);
    const endDate = new Date(query.endDate);

    if (Number.isNaN(startDate.getTime()) || Number.isNaN(endDate.getTime())) {
      throw new BadRequestException(
        'Format tanggal tidak valid. Gunakan ISO 8601.',
      );
    }

    const sensor = await this.prisma.sensor.findFirst({
      where: {
        sensorId: query.sensorId,
        type: SensorType.RAINFALL,
        isActive: true,
      },
    });

    if (!sensor) {
      throw new NotFoundException('Sensor tidak ditemukan.');
    }

    const page = Number(query.page) || 1;
    const limit = Number(query.limit) || 2000;
    const skip = (page - 1) * limit;

    // 1. Fetch threshold dynamically to evaluate intensity
    const threshold = await this.prisma.threshold.findUnique({
      where: { type: 'rainfall' },
    });
    const warningMin = threshold?.warningMin ?? 5.1;
    const dangerMin = threshold?.dangerMin ?? 20.1;

    // 2. Query aggregated logs using DATE_TRUNC minute
    const aggregatedLogs = await this.prisma.$queryRaw<
      Array<{
        minute: Date;
        rainfall: number;
        minRainfall: number;
        maxRainfall: number;
      }>
    >`
      SELECT 
        DATE_TRUNC('minute', recorded_at) as "minute",
        ROUND(AVG(rainfall)::numeric, 2)::float as "rainfall",
        ROUND(MIN(rainfall)::numeric, 2)::float as "minRainfall",
        ROUND(MAX(rainfall)::numeric, 2)::float as "maxRainfall"
      FROM rainfall_logs
      WHERE sensor_id = ${sensor.id} 
        AND recorded_at BETWEEN ${startDate} AND ${endDate}
      GROUP BY "minute"
      ORDER BY "minute" ASC
    `;

    const total = aggregatedLogs.length;
    const slicedLogs = aggregatedLogs.slice(skip, skip + limit);

    const items = slicedLogs.map((item) => {
      const avgRain = item.rainfall;
      const intensity: RainfallIntensity =
        avgRain >= dangerMin ? RainfallIntensity.HEAVY :
        avgRain >= warningMin ? RainfallIntensity.MODERATE : RainfallIntensity.LIGHT;

      return {
        id: `${sensor.sensorId}-rf-agg-${item.minute.getTime()}`,
        sensorId: sensor.sensorId,
        sensorName: sensor.name,
        rainfall: avgRain,
        minRainfall: item.minRainfall,
        maxRainfall: item.maxRainfall,
        unit: 'mm/hour',
        intensity,
        latitude: sensor.latitude,
        longitude: sensor.longitude,
        recordedAt: item.minute,
        interval: query.interval ?? 'minute',
      };
    });

    return {
      items,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getKentenRainfall() {
    let sensor = await this.prisma.sensor.findUnique({
      where: { sensorId: 'EWS-RF-KENTEN' },
    });

    if (!sensor) {
      sensor = await this.prisma.sensor.create({
        data: {
          sensorId: 'EWS-RF-KENTEN',
          name: 'Rain Gauge Kenten',
          type: SensorType.RAINFALL,
          latitude: -2.9348,
          longitude: 104.757,
          batteryLevel: 95,
          connectivity: 'ONLINE',
          isActive: true,
          installedAt: new Date(),
          lastActiveAt: new Date(),
        },
      });
    }

    const existingLogsCount = await this.prisma.rainfallLog.count({
      where: { sensorId: sensor.id },
    });

    if (existingLogsCount === 0) {
      const logs: any[] = [];
      const baseRainfalls = [280, 240, 220, 150, 110, 60, 40, 50, 90, 160, 260, 310];
      const currentYear = new Date().getFullYear();

      for (let month = 0; month < 12; month++) {
        const totalRain = baseRainfalls[month];
        const numLogs = 8;
        const avgRain = totalRain / numLogs;
        for (let i = 0; i < numLogs; i++) {
          const rainValue = parseFloat(
            (avgRain * (0.6 + Math.random() * 0.8)).toFixed(1),
          );
          const day = Math.floor(Math.random() * 27) + 1;
          const hour = Math.floor(Math.random() * 24);
          const recordedAt = new Date(currentYear, month, day, hour, 0, 0);

          let intensity: RainfallIntensity = RainfallIntensity.LIGHT;
          if (rainValue > 20) {
            intensity = RainfallIntensity.HEAVY;
          } else if (rainValue > 5) {
            intensity = RainfallIntensity.MODERATE;
          }

          logs.push({
            sensorId: sensor.id,
            rainfall: rainValue,
            intensity,
            unit: 'mm/hour',
            recordedAt,
          });
        }
      }
      await this.prisma.rainfallLog.createMany({ data: logs });
    }

    const logs = await this.prisma.rainfallLog.findMany({
      where: { sensorId: sensor.id },
      orderBy: { recordedAt: 'asc' },
    });

    const threshold = await this.prisma.threshold.findUnique({
      where: { type: 'rainfall' },
    });

    return {
      sensor: {
        sensorId: sensor.sensorId,
        name: sensor.name,
        latitude: sensor.latitude,
        longitude: sensor.longitude,
        batteryLevel: sensor.batteryLevel,
        connectivity: sensor.connectivity,
      },
      threshold: threshold ? threshold.warningMax ?? 150 : 150,
      logs: logs.map((log) => ({
        id: log.id,
        rainfall: log.rainfall,
        intensity: log.intensity,
        unit: log.unit,
        recordedAt: log.recordedAt,
      })),
    };
  }
}
