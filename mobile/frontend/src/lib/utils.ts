import type { ThresholdConfig, WaterStatus } from "@/types/water-level";

const defaultThreshold: ThresholdConfig = {
  safeMaxCm: 149,
  alertMaxCm: 199,
  dangerMinCm: 200,
};

export function cn(...classes: Array<string | false | null | undefined>) {
  return classes.filter(Boolean).join(" ");
}

export function formatTimestamp(date: string) {
  return new Date(date).toLocaleString("id-ID", {
    dateStyle: "medium",
    timeStyle: "short",
  });
}

export function getStatusFromLevel(
  levelCm: number,
  threshold: ThresholdConfig = defaultThreshold,
): WaterStatus {
  if (levelCm >= threshold.dangerMinCm) return "danger";
  if (levelCm > threshold.safeMaxCm) return "alert";
  return "safe";
}
