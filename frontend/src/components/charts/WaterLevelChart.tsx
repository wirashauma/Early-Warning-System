"use client";

import { useEffect, useState, useMemo, useRef } from "react";
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import type { WaterLevelPoint } from "@/types/water-level";
import jsPDF from "jspdf";
import html2canvas from "html2canvas-pro";

interface WaterLevelChartProps {
  points: WaterLevelPoint[];
}

export function WaterLevelChart({ points = [] }: WaterLevelChartProps) {
  const [mounted, setMounted] = useState(false);
  const [range, setRange] = useState<"day" | "week">("day");
  const cardRef = useRef<HTMLDivElement>(null);

  const handleExportPDF = async () => {
    if (!cardRef.current) return;
    try {
      const exportBtn = cardRef.current.querySelector(".pdf-export-btn") as HTMLElement;
      if (exportBtn) exportBtn.style.opacity = "0";

      const canvas = await html2canvas(cardRef.current, {
        scale: 2,
        useCORS: true,
        backgroundColor: "#ffffff",
      });

      if (exportBtn) exportBtn.style.opacity = "1";

      const imgData = canvas.toDataURL("image/png");
      const pdf = new jsPDF({
        orientation: "landscape",
        unit: "px",
        format: [canvas.width / 2, canvas.height / 2],
      });

      pdf.addImage(imgData, "PNG", 0, 0, canvas.width / 2, canvas.height / 2);
      pdf.save("Grafik_Ketinggian_Air.pdf");
    } catch (err) {
      console.error("PDF Export failed:", err);
    }
  };

  useEffect(() => {
    setMounted(true);
  }, []);

  const referenceNow = useMemo(() => {
    if (points.length === 0) return 0;
    return new Date(points[points.length - 1].timestamp).getTime();
  }, [points]);

  const isDemo = points.length === 0;

  // Aggregate and filter data points for Recharts based on range selection
  const chartData = useMemo(() => {
    if (isDemo) {
      return [
        { label: "08:00", value: 2.1 },
        { label: "09:00", value: 2.5 },
        { label: "10:00", value: 3.8 },
        { label: "11:00", value: 5.2 },
        { label: "12:00", value: 8.5 },
        { label: "13:00", value: 11.0 }, // Peak
        { label: "14:00", value: 9.2 },
      ];
    }

    if (points.length === 0) return [];

    const dayAgo = referenceNow - 24 * 60 * 60 * 1000;
    const weekAgo = referenceNow - 7 * 24 * 60 * 60 * 1000;

    if (range === "day") {
      const daily = points.filter((point) => new Date(point.timestamp).getTime() >= dayAgo);
      const source = daily.length > 0 ? daily : points.slice(-24);

      return source
        .map((point) => ({
          label: new Date(point.timestamp).toLocaleTimeString("id-ID", {
            hour: "2-digit",
            minute: "2-digit",
          }),
          value: point.levelCm,
          timestamp: new Date(point.timestamp).getTime(),
        }))
        .slice(-12);
    }

    const weekly = points.filter((point) => new Date(point.timestamp).getTime() >= weekAgo);
    const source = weekly.length > 0 ? weekly : points;

    const grouped = new Map<string, { sum: number; count: number; ts: number }>();
    source.forEach((point) => {
      const date = new Date(point.timestamp);
      const key = date.toISOString().slice(0, 10);
      const current = grouped.get(key) ?? { sum: 0, count: 0, ts: date.getTime() };
      grouped.set(key, {
        sum: current.sum + point.levelCm,
        count: current.count + 1,
        ts: Math.max(current.ts, date.getTime()),
      });
    });

    return Array.from(grouped.entries())
      .sort((a, b) => a[1].ts - b[1].ts)
      .slice(-7)
      .map(([key, value]) => ({
        label: new Date(`${key}T00:00:00`).toLocaleDateString("id-ID", {
          weekday: "short",
        }),
        value: Math.round(value.sum / Math.max(value.count, 1)),
        timestamp: value.ts,
      }));
  }, [points, range, referenceNow, isDemo]);

  // Calculations for stats boxes at the bottom
  const values = chartData.map((p) => p.value);
  const min = isDemo ? 2.1 : (values.length > 0 ? Math.min(...values) : 0);
  const max = isDemo ? 11.0 : (values.length > 0 ? Math.max(...values) : 0);
  const latest = isDemo ? 9.2 : (points.length > 0 ? points[points.length - 1].levelCm : 0);
  const average =
    isDemo ? 6.0 : (values.length > 0 ? Math.round(values.reduce((sum, v) => sum + v, 0) / values.length) : 0);

  if (!mounted) {
    return <div className="h-[430px] w-full animate-pulse rounded-xl bg-slate-50" />;
  }

  const isEmpty = false;

  return (
    <div ref={cardRef} className="flex flex-col h-full justify-between">
      {/* Unified Header - 2 Rows Compact Layout to prevent wrapping */}
      <div className="w-full mb-4">
        <div className="flex flex-row justify-between items-center w-full mb-2">
          <h3 className="text-base font-bold text-slate-800 leading-tight">Grafik Ketinggian Air</h3>
          <button
            type="button"
            onClick={handleExportPDF}
            className="pdf-export-btn inline-flex items-center gap-1 rounded-md border border-rose-200 bg-rose-50/80 px-2 py-0.5 text-[11px] font-bold text-rose-700 transition hover:bg-rose-100 cursor-pointer shadow-3xs"
          >
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="h-3 w-3">
              <path fillRule="evenodd" d="M4.5 2A1.5 1.5 0 003 3.5v13A1.5 1.5 0 004.5 18h11a1.5 1.5 0 001.5-1.5V7.621a1.5 1.5 0 00-.44-1.06l-4.12-4.122A1.5 1.5 0 0011.378 2H4.5zm2.25 8.5a.75.75 0 000 1.5h6.5a.75.75 0 000-1.5h-6.5zm0 3a.75.75 0 000 1.5h6.5a.75.75 0 000-1.5h-6.5z" clipRule="evenodd" />
            </svg>
            PDF
          </button>
        </div>
        <div className="flex flex-row items-center justify-between w-full pb-2 border-b border-slate-100">
          <div className="inline-flex rounded-full bg-slate-100 p-0.5 border border-slate-200 text-xs">
            <button
              type="button"
              onClick={() => setRange("day")}
              className={`rounded-full px-3 py-0.5 font-medium transition-colors ${
                range === "day"
                  ? "bg-white text-blue-600 shadow-xs font-semibold"
                  : "text-slate-500 hover:text-slate-800"
              }`}
            >
              Day
            </button>
            <button
              type="button"
              onClick={() => setRange("week")}
              className={`rounded-full px-3 py-0.5 font-medium transition-colors ${
                range === "week"
                  ? "bg-white text-blue-600 shadow-xs font-semibold"
                  : "text-slate-500 hover:text-slate-800"
              }`}
            >
              Week
            </button>
          </div>
          <span className="rounded-full bg-blue-50 px-2 py-0.5 text-xs font-semibold text-blue-700 border border-blue-100 whitespace-nowrap">
            Live: {latest} cm
          </span>
        </div>
      </div>

      {/* Chart Wrapper Area */}
      <div className="relative flex-grow flex flex-col justify-center min-h-[250px] w-full mb-4">
        {isEmpty ? (
          /* High-Fidelity Empty State */
          <div className="flex flex-col items-center justify-center h-[250px] rounded-xl border border-dashed border-slate-300 bg-slate-50/50 p-6 text-center">
            <div className="rounded-full bg-slate-100 p-3 text-slate-400 mb-2 border border-slate-200/60 shadow-2xs">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                fill="none"
                viewBox="0 0 24 24"
                strokeWidth={2}
                stroke="currentColor"
                className="h-6 w-6"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M20.25 14.15v4.25c0 .414-.336.75-.75.75H4.5a.75.75 0 0 1-.75-.75v-4.25m16.5 0a3 3 0 0 0-3-3H6.75a3 3 0 0 0-3 3m16.5 0V9a2.25 2.25 0 0 0-2.25-2.25H5.25A2.25 2.25 0 0 0 3 9v5.15"
                />
              </svg>
            </div>
            <p className="text-sm font-semibold text-slate-600">No Data Available</p>
            <p className="text-xs text-slate-400 mt-1 max-w-[200px]">
              Belum ada data ketinggian air yang masuk untuk sensor ini.
            </p>
          </div>
        ) : (
          <div className="h-[250px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <AreaChart data={chartData} margin={{ top: 10, right: 5, left: -20, bottom: 0 }}>
                <defs>
                  <linearGradient id="colorWaterLevel" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.2} />
                    <stop offset="95%" stopColor="#3b82f6" stopOpacity={0.0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" vertical={false} />
                <XAxis
                  dataKey="label"
                  axisLine={{ stroke: "#e2e8f0" }}
                  tickLine={false}
                  tick={{ fill: "#64748b", fontSize: 11 }}
                />
                <YAxis
                  axisLine={{ stroke: "#e2e8f0" }}
                  tickLine={false}
                  tick={{ fill: "#64748b", fontSize: 11 }}
                />
                <Tooltip
                  content={({ active, payload }) => {
                    if (active && payload && payload.length) {
                      return (
                        <div className="rounded-lg border border-slate-200 bg-white/95 p-2.5 shadow-md backdrop-blur-xs">
                          <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">
                            {range === "day" ? "Waktu Ingest" : "Hari"}
                          </p>
                          <p className="mt-0.5 text-sm font-black text-blue-600">
                            {payload[0].value} <span className="text-xs font-semibold text-slate-500">cm</span>
                          </p>
                        </div>
                      );
                    }
                    return null;
                  }}
                />
                <Area
                  type="monotone"
                  dataKey="value"
                  stroke="#3b82f6"
                  strokeWidth={2}
                  fillOpacity={1}
                  fill="url(#colorWaterLevel)"
                />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        )}
      </div>

      {/* Standardized Statistics Grid Footer */}
      <div className="grid grid-cols-3 gap-2 mt-2">
        <div className="rounded-lg bg-slate-50 p-2.5 text-center border border-slate-100/40">
          <p className="text-[10px] sm:text-xs text-slate-500 font-medium whitespace-nowrap">Minimum</p>
          <p className="text-xs sm:text-sm font-bold text-slate-700 mt-0.5 whitespace-nowrap">{min} cm</p>
        </div>
        <div className="rounded-lg bg-slate-50 p-2.5 text-center border border-slate-100/40">
          <p className="text-[10px] sm:text-xs text-slate-500 font-medium whitespace-nowrap">Rata-rata</p>
          <p className="text-xs sm:text-sm font-bold text-slate-700 mt-0.5 whitespace-nowrap">{average} cm</p>
        </div>
        <div className="rounded-lg bg-slate-50 p-2.5 text-center border border-slate-100/40">
          <p className="text-[10px] sm:text-xs text-slate-500 font-medium whitespace-nowrap">Saat Ini</p>
          <p className="text-xs sm:text-sm font-bold text-slate-700 mt-0.5 whitespace-nowrap">{latest} cm</p>
        </div>
      </div>
    </div>
  );
}
