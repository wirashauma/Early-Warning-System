"use client";

import { useEffect, useState } from "react";
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from "recharts";
import api from "@/lib/api";

export interface FlowRateLog {
  id: string;
  sensorId: string;
  flowRate: number;
  unit: string;
  recordedAt: string;
  createdAt: string;
}

export interface AggregatedDischarge {
  year: string;
  maksimum: number;
  minimum: number;
  rataRata: number;
}

export function WaterDischargeChart() {
  const [mounted, setMounted] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [chartData, setChartData] = useState<AggregatedDischarge[]>([]);

  useEffect(() => {
    setMounted(true);
  }, []);

  useEffect(() => {
    if (!mounted) return;

    const fetchDischargeData = async () => {
      try {
        setLoading(true);
        setError(null);

        // Fetching water discharge data for Sungai Komering
        const response = await api.get("/discharge/komering");
        const logs: FlowRateLog[] = response.data?.data || [];

        if (logs.length > 0) {
          const aggregated = aggregateDischargeByYear(logs);
          setChartData(aggregated);
        } else {
          setChartData([]);
        }
      } catch (err) {
        console.error("Error fetching Komering discharge data:", err);
        setError("Gagal memuat data debit Sungai Komering.");
      } finally {
        setLoading(false);
      }
    };

    fetchDischargeData();
  }, [mounted]);

  // Helper function to process and aggregate raw API response by Year (2000 to 2010)
  const aggregateDischargeByYear = (logs: FlowRateLog[]): AggregatedDischarge[] => {
    const groups: Record<number, number[]> = {};

    logs.forEach((log) => {
      const date = new Date(log.recordedAt);
      const year = date.getFullYear();

      // Aggregate only for years 2000 to 2010
      if (year >= 2000 && year <= 2010) {
        if (!groups[year]) {
          groups[year] = [];
        }
        groups[year].push(log.flowRate);
      }
    });

    const years = Object.keys(groups).map(Number).sort((a, b) => a - b);

    return years.map((year) => {
      const rates = groups[year];
      const max = Math.max(...rates);
      const min = Math.min(...rates);
      const sum = rates.reduce((acc, curr) => acc + curr, 0);
      const avg = sum / rates.length;

      return {
        year: year.toString(),
        maksimum: parseFloat(max.toFixed(2)),
        minimum: parseFloat(min.toFixed(2)),
        rataRata: parseFloat(avg.toFixed(2)),
      };
    });
  };

  if (!mounted) {
    return <div className="h-[440px] w-full animate-pulse rounded-3xl bg-slate-50" />;
  }

  return (
    <div className="flex flex-col rounded-3xl border border-slate-100 bg-white p-6 shadow-xs transition hover:shadow-md md:p-8">
      {/* Centered Chart Title */}
      <div className="mb-6 text-center">
        <h3 className="text-xs font-bold tracking-widest text-slate-400 uppercase">
          Grafik Debit Air Tahunan
        </h3>
        <h4 className="mt-1 text-lg font-black tracking-tight text-slate-600 uppercase md:text-xl">
          DEBIT SUNGAI KOMERING TAHUN 2000-2010
        </h4>
      </div>

      {loading ? (
        <div className="flex h-[320px] flex-col items-center justify-center gap-3">
          <div className="h-8 w-8 animate-spin rounded-full border-4 border-emerald-500 border-t-transparent" />
          <p className="text-sm font-semibold text-slate-500">Memuat data real-time Komering...</p>
        </div>
      ) : error ? (
        <div className="flex h-[320px] flex-col items-center justify-center text-center">
          <div className="rounded-full bg-rose-50 p-3 text-rose-500">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              fill="none"
              viewBox="0 0 24 24"
              strokeWidth={2.5}
              stroke="currentColor"
              className="h-6 w-6"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M12 9v3.75m9-.75a9 9 0 1 1-18 0 9 9 0 0 1 18 0Zm-9 3.75h.008v.008H12v-.008Z"
              />
            </svg>
          </div>
          <p className="mt-3 text-sm font-bold text-slate-700">{error}</p>
          <p className="mt-1 text-xs text-slate-400">Silakan hubungi administrator atau coba lagi nanti.</p>
        </div>
      ) : chartData.length === 0 ? (
        <div className="flex h-[320px] flex-col items-center justify-center text-center">
          <p className="text-sm font-medium text-slate-400">Tidak ada data untuk periode 2000-2010.</p>
        </div>
      ) : (
        <div className="w-full">
          <div className="h-[320px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart
                data={chartData}
                margin={{ top: 10, right: 10, left: 15, bottom: 15 }}
              >
                {/* Background light grey fill and horizontal grid lines */}
                <CartesianGrid
                  strokeDasharray="3 3"
                  stroke="#e2e8f0"
                  vertical={false}
                  fill="#f8fafc"
                />

                <XAxis
                  dataKey="year"
                  axisLine={{ stroke: "#cbd5e1", strokeWidth: 1 }}
                  tickLine={{ stroke: "#cbd5e1" }}
                  tick={{ fill: "#64748b", fontSize: 11, fontWeight: 500 }}
                  label={{
                    value: "Tahun",
                    position: "insideBottom",
                    offset: -10,
                    fill: "#94a3b8",
                    style: { fontSize: 11, fontWeight: 700, letterSpacing: "0.05em" },
                  }}
                />

                <YAxis
                  domain={[0, 2500]}
                  ticks={[0, 500, 1000, 1500, 2000, 2500]}
                  tickFormatter={(v) => Number(v).toFixed(2)}
                  axisLine={{ stroke: "#cbd5e1", strokeWidth: 1 }}
                  tickLine={{ stroke: "#cbd5e1" }}
                  tick={{ fill: "#64748b", fontSize: 11 }}
                  label={{
                    value: "Debit (m³/det)",
                    angle: -90,
                    position: "insideLeft",
                    offset: -5,
                    fill: "#94a3b8",
                    style: {
                      fontSize: 11,
                      fontWeight: 700,
                      letterSpacing: "0.05em",
                      textAnchor: "middle",
                    },
                  }}
                />

                <Tooltip
                  content={({ active, payload }) => {
                    if (active && payload && payload.length) {
                      return (
                        <div className="rounded-2xl border border-slate-100 bg-white/95 p-4 shadow-xl backdrop-blur-xs">
                          <p className="text-xs font-bold text-slate-400 tracking-wider">
                            TAHUN {payload[0].payload.year}
                          </p>
                          <div className="mt-2 space-y-1">
                            <div className="flex items-center justify-between gap-6 text-xs">
                              <span className="font-semibold text-blue-600">Maksimum:</span>
                              <span className="font-black text-slate-700">
                                {payload[0].payload.maksimum.toFixed(2)} m³/s
                              </span>
                            </div>
                            <div className="flex items-center justify-between gap-6 text-xs">
                              <span className="font-semibold text-red-600">Minimum:</span>
                              <span className="font-black text-slate-700">
                                {payload[0].payload.minimum.toFixed(2)} m³/s
                              </span>
                            </div>
                            <div className="flex items-center justify-between gap-6 text-xs">
                              <span className="font-semibold text-emerald-600">Rata-Rata:</span>
                              <span className="font-black text-slate-700">
                                {payload[0].payload.rataRata.toFixed(2)} m³/s
                              </span>
                            </div>
                          </div>
                        </div>
                      );
                    }
                    return null;
                  }}
                />

                {/* Legend on the right side of the chart, oriented vertically */}
                <Legend
                  layout="vertical"
                  align="right"
                  verticalAlign="middle"
                  iconType="circle"
                  iconSize={8}
                  wrapperStyle={{ paddingLeft: 15 }}
                  formatter={(value) => (
                    <span className="text-xs font-semibold text-slate-600">{value}</span>
                  )}
                />

                {/* 3 Data Lines with dot markers */}
                <Line
                  type="monotone"
                  dataKey="maksimum"
                  name="Maksimum"
                  stroke="#3b82f6"
                  strokeWidth={2}
                  activeDot={{ r: 6 }}
                  dot={{ r: 4, fill: "#3b82f6" }}
                />
                <Line
                  type="monotone"
                  dataKey="minimum"
                  name="Minimum"
                  stroke="#ef4444"
                  strokeWidth={2}
                  activeDot={{ r: 6 }}
                  dot={{ r: 4, fill: "#ef4444" }}
                />
                <Line
                  type="monotone"
                  dataKey="rataRata"
                  name="Rata-Rata"
                  stroke="#10b981"
                  strokeWidth={2}
                  activeDot={{ r: 6 }}
                  dot={{ r: 4, fill: "#10b981" }}
                />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>
      )}
    </div>
  );
}
