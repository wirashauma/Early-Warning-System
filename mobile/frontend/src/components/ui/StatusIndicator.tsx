import { statusColor } from "@/constants";
import type { WaterStatus } from "@/types/water-level";
import { Badge } from "./Badge";

const statusLabel: Record<WaterStatus, string> = {
  safe: "Aman",
  alert: "Siaga",
  danger: "Bahaya",
};

interface StatusIndicatorProps {
  status: WaterStatus;
}

export function StatusIndicator({ status }: StatusIndicatorProps) {
  return <Badge className={statusColor[status]}>{statusLabel[status]}</Badge>;
}
