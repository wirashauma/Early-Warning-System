"use client";

import { useEffect, useMemo, useState } from "react";
import {
  Area,
  AreaChart,
  CartesianGrid,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { Card } from "@/components/ui/Card";
import type { ThresholdIotPoint } from "@/hooks/useThresholdIotData";

interface ThresholdRainfallChartProps {
  data: ThresholdIotPoint[];
  loading: boolean;
}

interface ChartDatum {
  key: string;
  sensorName: string;
  recordedAt: string;
  timeLabel: string;
  value: number;
}

const MAX_POINTS = 18;

function formatTime(date: string) {
  return new Intl.DateTimeFormat("id-ID", {
    hour: "2-digit",
    minute: "2-digit",
  }).format(new Date(date));
}

function RainfallTooltip({ active, payload }: { active?: boolean; payload?: Array<{ payload?: ChartDatum }>; }) {
  if (!active || !payload?.length || !payload[0]?.payload) {
    return null;
  }

  const point = payload[0].payload as ChartDatum;

  return (
    <div className="rounded-2xl border border-slate-200 bg-white/95 px-4 py-3 text-sm shadow-xl shadow-slate-900/10 backdrop-blur">
      <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">{point.sensorName}</p>
      <p className="mt-1 text-sm font-semibold text-slate-900">{formatTime(point.recordedAt)}</p>
      <p className="mt-2 text-sm text-slate-600">
        Nilai: <span className="font-semibold text-slate-900">{point.value} mm/jam</span>
      </p>
    </div>
  );
}

function ChartSkeleton() {
  return (
    <div className="space-y-4" aria-hidden="true">
      <div className="flex items-center justify-between gap-3">
        <div className="space-y-2">
          <div className="h-4 w-40 rounded-full bg-slate-200 animate-pulse" />
          <div className="h-3 w-64 rounded-full bg-slate-200 animate-pulse" />
        </div>
        <div className="h-7 w-24 rounded-full bg-slate-200 animate-pulse" />
      </div>

      <div className="rounded-2xl border border-slate-100 bg-slate-50/70 p-4">
        <div className="flex h-62.5 items-end gap-3">
          {Array.from({ length: 8 }).map((_, index) => (
            <div key={index} className="flex h-full flex-1 items-end">
              <div
                className="w-full rounded-t-2xl bg-slate-200 animate-pulse"
                style={{ height: `${28 + ((index % 5) * 12)}%` }}
              />
            </div>
          ))}
        </div>
      </div>

      <div className="grid grid-cols-1 gap-2 sm:grid-cols-3">
        <div className="h-16 rounded-xl bg-slate-200 animate-pulse" />
        <div className="h-16 rounded-xl bg-slate-200 animate-pulse" />
        <div className="h-16 rounded-xl bg-slate-200 animate-pulse" />
      </div>
    </div>
  );
}

export function ThresholdRainfallChart({ data, loading }: ThresholdRainfallChartProps) {
  const [series, setSeries] = useState<ChartDatum[]>([]);

  const latestPoints = useMemo(() => {
    return [...data]
      .sort((a, b) => new Date(a.recordedAt).getTime() - new Date(b.recordedAt).getTime())
      .map((point) => ({
        key: `${point.sensorId}-${point.recordedAt}`,
        sensorName: point.sensorName,
        recordedAt: point.recordedAt,
        timeLabel: formatTime(point.recordedAt),
        value: Number(point.value.toFixed(2)),
      }));
  }, [data]);

  useEffect(() => {
    if (loading) {
      return;
    }

    if (latestPoints.length === 0) {
      setSeries([]);
      return;
    }

    setSeries((prev) => {
      const merged = [...prev, ...latestPoints];
      const deduped = Array.from(new Map(merged.map((item) => [item.key, item])).values());
      return deduped.slice(-MAX_POINTS);
    });
  }, [latestPoints, loading]);

  const chartData = series.length > 0 ? series : latestPoints;
  const latest = chartData.at(-1)?.value ?? 0;
  const average = chartData.length > 0 ? Number((chartData.reduce((sum, item) => sum + item.value, 0) / chartData.length).toFixed(2)) : 0;
  const max = chartData.length > 0 ? Math.max(...chartData.map((item) => item.value)) : 0;
  const min = chartData.length > 0 ? Math.min(...chartData.map((item) => item.value)) : 0;

  return (
    <Card className="rounded-2xl border border-slate-100 bg-white/80 p-5 shadow-sm backdrop-blur">
      {loading ? (
        <ChartSkeleton />
      ) : (
        <div className="space-y-4">
          <div className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <h3 className="text-base font-semibold text-slate-800">Grafik Curah Hujan (Real-time)</h3>
              <p className="text-sm text-slate-500">Area chart lembut untuk intensitas hujan terpantau.</p>
            </div>
            <span className="rounded-full bg-sky-50 px-3 py-1 text-xs font-semibold text-sky-700">
              Latest {latest} mm/jam
            </span>
          </div>

          <div className="h-62.5 rounded-2xl border border-slate-100 bg-linear-to-b from-white to-sky-50/50 p-3">
            <ResponsiveContainer width="100%" height="100%" minWidth={0}>
              <AreaChart data={chartData} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
                <defs>
                  <linearGradient id="thresholdRainfallFill" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#0ea5e9" stopOpacity={0.32} />
                    <stop offset="95%" stopColor="#0ea5e9" stopOpacity={0.03} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e2e8f0" />
                <XAxis
                  dataKey="timeLabel"
                  tickLine={false}
                  axisLine={false}
                  tick={{ fill: "#64748b", fontSize: 12 }}
                  interval="preserveStartEnd"
                />
                <YAxis
                  tickLine={false}
                  axisLine={false}
                  tick={{ fill: "#64748b", fontSize: 12 }}
                  width={36}
                />
                <Tooltip
                  content={<RainfallTooltip />}
                  cursor={{ stroke: "#94a3b8", strokeDasharray: "3 3" }}
                />
                <Area
                  type="monotone"
                  dataKey="value"
                  stroke="#0ea5e9"
                  strokeWidth={3}
                  fill="url(#thresholdRainfallFill)"
                  fillOpacity={1}
                  dot={{ r: 3, strokeWidth: 2, fill: "#ffffff", stroke: "#0ea5e9" }}
                  activeDot={{ r: 5, strokeWidth: 0, fill: "#0284c7" }}
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>

          <div className="grid grid-cols-1 gap-2 sm:grid-cols-3">
            <div className="rounded-xl border border-slate-200 bg-white px-3 py-3">
              <p className="text-xs text-slate-500">Saat ini</p>
              <p className="mt-1 text-sm font-semibold text-slate-900">{latest} mm/jam</p>
            </div>
            <div className="rounded-xl border border-slate-200 bg-white px-3 py-3">
              <p className="text-xs text-slate-500">Rata-rata</p>
              <p className="mt-1 text-sm font-semibold text-slate-900">{average} mm/jam</p>
            </div>
            <div className="rounded-xl border border-slate-200 bg-white px-3 py-3">
              <p className="text-xs text-slate-500">Rentang</p>
              <p className="mt-1 text-sm font-semibold text-slate-900">{min} - {max} mm/jam</p>
            </div>
          </div>
        </div>
      )}
    </Card>
  );
}
