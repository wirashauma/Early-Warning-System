import type { WaterStatus } from "./water-level";

export type SensorConnectivity = "online" | "offline";
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
  lastSeenAt?: string | null;
  status: WaterStatus;
  updatedAt: string;
}
