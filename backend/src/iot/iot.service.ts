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
import { EmailService } from '../common/email/email.service';
import { RealtimeService } from '../realtime/realtime.service';
import { AlertsService } from '../alerts/alerts.service';

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
  constructor(
    private readonly prisma: PrismaService,
    private readonly emailService: EmailService,
    private readonly realtimeService: RealtimeService,
    private readonly alertsService: AlertsService,
  ) {}

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


      }

      return resultData;
    });

    // 3. Emit SSE real-time sensor updates
    this.realtimeService.emitSensorUpdate(result);

    // 4. Trigger automated FCM push & email alerts outside transaction loop
    try {
      if (result.water) {
        const waterInfo = result.water;
        const sensor = await this.prisma.sensor.findUnique({
          where: { sensorId: waterInfo.sensorId },
        });

        if (
          sensor &&
          (waterInfo.status === WaterLevelStatus.WARNING ||
            waterInfo.status === WaterLevelStatus.ALERT ||
            waterInfo.status === WaterLevelStatus.DANGER)
        ) {
          const severity =
            waterInfo.status === WaterLevelStatus.DANGER
              ? AlertSeverity.DANGER
              : AlertSeverity.WARNING;

          const warningMin = waterThreshold?.warningMin ?? 151;
          const dangerMin = waterThreshold?.dangerMin ?? 221;
          const alertMin = waterThreshold?.alertMin ?? 180;

          // 15-minute throttle check to prevent spamming
          const fifteenMinutesAgo = new Date(Date.now() - 15 * 60 * 1000);
          const existingAlert = await this.prisma.alert.findFirst({
            where: {
              severity: severity,
              targetArea: sensor.name,
              sentAt: { gte: fifteenMinutesAgo },
              title: { contains: sensor.sensorId },
            },
          });

          if (!existingAlert) {
            await this.alertsService.broadcast({
              title:
                waterInfo.status === WaterLevelStatus.DANGER
                  ? `BAHAYA: Ketinggian Air Kritikal (${sensor.sensorId})`
                  : waterInfo.status === WaterLevelStatus.ALERT
                    ? `SIAGA: Ketinggian Air Tinggi (${sensor.sensorId})`
                    : `WASPADA: Ketinggian Air Meningkat (${sensor.sensorId})`,
              message:
                waterInfo.status === WaterLevelStatus.DANGER
                  ? `PERINGATAN BAHAYA: Sensor ${sensor.name} mendeteksi ketinggian air mencapai ${waterInfo.waterLevel} cm, melebihi ambang batas bahaya ${dangerMin} cm. Mohon segera lakukan evakuasi!`
                  : waterInfo.status === WaterLevelStatus.ALERT
                    ? `PERINGATAN SIAGA: Sensor ${sensor.name} mendeteksi ketinggian air mencapai ${waterInfo.waterLevel} cm, melebihi ambang batas siaga ${alertMin} cm. Tingkatkan kewaspadaan!`
                    : `PERINGATAN WASPADA: Sensor ${sensor.name} mendeteksi ketinggian air mencapai ${waterInfo.waterLevel} cm, melebihi ambang batas waspada ${warningMin} cm. Selalu pantau situasi terupdate!`,
              severity: severity,
              channels: ['PUSH', 'EMAIL'],
              targetArea: sensor.name,
            });
          }
        }
      }

      if (result.rainfall) {
        const rainInfo = result.rainfall;
        const sensor = await this.prisma.sensor.findUnique({
          where: { sensorId: rainInfo.sensorId },
        });

        if (
          sensor &&
          (rainInfo.intensity === RainfallIntensity.MODERATE ||
            rainInfo.intensity === RainfallIntensity.HEAVY)
        ) {
          const severity =
            rainInfo.intensity === RainfallIntensity.HEAVY
              ? AlertSeverity.DANGER
              : AlertSeverity.WARNING;

          const warningMin = rainfallThreshold?.warningMin ?? 5;
          const dangerMin = rainfallThreshold?.dangerMin ?? 20;

          // 15-minute throttle check to prevent spamming
          const fifteenMinutesAgo = new Date(Date.now() - 15 * 60 * 1000);
          const existingAlert = await this.prisma.alert.findFirst({
            where: {
              severity: severity,
              targetArea: sensor.name,
              sentAt: { gte: fifteenMinutesAgo },
              title: { contains: sensor.sensorId },
            },
          });

          if (!existingAlert) {
            await this.alertsService.broadcast({
              title:
                rainInfo.intensity === RainfallIntensity.HEAVY
                  ? `BAHAYA: Curah Hujan Ekstrim (${sensor.sensorId})`
                  : `WASPADA: Curah Hujan Tinggi (${sensor.sensorId})`,
              message:
                rainInfo.intensity === RainfallIntensity.HEAVY
                  ? `PERINGATAN BAHAYA: Sensor ${sensor.name} mencatat curah hujan ekstrim sebesar ${rainInfo.rainfall} mm/jam, melebihi ambang batas bahaya ${dangerMin} mm/jam. Waspadai banjir bandang segera!`
                  : `PERINGATAN WASPADA: Sensor ${sensor.name} mencatat curah hujan tinggi sebesar ${rainInfo.rainfall} mm/jam, melebihi ambang batas waspada ${warningMin} mm/jam. Berhati-hati saat beraktivitas!`,
              severity: severity,
              channels: ['PUSH', 'EMAIL'],
              targetArea: sensor.name,
            });
          }
        }
      }
    } catch (err) {
      console.error('Failed to trigger automatic FCM & email alerts:', err);
    }

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

