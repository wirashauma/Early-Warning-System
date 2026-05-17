export type WaterStatus = "safe" | "warning" | "alert" | "danger";

export interface WaterLevelPoint {
  timestamp: string;
  levelCm: number;
  rainfallMm: number;
  flowRateLpm?: number;
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
  flowRateLpm?: number;
  status: WaterStatus;
  updatedAt: string;
}

export interface LiveFlowRate {
  sensorId: string;
  sensorName: string;
  flowRateLpm: number;
  updatedAt: string;
}
