import type { WaterStatus } from "./water-level";

export type SensorConnectivity = "online" | "offline";

export interface Sensor {
  id: string;
  name: string;
  riverName: string;
  latitude: number;
  longitude: number;
  connectivity: SensorConnectivity;
  batteryPercent: number;
  lastLevelCm: number;
  status: WaterStatus;
  updatedAt: string;
}
