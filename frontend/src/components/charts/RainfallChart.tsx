"use client";

import { useMemo, useState } from "react";
import type { WaterLevelPoint } from "@/types/water-level";

interface RainfallChartProps {
  points: WaterLevelPoint[];
}

export function RainfallChart({ points }: RainfallChartProps) {
  const [range, setRange] = useState<"day" | "week">("day");
  const referenceNow = useMemo(() => {
    if (points.length === 0) {
      return 0;
    }

    return new Date(points[points.length - 1].timestamp).getTime();
  }, [points]);

  const chartPoints = useMemo(() => {
    if (points.length === 0) {
      return [] as Array<{ label: string; value: number; timestamp: number }>;
    }

    const dayAgo = referenceNow - 24 * 60 * 60 * 1000;
    const weekAgo = referenceNow - 7 * 24 * 60 * 60 * 1000;

    if (range === "day") {
      const daily = points.filter((point) => new Date(point.timestamp).getTime() >= dayAgo);
      const source = daily.length > 0 ? daily : points.slice(-24);

      return source.map((point) => ({
        label: new Date(point.timestamp).toLocaleTimeString("id-ID", { hour: "2-digit", minute: "2-digit" }),
        value: point.rainfallMm,
        timestamp: new Date(point.timestamp).getTime(),
      })).slice(-12);
    }

    const weekly = points.filter((point) => new Date(point.timestamp).getTime() >= weekAgo);
    const source = weekly.length > 0 ? weekly : points;

    const grouped = new Map<string, { sum: number; count: number; ts: number }>();
    source.forEach((point) => {
      const date = new Date(point.timestamp);
      const key = date.toISOString().slice(0, 10);
      const current = grouped.get(key) ?? { sum: 0, count: 0, ts: date.getTime() };
      grouped.set(key, {
        sum: current.sum + point.rainfallMm,
        count: current.count + 1,
        ts: Math.max(current.ts, date.getTime()),
      });
    });

    return Array.from(grouped.entries())
      .sort((a, b) => a[1].ts - b[1].ts)
      .slice(-7)
      .map(([key, value]) => ({
        label: new Date(`${key}T00:00:00`).toLocaleDateString("id-ID", { weekday: "short" }),
        value: Math.round(value.sum / Math.max(value.count, 1)),
        timestamp: value.ts,
      }));
  }, [points, range, referenceNow]);

  const values = chartPoints.map((p) => p.value);
  const max = Math.max(...values, 1);
  const latest = values.at(-1) ?? 0;
  const average = values.length > 0 ? Math.round(values.reduce((sum, value) => sum + value, 0) / values.length) : 0;

  const category = latest < 5 ? "Ringan" : latest <= 20 ? "Sedang" : "Lebat";
  const categoryClass =
    latest < 5
      ? "bg-emerald-100 text-emerald-700"
      : latest <= 20
        ? "bg-amber-100 text-amber-700"
        : "bg-rose-100 text-rose-700";

  const axisTickIndexes = (() => {
    const total = chartPoints.length;
    if (total <= 0) return [] as number[];
    if (total <= 6) return chartPoints.map((_, index) => index);
    return [0, Math.floor((total - 1) / 2), total - 1];
  })();

  return (
    <div className="space-y-3.5">
      <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
        <h3 className="text-base font-semibold leading-tight text-slate-800">Grafik Curah Hujan</h3>
        <div className="flex flex-wrap items-center gap-2 sm:justify-end">
          <div className="rounded-full border border-slate-200 p-0.5 text-xs">
            <button
              type="button"
              onClick={() => setRange("day")}
              className={`rounded-full px-2 py-1 font-semibold ${range === "day" ? "bg-cyan-100 text-cyan-700" : "text-slate-500"}`}
            >
              Day
            </button>
            <button
              type="button"
              onClick={() => setRange("week")}
              className={`rounded-full px-2 py-1 font-semibold ${range === "week" ? "bg-cyan-100 text-cyan-700" : "text-slate-500"}`}
            >
              Week
            </button>
          </div>
          <span className={`rounded-full px-2.5 py-1 text-xs font-semibold ${categoryClass}`}>
            {category} ({latest} mm/jam)
          </span>
        </div>
      </div>

      <div className="rounded-xl border border-cyan-100 bg-cyan-50/40 p-3">
        <div className="flex h-24 items-end gap-1.5">
          {chartPoints.map((point, index) => (
            <div key={`${point.timestamp}-${index}`} className="flex h-full min-w-0 flex-1 flex-col items-center">
              <div
                className="w-full rounded-sm bg-cyan-500"
                style={{ height: `${Math.max(6, (point.value / max) * 100)}%` }}
                title={`${point.value} mm/jam`}
              />
            </div>
          ))}
        </div>

        <div className="mt-2 flex items-center justify-between text-[11px] text-slate-500">
          {axisTickIndexes.map((index) => {
            const point = chartPoints[index];
            return (
              <span key={`${point.timestamp}-${index}`} className="max-w-16 truncate text-center">
                {point.label}
              </span>
            );
          })}
        </div>
      </div>

      <div className="grid grid-cols-1 gap-2 text-xs sm:grid-cols-3">
        <div className="rounded-lg border border-slate-200 bg-white px-2.5 py-2">
          <p className="text-slate-500">Saat ini</p>
          <p className="font-semibold text-slate-800">{latest} mm/jam</p>
        </div>
        <div className="rounded-lg border border-slate-200 bg-white px-2.5 py-2">
          <p className="text-slate-500">Rata-rata</p>
          <p className="font-semibold text-slate-800">{average} mm/jam</p>
        </div>
        <div className="rounded-lg border border-slate-200 bg-white px-2.5 py-2">
          <p className="text-slate-500">Puncak</p>
          <p className="font-semibold text-slate-800">{max} mm/jam</p>
        </div>
      </div>

      <p className="text-xs text-slate-500">Rentang {range === "day" ? "harian" : "mingguan"} untuk membaca intensitas hujan lebih cepat.</p>
    </div>
  );
}
