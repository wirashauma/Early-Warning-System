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
export class FlowRateService {
  constructor(private readonly prisma: PrismaService) {}

  async getCurrent() {
    const sensors = await this.prisma.sensor.findMany({
      where: { type: SensorType.FLOW_RATE, isActive: true },
      orderBy: { sensorId: 'asc' },
    });

    const currentData = await Promise.all(
      sensors.map(async (sensor) => {
        const latest = await this.prisma.flowRateLog.findFirst({
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
          flowRate: latest.flowRate,
          unit: latest.unit,
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
        type: SensorType.FLOW_RATE,
        isActive: true,
      },
    });

    if (!sensor) {
      throw new NotFoundException('Sensor tidak ditemukan.');
    }

    const page = Number(query.page) || 1;
    const limit = Number(query.limit) || 20;
    const skip = (page - 1) * limit;

    // 2. Query aggregated logs using DATE_TRUNC hourly
    const aggregatedLogs = await this.prisma.$queryRaw<
      Array<{
        hour: Date;
        flowRate: number;
        minFlowRate: number;
        maxFlowRate: number;
      }>
    >`
      SELECT 
        DATE_TRUNC('hour', recorded_at) as "hour",
        ROUND(AVG(flow_rate)::numeric, 2)::float as "flowRate",
        ROUND(MIN(flow_rate)::numeric, 2)::float as "minFlowRate",
        ROUND(MAX(flow_rate)::numeric, 2)::float as "maxFlowRate"
      FROM flow_rate_logs
      WHERE sensor_id = ${sensor.id} 
        AND recorded_at BETWEEN ${startDate} AND ${endDate}
      GROUP BY "hour"
      ORDER BY "hour" ASC
    `;

    const total = aggregatedLogs.length;
    const slicedLogs = aggregatedLogs.slice(skip, skip + limit);

    const items = slicedLogs.map((item) => {
      return {
        id: `${sensor.sensorId}-fr-agg-${item.hour.getTime()}`,
        sensorId: sensor.sensorId,
        sensorName: sensor.name,
        flowRate: item.flowRate,
        minFlowRate: item.minFlowRate,
        maxFlowRate: item.maxFlowRate,
        unit: 'l/min',
        latitude: sensor.latitude,
        longitude: sensor.longitude,
        recordedAt: item.hour,
        interval: query.interval ?? 'hourly',
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
