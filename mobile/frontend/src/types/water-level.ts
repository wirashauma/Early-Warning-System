export type WaterStatus = "safe" | "alert" | "danger";

export interface WaterLevelPoint {
  timestamp: string;
  levelCm: number;
  rainfallMm: number;
  sensorId: string;
}

export interface ThresholdConfig {
  safeMaxCm: number;
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
