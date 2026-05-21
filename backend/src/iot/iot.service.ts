import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  AlertSeverity,
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

    // 1. Fetch threshold rules to evaluate incoming values
    const thresholdRows = await this.prisma.threshold.findMany();
    const waterThreshold = thresholdRows.find((row) => row.type === 'water_level') ?? null;
    const rainfallThreshold = thresholdRows.find((row) => row.type === 'rainfall') ?? null;
    const flowThreshold = thresholdRows.find((row) => row.type === 'flow_rate') ?? null;

    // 2. Perform all database writes and checks within a transaction to ensure atomic execution
    const result = await this.prisma.$transaction(async (tx) => {
      const resultData: IngestResult = {
        recordedAt: recordedAt.toISOString(),
      };

      // Find an admin user to act as system sender if an alert is generated
      const adminUser = await tx.user.findFirst({
        where: { isActive: true, role: 'SUPER_ADMIN' },
        orderBy: { createdAt: 'asc' },
      }) ?? await tx.user.findFirst({
        where: { isActive: true },
        orderBy: { createdAt: 'asc' },
      });
      const sentById = adminUser?.id ?? null;

      // Handle Water Level Reading
      if (hasWater && waterSensorId) {
        const sensor = await tx.sensor.findFirst({
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

        // Insert log
        await tx.waterLevelLog.create({
          data: {
            sensorId: sensor.id,
            waterLevel: payload.waterLevel as number,
            unit: 'cm',
            status: waterStatus,
            recordedAt,
          },
        });

        // Update sensor connectivity metadata
        const updateData: {
          lastActiveAt: Date;
          connectivity: SensorConnectivity;
          batteryLevel?: number;
        } = {
          lastActiveAt: recordedAt,
          connectivity: payload.connectivity ?? SensorConnectivity.ONLINE,
        };
        if (payload.batteryLevel !== undefined) {
          updateData.batteryLevel = Math.round(payload.batteryLevel);
        }
        await tx.sensor.update({
          where: { id: sensor.id },
          data: updateData,
        });

        resultData.water = {
          sensorId: sensor.sensorId,
          waterLevel: payload.waterLevel as number,
          status: waterStatus,
        };

        // Automated alerts: Trigger alert if status is DANGER
        const dangerMin = waterThreshold?.dangerMin ?? 221;
        if (waterStatus === WaterLevelStatus.DANGER || (payload.waterLevel as number) >= dangerMin) {
          // 15-minute throttle check to prevent spamming
          const fifteenMinutesAgo = new Date(Date.now() - 15 * 60 * 1000);
          const existingAlert = await tx.alert.findFirst({
            where: {
              severity: AlertSeverity.DANGER,
              createdAt: { gte: fifteenMinutesAgo },
              OR: [
                { title: { contains: sensor.sensorId } },
                { message: { contains: sensor.sensorId } },
                { targetArea: sensor.name }
              ]
            }
          });

          if (!existingAlert) {
            await tx.alert.create({
              data: {
                title: `CRITICAL FLOOD WARNING (${sensor.sensorId})`,
                message: `CRITICAL ALERT: Sensor ${sensor.name} has detected water levels reaching ${payload.waterLevel} cm, exceeding the danger threshold of ${dangerMin} cm. Evacuation protocols should be considered immediately.`,
                severity: AlertSeverity.DANGER,
                channels: ['PUSH', 'EMAIL'],
                targetArea: sensor.name,
                sentBy: sentById,
              }
            });
          }
        }
      }

      // Handle Rainfall Reading
      if (hasRain && rainSensorId) {
        const sensor = await tx.sensor.findFirst({
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

        // Insert log
        await tx.rainfallLog.create({
          data: {
            sensorId: sensor.id,
            rainfall: payload.rainfall as number,
            unit: 'mm/hour',
            intensity,
            recordedAt,
          },
        });

        // Update sensor connectivity metadata
        const updateData: {
          lastActiveAt: Date;
          connectivity: SensorConnectivity;
          batteryLevel?: number;
        } = {
          lastActiveAt: recordedAt,
          connectivity: payload.connectivity ?? SensorConnectivity.ONLINE,
        };
        if (payload.batteryLevel !== undefined) {
          updateData.batteryLevel = Math.round(payload.batteryLevel);
        }
        await tx.sensor.update({
          where: { id: sensor.id },
          data: updateData,
        });

        resultData.rainfall = {
          sensorId: sensor.sensorId,
          rainfall: payload.rainfall as number,
          intensity,
        };

        // Automated alerts: Trigger alert if intensity is HEAVY / breaches dangerMin
        const dangerMin = rainfallThreshold?.dangerMin ?? 20;
        if (intensity === RainfallIntensity.HEAVY || (payload.rainfall as number) >= dangerMin) {
          // 15-minute throttle check to prevent spamming
          const fifteenMinutesAgo = new Date(Date.now() - 15 * 60 * 1000);
          const existingAlert = await tx.alert.findFirst({
            where: {
              severity: AlertSeverity.DANGER,
              createdAt: { gte: fifteenMinutesAgo },
              OR: [
                { title: { contains: sensor.sensorId } },
                { message: { contains: sensor.sensorId } },
                { targetArea: sensor.name }
              ]
            }
          });

          if (!existingAlert) {
            await tx.alert.create({
              data: {
                title: `CRITICAL RAINFALL WARNING (${sensor.sensorId})`,
                message: `CRITICAL ALERT: Sensor ${sensor.name} has recorded extreme rainfall of ${payload.rainfall} mm/hour, exceeding the danger threshold of ${dangerMin} mm/hour. Watch for potential flash floods in surrounding areas.`,
                severity: AlertSeverity.DANGER,
                channels: ['PUSH', 'EMAIL'],
                targetArea: sensor.name,
                sentBy: sentById,
              }
            });
          }
        }
      }

      // Handle Flow Rate Reading
      if (hasFlow && flowSensorId) {
        const sensor = await tx.sensor.findFirst({
          where: {
            sensorId: flowSensorId,
            type: SensorType.FLOW_RATE,
            isActive: true,
          },
        });

        if (!sensor) {
          throw new NotFoundException('Sensor flow rate tidak ditemukan.');
        }

        // Insert log
        await tx.flowRateLog.create({
          data: {
            sensorId: sensor.id,
            flowRate: payload.flowRate as number,
            unit: 'l/min',
            recordedAt,
          },
        });

        // Update sensor connectivity metadata
        const updateData: {
          lastActiveAt: Date;
          connectivity: SensorConnectivity;
          batteryLevel?: number;
        } = {
          lastActiveAt: recordedAt,
          connectivity: payload.connectivity ?? SensorConnectivity.ONLINE,
        };
        if (payload.batteryLevel !== undefined) {
          updateData.batteryLevel = Math.round(payload.batteryLevel);
        }
        await tx.sensor.update({
          where: { id: sensor.id },
          data: updateData,
        });

        resultData.flowRate = {
          sensorId: sensor.sensorId,
          flowRate: payload.flowRate as number,
          unit: 'l/min',
        };

        // Automated alerts for Flow Rate (if thresholds exist)
        if (flowThreshold && flowThreshold.dangerMin) {
          const dangerMin = flowThreshold.dangerMin;
          if ((payload.flowRate as number) >= dangerMin) {
            // 15-minute throttle check to prevent spamming
            const fifteenMinutesAgo = new Date(Date.now() - 15 * 60 * 1000);
            const existingAlert = await tx.alert.findFirst({
              where: {
                severity: AlertSeverity.DANGER,
                createdAt: { gte: fifteenMinutesAgo },
                OR: [
                  { title: { contains: sensor.sensorId } },
                  { message: { contains: sensor.sensorId } },
                  { targetArea: sensor.name }
                ]
              }
            });

            if (!existingAlert) {
              await tx.alert.create({
                data: {
                  title: `CRITICAL FLOW RATE WARNING (${sensor.sensorId})`,
                  message: `CRITICAL ALERT: Sensor ${sensor.name} has recorded dangerous water flow rate of ${payload.flowRate} l/min, exceeding the danger threshold of ${dangerMin} l/min.`,
                  severity: AlertSeverity.DANGER,
                  channels: ['PUSH', 'EMAIL'],
                  targetArea: sensor.name,
                  sentBy: sentById,
                }
              });
            }
          }
        }
      }

      return resultData;
    });

    return result;
  }

  private resolveWaterStatus(
    level: number,
    threshold: Threshold | null,
  ): WaterLevelStatus {
    const warningMin = threshold?.warningMin ?? 151;
    const dangerMin = threshold?.dangerMin ?? 221;
    const alertMin = threshold?.alertMin ?? null;

    if (level >= dangerMin) {
      return WaterLevelStatus.DANGER;
    }

    if (alertMin !== null && level >= alertMin) {
      return WaterLevelStatus.ALERT;
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
}

