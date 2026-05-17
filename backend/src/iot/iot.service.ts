import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  RainfallIntensity,
  SensorConnectivity,
  SensorType,
  WaterLevelStatus,
  type Threshold,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { IngestPayload } from './dto/ingest.dto';

export interface IngestResult {
  recordedAt: string;
  water?: {
    sensorId: string;
    waterLevel: number;
    status: WaterLevelStatus;
  };
  rainfall?: {
    sensorId: string;
    rainfall: number;
    intensity: RainfallIntensity;
  };
  flowRate?: {
    sensorId: string;
    flowRate: number;
    unit: string;
  };
}

@Injectable()
export class IotService {
  constructor(private readonly prisma: PrismaService) {}

  async ingest(payload: IngestPayload): Promise<IngestResult> {
    const hasValue = (value: number | null | undefined) => value !== undefined && value !== null;

    const hasWater = hasValue(payload.waterLevel);
    const hasRain = hasValue(payload.rainfall);
    const hasFlow = hasValue(payload.flowRate);

    if (!hasWater && !hasRain && !hasFlow) {
      throw new BadRequestException(
        'waterLevel, rainfall, atau flowRate wajib diisi.',
      );
    }

    const waterSensorId = payload.waterSensorId ?? payload.sensorId;
    const rainSensorId = payload.rainSensorId ?? payload.sensorId;
    const flowSensorId = payload.flowSensorId ?? payload.sensorId;

    if (hasWater && !waterSensorId) {
      throw new BadRequestException('waterSensorId atau sensorId wajib diisi.');
    }

    if (hasRain && !rainSensorId) {
      throw new BadRequestException('rainSensorId atau sensorId wajib diisi.');
    }

    if (hasFlow && !flowSensorId) {
      throw new BadRequestException('flowSensorId atau sensorId wajib diisi.');
    }

    const recordedAt = payload.recordedAt
      ? new Date(payload.recordedAt)
      : new Date();

    if (Number.isNaN(recordedAt.getTime())) {
      throw new BadRequestException('recordedAt tidak valid.');
    }

    const thresholdRows = await this.prisma.threshold.findMany({
      where: { type: { in: ['water_level', 'rainfall'] } },
    });

    const waterThreshold =
      thresholdRows.find((row) => row.type === 'water_level') ?? null;
    const rainfallThreshold =
      thresholdRows.find((row) => row.type === 'rainfall') ?? null;

    const result: IngestResult = {
      recordedAt: recordedAt.toISOString(),
    };

    if (hasWater && waterSensorId) {
      const sensor = await this.prisma.sensor.findFirst({
        where: {
          sensorId: waterSensorId,
          type: SensorType.WATER_LEVEL,
          isActive: true,
        },
      });

      if (!sensor) {
        throw new NotFoundException('Sensor water level tidak ditemukan.');
      }

      const waterStatus = this.resolveWaterStatus(
        payload.waterLevel as number,
        waterThreshold,
      );

      await this.prisma.waterLevelLog.create({
        data: {
          sensorId: sensor.id,
          waterLevel: payload.waterLevel as number,
          unit: 'cm',
          status: waterStatus,
          recordedAt,
        },
      });

      await this.updateSensorStatus(sensor.id, recordedAt, payload);

      result.water = {
        sensorId: sensor.sensorId,
        waterLevel: payload.waterLevel as number,
        status: waterStatus,
      };
    }

    if (hasRain && rainSensorId) {
      const sensor = await this.prisma.sensor.findFirst({
        where: {
          sensorId: rainSensorId,
          type: SensorType.RAINFALL,
          isActive: true,
        },
      });

      if (!sensor) {
        throw new NotFoundException('Sensor rainfall tidak ditemukan.');
      }

      const intensity = this.resolveRainIntensity(
        payload.rainfall as number,
        rainfallThreshold,
      );

      await this.prisma.rainfallLog.create({
        data: {
          sensorId: sensor.id,
          rainfall: payload.rainfall as number,
          unit: 'mm/hour',
          intensity,
          recordedAt,
        },
      });

      await this.updateSensorStatus(sensor.id, recordedAt, payload);

      result.rainfall = {
        sensorId: sensor.sensorId,
        rainfall: payload.rainfall as number,
        intensity,
      };
    }

    if (hasFlow && flowSensorId) {
      const sensor = await this.prisma.sensor.findFirst({
        where: {
          sensorId: flowSensorId,
          type: SensorType.FLOW_RATE,
          isActive: true,
        },
      });

      if (!sensor) {
        throw new NotFoundException('Sensor flow rate tidak ditemukan.');
      }

      await this.prisma.flowRateLog.create({
        data: {
          sensorId: sensor.id,
          flowRate: payload.flowRate as number,
          unit: 'l/min',
          recordedAt,
        },
      });

      await this.updateSensorStatus(sensor.id, recordedAt, payload);

      result.flowRate = {
        sensorId: sensor.sensorId,
        flowRate: payload.flowRate as number,
        unit: 'l/min',
      };
    }

    return result;
  }

  private resolveWaterStatus(
    level: number,
    threshold: Threshold | null,
  ): WaterLevelStatus {
    const warningMin = threshold?.warningMin ?? 151;
    const dangerMin = threshold?.dangerMin ?? 221;

    if (level >= dangerMin) {
      return WaterLevelStatus.DANGER;
    }

    if (level >= warningMin) {
      return WaterLevelStatus.WARNING;
    }

    return WaterLevelStatus.NORMAL;
  }

  private resolveRainIntensity(
    rainfall: number,
    threshold: Threshold | null,
  ): RainfallIntensity {
    const moderateMin = threshold?.warningMin ?? 5;
    const heavyMin = threshold?.dangerMin ?? 20;

    if (rainfall >= heavyMin) {
      return RainfallIntensity.HEAVY;
    }

    if (rainfall >= moderateMin) {
      return RainfallIntensity.MODERATE;
    }

    return RainfallIntensity.LIGHT;
  }

  private async updateSensorStatus(
    sensorId: string,
    recordedAt: Date,
    payload: IngestPayload,
  ) {
    const data: {
      lastActiveAt: Date;
      connectivity: SensorConnectivity;
      batteryLevel?: number | null;
    } = {
      lastActiveAt: recordedAt,
      connectivity: payload.connectivity ?? SensorConnectivity.ONLINE,
    };

    if (payload.batteryLevel !== undefined) {
      data.batteryLevel = Math.round(payload.batteryLevel);
    }

    await this.prisma.sensor.update({
      where: { id: sensorId },
      data,
    });
  }
}
