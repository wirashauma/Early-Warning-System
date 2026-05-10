import type { ThresholdConfig, WaterStatus } from "@/types/water-level";

const defaultThreshold: ThresholdConfig = {
  safeMaxCm: 149,
  warningMaxCm: 174,
  alertMaxCm: 199,
  dangerMinCm: 200,
};

export interface RainfallCategory {
  label: "Ringan" | "Sedang" | "Lebat";
  detail: string;
  color: string;
}

export type UserRiskLevel = "normal" | "yellow" | "orange" | "red";

export function cn(...classes: Array<string | false | null | undefined>) {
  return classes.filter(Boolean).join(" ");
}

export function formatTimestamp(date: string) {
  const parsed = new Date(date);
  if (Number.isNaN(parsed.getTime())) {
    return "Waktu tidak valid";
  }

  return parsed.toLocaleString("id-ID", {
    dateStyle: "medium",
    timeStyle: "short",
    timeZone: "Asia/Jakarta",
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

export function getRiskLevelFromLevel(levelCm: number): UserRiskLevel {
  if (levelCm >= 200) {
    return "red";
  }

  if (levelCm >= 180) {
    return "orange";
  }

  if (levelCm >= 150) {
    return "yellow";
  }

  return "normal";
}

export function getRainfallCategory(rainfallMmPerHour: number): RainfallCategory {
  if (rainfallMmPerHour <= 5) {
    return { label: "Ringan", detail: "0-5 mm/jam", color: "text-emerald-700 bg-emerald-100" };
  }

  if (rainfallMmPerHour <= 20) {
    return { label: "Sedang", detail: ">5-20 mm/jam", color: "text-amber-700 bg-amber-100" };
  }

  return { label: "Lebat", detail: ">20 mm/jam", color: "text-rose-700 bg-rose-100" };
}
