"use client";

import { useEffect, useState, useMemo, useRef } from "react";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import type { WaterLevelPoint } from "@/types/water-level";
import jsPDF from "jspdf";
import html2canvas from "html2canvas-pro";

interface FlowSpeedChartProps {
  points: WaterLevelPoint[];
}

export function FlowSpeedChart({ points = [] }: FlowSpeedChartProps) {
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
      pdf.save("Grafik_Debit_Air.pdf");
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
        { label: "1", value: 13.0 },
        { label: "2", value: 16.8 },
        { label: "3", value: 15.2 },
        { label: "4", value: 15.8 },
        { label: "5", value: 14.0 },
        { label: "6", value: 14.0 },
        { label: "7", value: 11.5 },
        { label: "8", value: 15.0 },
        { label: "9", value: 15.0 },
        { label: "10", value: 15.0 },
        { label: "11", value: 13.0 },
        { label: "12", value: 14.0 },
        { label: "13", value: 18.0 },
        { label: "14", value: 18.0 },
        { label: "15", value: 15.0 },
        { label: "16", value: 12.2 },
        { label: "17", value: 10.6 },
        { label: "18", value: 12.0 },
        { label: "19", value: 26.6 },
        { label: "20", value: 20.3 },
      ];
    }

    if (points.length === 0) return [];

    const dayAgo = referenceNow - 24 * 60 * 60 * 1000;
    const weekAgo = referenceNow - 7 * 24 * 60 * 60 * 1000;

    if (range === "day") {
      const daily = points.filter((point) => new Date(point.timestamp).getTime() >= dayAgo);
      const source = daily.length > 0 ? daily : points;
      const activeSource = source.slice(-20);

      return activeSource.map((point, index) => {
        const val = point.flowRateLpm ?? Number((point.levelCm / 260 + point.rainfallMm / 40).toFixed(2));
        return {
          label: (index + 1).toString(),
          value: parseFloat(val.toFixed(2)),
          timestamp: new Date(point.timestamp).getTime(),
        };
      });
    }

    const weekly = points.filter((point) => new Date(point.timestamp).getTime() >= weekAgo);
    const source = weekly.length > 0 ? weekly : points;

    const grouped = new Map<string, { sum: number; count: number; ts: number }>();
    source.forEach((point) => {
      const date = new Date(point.timestamp);
      const key = date.toISOString().slice(0, 10);
      const val = point.flowRateLpm ?? Number((point.levelCm / 260 + point.rainfallMm / 40).toFixed(2));
      const current = grouped.get(key) ?? { sum: 0, count: 0, ts: date.getTime() };
      grouped.set(key, {
        sum: current.sum + val,
        count: current.count + 1,
        ts: Math.max(current.ts, date.getTime()),
      });
    });

    return Array.from(grouped.entries())
      .sort((a, b) => a[1].ts - b[1].ts)
      .slice(-7)
      .map(([key, value], index) => ({
        label: (index + 1).toString(),
        value: parseFloat((value.sum / Math.max(value.count, 1)).toFixed(2)),
        timestamp: value.ts,
      }));
  }, [points, range, referenceNow, isDemo]);

  // Dynamic X-axis ticks based on active range
  const xAxisTicks = useMemo(() => {
    if (range === "day") {
      return ["1", "4", "7", "10", "13", "16", "19", "20"];
    }
    return ["1", "2", "3", "4", "5", "6", "7"];
  }, [range]);

  // Calculations for stats boxes at the bottom
  const values = chartData.map((p) => p.value);
  const min = isDemo ? 10.6 : (values.length > 0 ? Math.min(...values) : 0);
  const max = isDemo ? 26.6 : (values.length > 0 ? Math.max(...values) : 0);
  const latest =
    isDemo ? 20.3 : (points.length > 0
      ? parseFloat((points[points.length - 1].flowRateLpm ?? Number((points[points.length - 1].levelCm / 260 + points[points.length - 1].rainfallMm / 40).toFixed(2))).toFixed(2))
      : 0);
  const average =
    isDemo ? 15.5 : (values.length > 0
      ? parseFloat((values.reduce((sum, v) => sum + v, 0) / values.length).toFixed(2))
      : 0);

  // Status Badge and Trend Resolution
  const trendClass =
    latest >= 20
      ? "bg-rose-50 text-rose-700 border-rose-100"
      : latest >= 10
      ? "bg-amber-50 text-amber-700 border-amber-100"
      : "bg-emerald-50 text-emerald-700 border-emerald-100";
  const trendLabel = latest >= 20 ? "Debit Tinggi" : latest >= 10 ? "Debit Sedang" : "Debit Rendah";

  if (!mounted) {
    return <div className="h-[430px] w-full animate-pulse rounded-xl bg-slate-50" />;
  }

  const isEmpty = false;

  return (
    <div ref={cardRef} className="flex flex-col h-full justify-between">
      {/* Unified Header - 2 Rows Compact Layout to prevent wrapping */}
      <div className="w-full mb-4">
        <div className="flex flex-row justify-between items-center w-full mb-2">
          <h3 className="text-base font-bold text-slate-800 leading-tight">Grafik Debit Air</h3>
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
          <span className={`rounded-full px-2 py-0.5 text-xs font-semibold border whitespace-nowrap ${trendClass}`}>
            {trendLabel} ({latest} L/m)
          </span>
        </div>
      </div>

      {/* Chart Wrapper Area */}
      <div className="relative flex-grow flex flex-col justify-center min-h-[250px] w-full mb-4">
        <div className="h-[250px] w-full">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={chartData} margin={{ top: 15, right: 15, left: -15, bottom: 25 }}>
              <CartesianGrid stroke="#cbd5e1" vertical={false} />
              
              {/* Secondary axes to complete the solid border box */}
              <XAxis
                xAxisId="top"
                orientation="top"
                axisLine={{ stroke: "#8c8c8c", strokeWidth: 1 }}
                tick={false}
                tickLine={false}
              />
              <YAxis
                yAxisId="right"
                orientation="right"
                axisLine={{ stroke: "#8c8c8c", strokeWidth: 1 }}
                tick={false}
                tickLine={false}
              />

              <XAxis
                xAxisId={0}
                dataKey="label"
                ticks={xAxisTicks}
                axisLine={{ stroke: "#8c8c8c", strokeWidth: 1 }}
                tickLine={{ stroke: "#8c8c8c", strokeWidth: 1 }}
                tick={{ fill: "#000000", fontSize: 10, fontWeight: 500 }}
                interval={0}
                label={{
                  value: "Hari Pengukuran",
                  position: "insideBottom",
                  offset: -10,
                  fill: "#000000",
                  style: { fontSize: 11, fontWeight: 600 },
                }}
              />
              <YAxis
                yAxisId={0}
                domain={[0, 30]}
                ticks={[0, 5, 10, 15, 20, 25, 30]}
                axisLine={{ stroke: "#8c8c8c", strokeWidth: 1 }}
                tickLine={{ stroke: "#8c8c8c", strokeWidth: 1 }}
                tick={{ fill: "#000000", fontSize: 10, fontWeight: 500 }}
              />
              <Tooltip
                cursor={{ fill: "#f8fafc", opacity: 0.8 }}
                content={({ active, payload }) => {
                  if (active && payload && payload.length) {
                    return (
                      <div className="rounded-lg border border-slate-200 bg-white/95 p-2.5 shadow-md backdrop-blur-xs">
                        <p className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">
                          Hari Pengukuran: {payload[0].payload.label}
                        </p>
                        <p className="mt-0.5 text-sm font-black text-blue-600">
                          {payload[0].value} <span className="text-xs font-semibold text-slate-500">L/min</span>
                        </p>
                      </div>
                    );
                  }
                  return null;
                }}
              />
              <Bar
                xAxisId={0}
                yAxisId={0}
                dataKey="value"
                fill="#3f80c0"
                radius={0}
                barSize={3}
                maxBarSize={4}
              />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

       {/* Standardized Statistics Grid Footer */}
      <div className="grid grid-cols-3 gap-2 mt-2">
        <div className="rounded-lg bg-slate-50 p-2.5 text-center border border-slate-100/40">
          <p className="text-[10px] sm:text-xs text-slate-500 font-medium whitespace-nowrap">Minimum</p>
          <p className="text-xs sm:text-sm font-bold text-slate-700 mt-0.5 whitespace-nowrap">{min} L/m</p>
        </div>
        <div className="rounded-lg bg-slate-50 p-2.5 text-center border border-slate-100/40">
          <p className="text-[10px] sm:text-xs text-slate-500 font-medium whitespace-nowrap">Rata-rata</p>
          <p className="text-xs sm:text-sm font-bold text-slate-700 mt-0.5 whitespace-nowrap">{average} L/m</p>
        </div>
        <div className="rounded-lg bg-slate-50 p-2.5 text-center border border-slate-100/40">
          <p className="text-[10px] sm:text-xs text-slate-500 font-medium whitespace-nowrap">Saat Ini</p>
          <p className="text-xs sm:text-sm font-bold text-slate-700 mt-0.5 whitespace-nowrap">{latest} L/m</p>
        </div>
      </div>
    </div>
  );
}
