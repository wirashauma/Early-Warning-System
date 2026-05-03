export type WaterStatus = "safe" | "warning" | "alert" | "danger";

export interface WaterLevelPoint {
  timestamp: string;
  levelCm: number;
  rainfallMm: number;
  flowSpeedMs?: number;
  sensorId: string;
}

export interface ThresholdConfig {
  safeMaxCm: number;
  warningMaxCm: number;
  alertMaxCm: number;
  dangerMinCm: number;
}

export interface LiveWaterLevel {
  sensorId: string;
  sensorName: string;
  levelCm: number;
  rainfallMm: number;
  status: WaterStatus;
  updatedAt: string;
}
