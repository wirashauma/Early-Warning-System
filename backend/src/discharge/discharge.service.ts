import { Injectable } from '@nestjs/common';
import { SensorType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class DischargeService {
  constructor(private readonly prisma: PrismaService) {}

  async getKomeringDischarge() {
    let sensor = await this.prisma.sensor.findUnique({
      where: { sensorId: 'EWS-FL-KOMERING' },
    });

    if (!sensor) {
      sensor = await this.prisma.sensor.create({
        data: {
          sensorId: 'EWS-FL-KOMERING',
          name: 'Water Flow Komering',
          type: SensorType.FLOW_RATE,
          latitude: -3.2201,
          longitude: 104.8394,
          batteryLevel: 98,
          connectivity: 'ONLINE',
          isActive: true,
          installedAt: new Date('2000-01-01'),
          lastActiveAt: new Date(),
        },
      });
    }

    const existingLogsCount = await this.prisma.flowRateLog.count({
      where: { sensorId: sensor.id },
    });

    if (existingLogsCount === 0) {
      const logs: any[] = [];
      
      // Seasonal bases in m3/s:
      // Wet season (Nov, Dec, Jan, Feb): 1500 to 2400
      // Transitional (Mar, Apr, Sep, Oct): 900 to 1600
      // Dry season (May, Jun, Jul, Aug): 400 to 850
      const monthlyBases = [2100, 1900, 1500, 1100, 800, 550, 450, 500, 950, 1300, 1700, 2300];

      for (let year = 2000; year <= 2010; year++) {
        for (let month = 0; month < 12; month++) {
          const base = monthlyBases[month];
          // Adding a random variation of -15% to +15% to make data highly realistic
          const flowRate = parseFloat(
            (base * (0.85 + Math.random() * 0.3)).toFixed(2),
          );
          const recordedAt = new Date(year, month, 15, 12, 0, 0);

          logs.push({
            sensorId: sensor.id,
            flowRate,
            unit: 'm3/s',
            recordedAt,
          });
        }
      }
      await this.prisma.flowRateLog.createMany({ data: logs });
    }

    return this.prisma.flowRateLog.findMany({
      where: { sensorId: sensor.id },
      orderBy: { recordedAt: 'asc' },
    });
  }
}
