import { Injectable } from '@nestjs/common';
import { SensorConnectivity, SensorType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

interface UpsertSensorPayload {
  sensorId: string;
  name: string;
  type?: SensorType;
  latitude: number;
  longitude: number;
  batteryLevel?: number | null;
  connectivity?: SensorConnectivity;
}

@Injectable()
export class SensorsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(page = 1, limit = 20) {
    const skip = (page - 1) * limit;

    const [items, total] = await this.prisma.$transaction([
      this.prisma.sensor.findMany({
        where: { isActive: true },
        orderBy: { sensorId: 'asc' },
        skip,
        take: limit,
        select: {
          id: true,
          sensorId: true,
          name: true,
          type: true,
          latitude: true,
          longitude: true,
          batteryLevel: true,
          connectivity: true,
          lastActiveAt: true,
          installedAt: true,
        },
      }),
      this.prisma.sensor.count({ where: { isActive: true } }),
    ]);

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

  async create(payload: UpsertSensorPayload) {
    return this.prisma.sensor.create({
      data: {
        sensorId: payload.sensorId,
        name: payload.name,
        type: payload.type ?? SensorType.WATER_LEVEL,
        latitude: payload.latitude,
        longitude: payload.longitude,
        batteryLevel: payload.batteryLevel ?? null,
        connectivity: payload.connectivity ?? SensorConnectivity.ONLINE,
        isActive: true,
      },
      select: {
        id: true,
        sensorId: true,
        name: true,
        type: true,
        latitude: true,
        longitude: true,
        batteryLevel: true,
        connectivity: true,
        lastActiveAt: true,
        installedAt: true,
      },
    });
  }

  async update(id: string, payload: Partial<UpsertSensorPayload>) {
    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id);
    const where = isUuid ? { id } : { sensorId: id };

    return this.prisma.sensor.update({
      where,
      data: {
        sensorId: payload.sensorId,
        name: payload.name,
        type: payload.type,
        latitude: payload.latitude,
        longitude: payload.longitude,
        batteryLevel: payload.batteryLevel,
        connectivity: payload.connectivity,
        lastActiveAt: new Date(),
      },
      select: {
        id: true,
        sensorId: true,
        name: true,
        type: true,
        latitude: true,
        longitude: true,
        batteryLevel: true,
        connectivity: true,
        lastActiveAt: true,
        installedAt: true,
      },
    });
  }

  async remove(id: string) {
    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id);
    const where = isUuid ? { id } : { sensorId: id };

    await this.prisma.sensor.update({
      where,
      data: { isActive: false },
    });

    return { id };
  }
}
