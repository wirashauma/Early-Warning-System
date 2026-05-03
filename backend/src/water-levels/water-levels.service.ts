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
    const limit = Number(query.limit) || 20;
    const skip = (page - 1) * limit;

    const [logs, total] = await this.prisma.$transaction([
      this.prisma.waterLevelLog.findMany({
        where: {
          sensorId: sensor.id,
          recordedAt: {
            gte: startDate,
            lte: endDate,
          },
        },
        orderBy: { recordedAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.waterLevelLog.count({
        where: {
          sensorId: sensor.id,
          recordedAt: {
            gte: startDate,
            lte: endDate,
          },
        },
      }),
    ]);

    const items = logs.map((item) => ({
      id: item.id,
      sensorId: sensor.sensorId,
      sensorName: sensor.name,
      waterLevel: item.waterLevel,
      unit: item.unit,
      status: item.status,
      latitude: sensor.latitude,
      longitude: sensor.longitude,
      recordedAt: item.recordedAt,
      interval: query.interval ?? 'hourly',
    }));

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
