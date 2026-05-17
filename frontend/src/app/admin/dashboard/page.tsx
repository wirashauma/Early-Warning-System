"use client";

import { useEffect, useMemo, useState, type ReactNode } from "react";
import { AdminGoogleSensorMap } from "@/components/maps/AdminGoogleSensorMap";
import { Card } from "@/components/ui/Card";
import { StatusIndicator } from "@/components/ui/StatusIndicator";
import type { Sensor } from "@/types/sensor";
import { cn, formatRelativeTime, formatTimestamp, isSensorOnline } from "@/lib/utils";
import { useWaterLevel } from "@/hooks/useWaterLevel";
import api from "@/lib/api";

function StatIcon({ children, colorClass }: { children: ReactNode; colorClass: string }) {
  return <span className={`inline-flex h-16 w-16 items-center justify-center rounded-2xl text-white shadow-md ${colorClass}`}>{children}</span>;
}

function CardTitleIcon({ children }: { children: ReactNode }) {
  return <span className="inline-flex h-5 w-5 items-center justify-center text-slate-500">{children}</span>;
}

export default function AdminDashboardPage() {
  const { sensorsSnapshot, liveBySensor, isLoading, error, reload } = useWaterLevel({ refreshMs: 12_000 });
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [activityLogs, setActivityLogs] = useState<Array<{ id: string; time: string; event: string; severity: "info" | "warning" | "critical" }>>([]);
  const [nowMs, setNowMs] = useState(() => Date.now());

  useEffect(() => {
    const timer = window.setInterval(() => setNowMs(Date.now()), 30_000);
    return () => window.clearInterval(timer);
  }, []);

  useEffect(() => {
    let cancelled = false;

    const loadActivity = async () => {
      setErrorMessage(null);
      try {
        const historyResp = await api.get("/alerts/history", { params: { page: 1, limit: 10 } });
        if (cancelled) return;

        const alertRows = (historyResp.data?.data?.items ?? []) as Array<{
          id: string;
          sentAt: string;
          title: string;
          severity: "INFO" | "WARNING" | "DANGER";
        }>;

        setActivityLogs(
          alertRows.map((item) => ({
            id: item.id,
            time: new Date(item.sentAt).toLocaleTimeString("id-ID", { hour: "2-digit", minute: "2-digit", hour12: false }),
            event: item.title,
            severity: item.severity === "DANGER" ? "critical" : item.severity === "WARNING" ? "warning" : "info",
          })),
        );
      } catch (error) {
        setErrorMessage(error instanceof Error ? error.message : "Gagal memuat dashboard admin.");
      }
    };

    void loadActivity();
    const timer = window.setInterval(() => {
      void loadActivity();
    }, 15_000);

    return () => {
      cancelled = true;
      window.clearInterval(timer);
    };
  }, []);

  const sensorState = useMemo(
    () =>
      sensorsSnapshot.map((sensor) => ({
        ...sensor,
        online: isSensorOnline(sensor.lastSeenAt ?? sensor.updatedAt, nowMs),
      })),
    [nowMs, sensorsSnapshot],
  );

  const online = sensorState.filter((sensor) => sensor.online).length;
  const offline = sensorState.length - online;
  const warningCount = sensorState.filter((sensor) => sensor.status === "alert").length;
  const dangerCount = sensorState.filter((sensor) => sensor.status === "danger").length;
  const maxLevelCm = sensorState.length ? Math.max(...sensorState.map((sensor) => sensor.lastLevelCm)) : 0;
  const avgRainfall = liveBySensor.length ? Math.round((liveBySensor.reduce((sum, sensor) => sum + sensor.rainfallMm, 0) / liveBySensor.length) * 10) / 10 : 0;
  const globalStatus = sensorState.some((sensor) => sensor.status === "danger")
    ? "Bahaya"
    : sensorState.some((sensor) => sensor.status === "alert")
      ? "Waspada"
      : "Aman";

  const severityClass: Record<"info" | "warning" | "critical", string> = {
    info: "bg-blue-100 text-blue-700",
    warning: "bg-amber-100 text-amber-700",
    critical: "bg-rose-100 text-rose-700",
  };

  const severityLabel: Record<"info" | "warning" | "critical", string> = {
    info: "Info",
    warning: "Warning",
    critical: "Critical",
  };

  const stats = [
    {
      title: "Sensor Aktif",
      value: online,
      sub: `Total sensor: ${sensorState.length}`,
      color: "from-blue-500 to-indigo-500",
      icon: (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-7 w-7" aria-hidden="true">
          <circle cx="12" cy="12" r="2.2" />
          <path strokeLinecap="round" d="M12 4v2.2M12 17.8V20M4 12h2.2M17.8 12H20M6.7 6.7l1.5 1.5M15.8 15.8l1.5 1.5M17.3 6.7l-1.5 1.5M8.2 15.8l-1.5 1.5" />
        </svg>
      ),
    },
    {
      title: "Status Waspada",
      value: warningCount,
      sub: "Sensor dalam status alert",
      color: "from-amber-500 to-orange-500",
      icon: (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-7 w-7" aria-hidden="true">
          <path strokeLinecap="round" strokeLinejoin="round" d="M12 3.5l8.5 15H3.5L12 3.5z" />
          <path strokeLinecap="round" d="M12 9.5v4" />
          <circle cx="12" cy="16.2" r="1" fill="currentColor" stroke="none" />
        </svg>
      ),
    },
    {
      title: "Status Bahaya",
      value: dangerCount,
      sub: "Perlu respons segera",
      color: "from-rose-500 to-pink-500",
      icon: (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-7 w-7" aria-hidden="true">
          <path strokeLinecap="round" strokeLinejoin="round" d="M12 4a5 5 0 00-5 5v2.4c0 .8-.3 1.6-.8 2.2L5 15.5h14l-1.2-1.9a3.5 3.5 0 01-.8-2.2V9a5 5 0 00-5-5z" />
          <path strokeLinecap="round" d="M10.2 18a2 2 0 003.6 0" />
        </svg>
      ),
    },
    {
      title: "Curah Hujan",
      value: `${avgRainfall} mm/jam`,
      sub: "Rata-rata sensor aktif",
      color: "from-cyan-500 to-sky-500",
      icon: (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-7 w-7" aria-hidden="true">
          <path strokeLinecap="round" strokeLinejoin="round" d="M7 10a5 5 0 019.7-1.8A4 4 0 0117 16H7a3 3 0 010-6z" />
          <path strokeLinecap="round" d="M9 18l1 2M13 18l1 2M17 18l1 2" />
        </svg>
      ),
    },
    {
      title: "Puncak Tinggi Air",
      value: `${maxLevelCm} cm`,
      sub: "Pembacaan tertinggi saat ini",
      color: "from-emerald-500 to-teal-500",
      icon: (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-7 w-7" aria-hidden="true">
          <path strokeLinecap="round" strokeLinejoin="round" d="M4 15c2.4-2.2 5.2-2.2 7.6 0s5.2 2.2 7.6 0" />
          <path strokeLinecap="round" strokeLinejoin="round" d="M4 19c2.4-2.2 5.2-2.2 7.6 0s5.2 2.2 7.6 0" />
          <path strokeLinecap="round" d="M12 5v7" />
        </svg>
      ),
    },
    {
      title: "Sensor Offline",
      value: offline,
      sub: "Perlu pengecekan perangkat",
      color: "from-violet-500 to-purple-500",
      icon: (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-7 w-7" aria-hidden="true">
          <path strokeLinecap="round" d="M6 9a9 9 0 0112 0" />
          <path strokeLinecap="round" d="M8.5 12a5.5 5.5 0 017 0" />
          <circle cx="12" cy="16" r="1.2" fill="currentColor" stroke="none" />
          <path strokeLinecap="round" d="M3 3l18 18" />
        </svg>
      ),
    },
  ] as const;

  return (
    <main className="space-y-6">
      <Card className="relative overflow-hidden border-blue-500/30 bg-linear-to-r from-blue-600 via-blue-600 to-cyan-600 text-white shadow-lg shadow-blue-900/20">
        <div className="absolute -right-2 top-4 h-24 w-24 rounded-3xl border border-white/20 bg-white/10" />
        <div className="relative z-10 space-y-1.5">
          <h1 className="text-3xl font-bold tracking-tight">Selamat Datang! 👋</h1>
          <p className="max-w-2xl text-sm text-blue-50/95 md:text-base">
            Ringkasan cepat kondisi sistem Early Warning System untuk membantu tim merespons perubahan level air lebih sigap.
          </p>
          <p className="text-xs font-semibold text-blue-100/95 md:text-sm">
            Status global saat ini:
            <span
              className={`ml-1.5 rounded-full px-2.5 py-1 ${
                globalStatus === "Bahaya"
                  ? "bg-rose-500/20 text-rose-100"
                  : globalStatus === "Waspada"
                    ? "bg-amber-500/20 text-amber-100"
                    : "bg-emerald-500/20 text-emerald-100"
              }`}
            >
              {globalStatus}
            </span>
          </p>
          <div className="mt-4 inline-flex items-center gap-2 rounded-xl border border-white/25 bg-white/12 px-3 py-1.5 text-xs font-semibold text-blue-50">
            <CardTitleIcon>
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-4 w-4" aria-hidden="true">
                <rect x="3" y="4" width="18" height="17" rx="3" />
                <path strokeLinecap="round" d="M8 2.8v2.4M16 2.8v2.4M3 9h18" />
              </svg>
            </CardTitleIcon>
            Periode Pemantauan Aktif
          </div>
        </div>
      </Card>

      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        {stats.map((item) => (
          <Card key={item.title} className="border-slate-200 bg-white/80 shadow-sm backdrop-blur-xl">
            <div className="flex items-center justify-between gap-3">
              <div>
                <p className="text-sm font-medium text-slate-500">{item.title}</p>
                <p className="mt-1 text-4xl font-bold tracking-tight text-slate-900">{item.value}</p>
                <p className="mt-1 text-sm text-slate-500">{item.sub}</p>
              </div>
              <StatIcon colorClass={`bg-linear-to-br ${item.color}`}>{item.icon}</StatIcon>
            </div>
          </Card>
        ))}
      </div>

      <Card className="border-slate-200 bg-white/80 shadow-md shadow-slate-200/40 backdrop-blur-xl">
        <div className="mb-4 flex items-center justify-between gap-3">
          <div>
            <h2 className="text-lg font-semibold text-slate-900">Sensor Terkini</h2>
            <p className="text-sm text-slate-500">Terakhir update, koneksi, dan ketinggian air terbaru.</p>
          </div>
          <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">Polling 12 detik</span>
        </div>

        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
          {sensorState.slice(0, 4).map((sensor) => (
            <div key={sensor.id} className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm">
              <div className="flex items-start justify-between gap-3">
                <div>
                  <p className="text-base font-semibold text-slate-900">{sensor.name}</p>
                  <p className="text-xs text-slate-500">{sensor.riverName}</p>
                </div>
                <span className={cn("inline-flex items-center gap-2 rounded-full border px-2.5 py-1 text-xs font-semibold", sensor.online ? "border-emerald-200 bg-emerald-50 text-emerald-700" : "border-slate-200 bg-slate-100 text-slate-600")}>
                  <span className="relative inline-flex h-3 w-3">
                    {sensor.online && <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-emerald-400 opacity-75" />}
                    <span className={cn("relative inline-flex h-3 w-3 rounded-full", sensor.online ? "bg-emerald-500" : "bg-slate-400")} />
                  </span>
                  {sensor.online ? "Online" : "Offline"}
                </span>
              </div>

              <div className="mt-3 grid grid-cols-2 gap-2 text-sm">
                <div className="rounded-lg bg-slate-50 p-3">
                  <p className="text-xs text-slate-500">Ketinggian Air</p>
                  {sensor.hasWaterLevelData ? (
                    <p className="mt-1 font-semibold text-slate-900">{sensor.lastLevelCm.toFixed(1)} cm</p>
                  ) : (
                    <span className="mt-1 inline-flex rounded-full bg-slate-100 px-2 py-1 text-xs font-semibold text-slate-500">Menunggu Data</span>
                  )}
                </div>
                <div className="rounded-lg bg-slate-50 p-3">
                  <p className="text-xs text-slate-500">Baterai</p>
                  <p className="mt-1 font-semibold text-slate-900">{sensor.batteryPercent}%</p>
                </div>
              </div>

              <div className="mt-3 text-xs text-slate-500">
                Terakhir Update: <span className="font-semibold text-slate-700">{formatRelativeTime(sensor.lastSeenAt ?? sensor.updatedAt, nowMs)}</span>
                <div className="mt-1">{formatTimestamp(sensor.lastSeenAt ?? sensor.updatedAt)}</div>
              </div>
            </div>
          ))}
        </div>
      </Card>

      <Card className="border-slate-200 bg-white/80 shadow-md shadow-slate-200/40 backdrop-blur-xl">
        <div className="mb-4 flex items-center justify-between gap-3">
          <div>
            <h2 className="text-lg font-semibold text-slate-900">Peta Interaktif Sensor</h2>
            <p className="text-sm text-slate-500">Klik titik sensor untuk melihat lokasi, ketinggian air, dan status baterai.</p>
          </div>
          <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">
            Total {sensorState.length} Sensor
          </span>
        </div>

        <AdminGoogleSensorMap sensors={sensorState} />
      </Card>

      <Card className="border-slate-200 bg-white/80 shadow-md shadow-slate-200/40 backdrop-blur-xl">
        <div className="mb-4 flex items-center justify-between gap-3">
          <div>
            <h2 className="text-lg font-semibold text-slate-900">Log Aktivitas Terkini</h2>
            <p className="text-sm text-slate-500">Pemantauan kejadian terbaru untuk respons cepat.</p>
          </div>
          <span className="rounded-full bg-blue-50 px-3 py-1 text-xs font-semibold text-blue-700">
            Update: {formatTimestamp(new Date().toISOString())}
          </span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full min-w-160 text-left text-sm">
            <thead>
              <tr className="border-b border-slate-200 text-slate-500">
                <th className="py-2">Waktu (HH:MM)</th>
                <th className="py-2">Kejadian</th>
                <th className="py-2">Tingkat Keparahan</th>
              </tr>
            </thead>
            <tbody>
              {activityLogs.map((item) => (
                <tr key={item.id} className="border-b border-slate-100 align-top">
                  <td className="py-3 font-medium text-slate-700">{item.time}</td>
                  <td className="py-3 text-slate-700">{item.event}</td>
                  <td className="py-3">
                    <span className={`inline-flex rounded-full px-2.5 py-1 text-xs font-semibold ${severityClass[item.severity]}`}>
                      {severityLabel[item.severity]}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>

      {(isLoading || error || errorMessage) && (
        <div className="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-slate-200 bg-white/90 px-4 py-3 shadow-sm">
          <div>
            <p className="text-sm font-semibold text-slate-700">Status Sinkronisasi</p>
            <p className="text-xs text-slate-500">{isLoading ? "Memuat data sensor terbaru..." : error || errorMessage || "Dashboard sinkron"}</p>
          </div>
          {(error || errorMessage) && (
            <button type="button" onClick={() => reload()} className="rounded-lg border border-slate-200 bg-white px-3 py-2 text-xs font-semibold text-slate-700 hover:bg-slate-50">
              Coba Lagi
            </button>
          )}
        </div>
      )}
    </main>
  );
}
