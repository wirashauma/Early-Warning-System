import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { SensorType } from '@prisma/client';
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
export class WaterLevelsService {
  constructor(private readonly prisma: PrismaService) {}

  async getCurrent() {
    const sensors = await this.prisma.sensor.findMany({
      where: { type: SensorType.WATER_LEVEL, isActive: true },
      orderBy: { sensorId: 'asc' },
    });

    const currentData = await Promise.all(
      sensors.map(async (sensor) => {
        const latest = await this.prisma.waterLevelLog.findFirst({
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
          waterLevel: latest.waterLevel,
          unit: latest.unit,
          status: latest.status,
          latitude: sensor.latitude,
          longitude: sensor.longitude,
          recordedAt: latest.recordedAt,
        };
      }),
    );

    return currentData.filter((item) => item !== null);
  }

  async getLatestBySensor(sensorId: string) {
    const sensor = await this.prisma.sensor.findFirst({
      where: { sensorId, type: SensorType.WATER_LEVEL, isActive: true },
    });

    if (!sensor) {
      throw new NotFoundException('Sensor tidak ditemukan.');
    }

    const latest = await this.prisma.waterLevelLog.findFirst({
      where: { sensorId: sensor.id },
      orderBy: { recordedAt: 'desc' },
    });

    if (!latest) {
      throw new NotFoundException(
        'Data water level belum tersedia untuk sensor ini.',
      );
    }

    return {
      id: latest.id,
      sensorId: sensor.sensorId,
      sensorName: sensor.name,
      waterLevel: latest.waterLevel,
      unit: latest.unit,
      status: latest.status,
      latitude: sensor.latitude,
      longitude: sensor.longitude,
      recordedAt: latest.recordedAt,
    };
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
        type: SensorType.WATER_LEVEL,
        isActive: true,
      },
    });

    if (!sensor) {
      throw new NotFoundException('Sensor tidak ditemukan.');
    }

    const page = Number(query.page) || 1;
    const limit = Number(query.limit) || 2000;
    const skip = (page - 1) * limit;

    // 1. Fetch threshold dynamically to evaluate statuses based on aggregated averages
    const threshold = await this.prisma.threshold.findUnique({
      where: { type: 'water_level' },
    });
    const warningMin = threshold?.warningMin ?? 151;
    const dangerMin = threshold?.dangerMin ?? 221;
    const alertMin = threshold?.alertMin ?? 180;

    // 2. Query aggregated logs using DATE_TRUNC minute
    const aggregatedLogs = await this.prisma.$queryRaw<
      Array<{
        minute: Date;
        waterLevel: number;
        minWaterLevel: number;
        maxWaterLevel: number;
      }>
    >`
      SELECT 
        DATE_TRUNC('minute', recorded_at) as "minute",
        ROUND(AVG(water_level)::numeric, 2)::float as "waterLevel",
        ROUND(MIN(water_level)::numeric, 2)::float as "minWaterLevel",
        ROUND(MAX(water_level)::numeric, 2)::float as "maxWaterLevel"
      FROM water_level_logs
      WHERE sensor_id = ${sensor.id} 
        AND recorded_at BETWEEN ${startDate} AND ${endDate}
      GROUP BY "minute"
      ORDER BY "minute" ASC
    `;

    const total = aggregatedLogs.length;
    const slicedLogs = aggregatedLogs.slice(skip, skip + limit);

    const items = slicedLogs.map((item) => {
      const avgLevel = item.waterLevel;
      const status =
        avgLevel >= dangerMin ? 'DANGER' :
        avgLevel >= alertMin ? 'ALERT' :
        avgLevel >= warningMin ? 'WARNING' : 'NORMAL';

      return {
        id: `${sensor.sensorId}-wl-agg-${item.minute.getTime()}`,
        sensorId: sensor.sensorId,
        sensorName: sensor.name,
        waterLevel: avgLevel,
        minWaterLevel: item.minWaterLevel,
        maxWaterLevel: item.maxWaterLevel,
        unit: 'cm',
        status,
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
}
