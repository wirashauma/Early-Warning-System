import type { WaterStatus } from "./water-level";

export type SensorConnectivity = "online" | "offline" | "ONLINE" | "OFFLINE" | "MAINTENANCE";
export type SensorType = "WATER_LEVEL" | "RAINFALL" | "FLOW_RATE";

export interface Sensor {
  id: string;
  name: string;
  riverName: string;
  latitude: number;
  longitude: number;
  type?: SensorType;
  connectivity: SensorConnectivity;
  batteryPercent: number;
  lastLevelCm: number;
  hasWaterLevelData?: boolean;
  lastRainfall?: number;
  hasRainfallData?: boolean;
  lastFlowRate?: number;
  hasFlowRateData?: boolean;
  lastSeenAt?: string | null;
  status: WaterStatus;
  updatedAt: string;
}
