import type { WaterStatus } from "./water-level";

export type AlertChannel = "push" | "whatsapp" | "email";

export interface AlertMessage {
  id: string;
  title: string;
  message: string;
  status: WaterStatus;
  channels: AlertChannel[];
  sentAt: string;
}
