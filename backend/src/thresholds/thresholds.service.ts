import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

interface UpdateThresholdRequest {
  waterLevel?: {
    normal: { min: number; max: number };
    warning: { min: number; max: number };
    alert?: { min: number; max: number };
    danger: { min: number; max: number | null };
  };
  rainfall?: {
    light: { min: number; max: number };
    moderate: { min: number; max: number };
    heavy: { min: number; max: number | null };
  };
}

@Injectable()
export class ThresholdsService {
  constructor(private readonly prisma: PrismaService) {}

  async getCurrent() {
    const rows = await this.prisma.threshold.findMany();

    const waterLevel = rows.find((item) => item.type === 'water_level');
    const rainfall = rows.find((item) => item.type === 'rainfall');

    return {
      waterLevel: waterLevel
        ? {
            normal: { min: waterLevel.normalMin, max: waterLevel.normalMax },
            warning: { min: waterLevel.warningMin, max: waterLevel.warningMax },
            alert: { min: waterLevel.alertMin ?? 0, max: waterLevel.alertMax ?? 0 },
            danger: { min: waterLevel.dangerMin, max: waterLevel.dangerMax },
          }
        : null,
      rainfall: rainfall
        ? {
            light: { min: rainfall.normalMin, max: rainfall.normalMax },
            moderate: { min: rainfall.warningMin, max: rainfall.warningMax },
            heavy: { min: rainfall.dangerMin, max: rainfall.dangerMax },
          }
        : null,
    };
  }

  async update(payload: UpdateThresholdRequest) {
    if (!payload.waterLevel && !payload.rainfall) {
      throw new BadRequestException('Payload threshold tidak boleh kosong.');
    }

    if (payload.waterLevel) {
      await this.prisma.threshold.upsert({
        where: { type: 'water_level' },
        create: {
          type: 'water_level',
          normalMin: payload.waterLevel.normal.min,
          normalMax: payload.waterLevel.normal.max,
          warningMin: payload.waterLevel.warning.min,
          warningMax: payload.waterLevel.warning.max,
          alertMin: payload.waterLevel.alert?.min ?? null,
          alertMax: payload.waterLevel.alert?.max ?? null,
          dangerMin: payload.waterLevel.danger.min,
          dangerMax: payload.waterLevel.danger.max,
        },
        update: {
          normalMin: payload.waterLevel.normal.min,
          normalMax: payload.waterLevel.normal.max,
          warningMin: payload.waterLevel.warning.min,
          warningMax: payload.waterLevel.warning.max,
          alertMin: payload.waterLevel.alert?.min ?? null,
          alertMax: payload.waterLevel.alert?.max ?? null,
          dangerMin: payload.waterLevel.danger.min,
          dangerMax: payload.waterLevel.danger.max,
        },
      });
    }

    if (payload.rainfall) {
      await this.prisma.threshold.upsert({
        where: { type: 'rainfall' },
        create: {
          type: 'rainfall',
          normalMin: payload.rainfall.light.min,
          normalMax: payload.rainfall.light.max,
          warningMin: payload.rainfall.moderate.min,
          warningMax: payload.rainfall.moderate.max,
          dangerMin: payload.rainfall.heavy.min,
          dangerMax: payload.rainfall.heavy.max,
        },
        update: {
          normalMin: payload.rainfall.light.min,
          normalMax: payload.rainfall.light.max,
          warningMin: payload.rainfall.moderate.min,
          warningMax: payload.rainfall.moderate.max,
          dangerMin: payload.rainfall.heavy.min,
          dangerMax: payload.rainfall.heavy.max,
        },
      });
    }

    return this.getCurrent();
  }
}
