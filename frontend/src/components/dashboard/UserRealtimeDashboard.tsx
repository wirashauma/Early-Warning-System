"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { RainfallCard } from "@/components/dashboard/RainfallCard";
import { WaterLevelGauge } from "@/components/dashboard/WaterLevelGauge";
import { WaterLevelChart } from "@/components/charts/WaterLevelChart";
import { RainfallChart } from "@/components/charts/RainfallChart";
import { FlowSpeedChart } from "@/components/charts/FlowSpeedChart";
import { StatusIndicator } from "@/components/ui/StatusIndicator";
import { useWaterLevel } from "@/hooks/useWaterLevel";
import { useFlowRate } from "@/hooks/useFlowRate";
import { cn, getRainfallCategory, formatRelativeTime, formatTimestamp, isSensorOnline } from "@/lib/utils";
import type { WaterStatus } from "@/types/water-level";

interface UserRealtimeDashboardProps {
  headline: string;
  subtitle?: string;
  roleLabel?: string;
}

const statusRank: Record<WaterStatus, number> = {
  safe: 0,
  warning: 1,
  alert: 2,
  danger: 3,
};

const statusMeta: Record<
  WaterStatus,
  {
    label: string;
    summary: string;
    panelClass: string;
    dotClass: string;
    heroClass: string;
    actions: string[];
  }
> = {
  safe: {
    label: "Normal",
    summary: "Situasi saat ini aman. Tetap pantau dashboard secara berkala.",
    panelClass: "border-emerald-100 bg-emerald-50 text-emerald-900",
    dotClass: "bg-emerald-500",
    heroClass: "bg-emerald-500 shadow-emerald-500/20",
    actions: [
      "Pantau pembaruan level air setiap 30 menit.",
      "Pastikan notifikasi perangkat tetap aktif.",
      "Simpan jalur evakuasi sebagai antisipasi.",
    ],
  },
  warning: {
    label: "Waspada",
    summary: "Terjadi kenaikan air, siapkan perlengkapan dan rencana evakuasi.",
    panelClass: "border-amber-100 bg-amber-50 text-amber-900",
    dotClass: "bg-amber-500",
    heroClass: "bg-amber-500 shadow-amber-500/20",
    actions: [
      "Pantau dashboard tiap 10-15 menit.",
      "Siapkan tas siaga dan dokumen penting.",
      "Prioritaskan kesiapan anggota keluarga rentan.",
    ],
  },
  alert: {
    label: "Siaga",
    summary: "Kondisi mendekati bahaya, amankan barang berharga dan bersiap evakuasi.",
    panelClass: "border-orange-100 bg-orange-50 text-orange-900",
    dotClass: "bg-orange-500",
    heroClass: "bg-orange-500 shadow-orange-500/20",
    actions: [
      "Amankan barang berharga ke tempat yang lebih tinggi.",
      "Pantau instruksi evakuasi dari petugas lapangan.",
      "Siapkan kendaraan dan rute evakuasi yang aman.",
    ],
  },
  danger: {
    label: "Bahaya",
    summary: "Kondisi kritis! Prioritaskan keselamatan jiwa dan evakuasi segera.",
    panelClass: "border-rose-100 bg-rose-50 text-rose-900",
    dotClass: "bg-rose-500",
    heroClass: "bg-rose-500 shadow-rose-500/30 animate-in fade-in duration-500",
    actions: [
      "Lakukan evakuasi ke titik aman resmi segera.",
      "Hubungi layanan darurat jika akses terputus.",
      "Ikuti arahan petugas dan hindari arus banjir.",
    ],
  },
};

export function UserRealtimeDashboard({ headline, subtitle, roleLabel }: UserRealtimeDashboardProps) {
  const pathname = usePathname();
  const isUserRoute = pathname.startsWith("/user");
  const [selectedSensorId, setSelectedSensorId] = useState("");
  const { latest, history, sensorsSnapshot, liveBySensor } = useWaterLevel({ sensorId: selectedSensorId, refreshMs: 12_000, showAll: true });
  const { history: flowHistory } = useFlowRate();
  const [nowMs, setNowMs] = useState(() => Date.now());

  useEffect(() => {
    const timer = window.setInterval(() => setNowMs(Date.now()), 30_000);
    return () => window.clearInterval(timer);
  }, []);

  const sensorState = useMemo(
    () =>
      sensorsSnapshot.map((sensor) => ({
        ...sensor,
        online: isSensorOnline(sensor.lastSeenAt ?? sensor.updatedAt, nowMs),
      })),
    [nowMs, sensorsSnapshot],
  );

  const sortedSensors = useMemo(
    () => [...liveBySensor].sort((a, b) => statusRank[b.status] - statusRank[a.status] || b.levelCm - a.levelCm),
    [liveBySensor],
  );

  const overallStatus = sortedSensors[0]?.status ?? latest.status;
  const dangerCount = liveBySensor.filter((sensor) => sensor.status === "danger").length;
  const alertCount = liveBySensor.filter((sensor) => sensor.status === "alert").length;
  const warningCount = liveBySensor.filter((sensor) => sensor.status === "warning").length;

  const selectableSensors = useMemo(
    () => sensorState.filter((sensor) => sensor.type !== "FLOW_RATE"),
    [sensorState],
  );

  const selectedSensor = useMemo(
    () => selectableSensors.find((sensor) => sensor.id === latest.sensorId) ?? selectableSensors[0],
    [latest.sensorId, selectableSensors],
  );

  const selectedSensorOnline = selectedSensor ? isSensorOnline(selectedSensor.lastSeenAt ?? selectedSensor.updatedAt, nowMs) : false;
  const selectedSensorHasData = selectedSensor?.hasWaterLevelData ?? true;
  const selectedSensorLevel = selectedSensorHasData ? latest.levelCm : null;
  const selectedSensorLastSeen = selectedSensor?.lastSeenAt ?? selectedSensor?.updatedAt ?? latest.updatedAt;

  const rainfallCategory = getRainfallCategory(latest.rainfallMm);
  const onlineCount = sensorState.filter((sensor) => sensor.online).length;
  const activeMeta = statusMeta[latest.status];
  const globalMeta = statusMeta[overallStatus];

  const routeLinks = {
    map: isUserRoute ? "/user/map" : "/map",
    emergency: isUserRoute ? "/user/emergency" : "/emergency",
    education: isUserRoute ? "/user/education" : "/education",
  };

  return (
    <div className="min-h-screen bg-slate-50/50 pb-20">
      <main className="mx-auto w-full max-w-6xl px-5 pt-8 md:px-8">
        
        {/* HEADER */}
        <header className="mb-6">
          {roleLabel && (
            <div className="mb-3 inline-flex items-center rounded-full bg-blue-100 px-3 py-1 text-xs font-bold uppercase tracking-wider text-blue-700">
              {roleLabel}
            </div>
          )}
          <h1 className="text-3xl font-extrabold tracking-tight text-slate-900 md:text-4xl">{headline}</h1>
          {subtitle && <p className="mt-2 text-base text-slate-600">{subtitle}</p>}
        </header>

        {/* 1. HERO BANNER - SANGAT JELAS UNTUK ORANG AWAM */}
        <section className={cn("relative mb-8 flex flex-col justify-between gap-4 overflow-hidden rounded-3xl px-6 py-8 text-white shadow-xl md:flex-row md:items-center md:px-10", globalMeta.heroClass)}>
          <div className="absolute -right-10 -top-10 opacity-10">
            <svg viewBox="0 0 24 24" fill="currentColor" className="h-56 w-56">
              <path d="M12 2L1 21h22L12 2zm0 3.83L19.13 19H4.87L12 5.83zM11 10v5h2v-5h-2zm0 6v2h2v-2h-2z" />
            </svg>
          </div>
          <div className="relative z-10">
            <p className="text-sm font-medium text-white/80 uppercase tracking-widest">Status Keseluruhan Wilayah</p>
            <div className="mt-2 flex items-center gap-3">
              {overallStatus !== 'safe' && (
                <span className="flex h-4 w-4 rounded-full bg-white animate-pulse shadow-[0_0_15px_rgba(255,255,255,0.8)]"></span>
              )}
              <h2 className="text-4xl font-black tracking-wide">{globalMeta.label.toUpperCase()}</h2>
            </div>
          </div>
          <div className="relative z-10 text-left md:text-right bg-black/10 rounded-2xl p-4 backdrop-blur-sm">
            <p className="text-sm font-medium text-white/80">Terakhir Update</p>
            <p className="text-lg font-bold">{formatTimestamp(latest.updatedAt)}</p>
          </div>
        </section>

        {/* 2. STATISTIK CEPAT */}
        <section className="mb-8 grid grid-cols-2 gap-4 lg:grid-cols-4 lg:gap-5">
          {/* Water Level */}
          <div className="relative overflow-hidden rounded-2xl bg-white p-5 shadow-sm ring-1 ring-slate-100 transition-shadow hover:shadow-md">
            <div className="absolute left-0 top-0 bottom-0 w-1 rounded-l-2xl bg-emerald-500" />
            <div className="flex items-center gap-2 mb-2">
              <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-emerald-50">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-4 w-4 text-emerald-600">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M12 21.5c-3.04 0-5.5-2.24-5.5-5 0-3.08 3.63-7.78 4.82-9.26a.88.88 0 011.36 0C13.87 8.72 17.5 13.42 17.5 16.5c0 2.76-2.46 5-5.5 5z" />
                </svg>
              </div>
              <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Tinggi Air</p>
            </div>
            {selectedSensorHasData ? (
              <p className="text-2xl font-extrabold text-slate-900 transition-all duration-300">{latest.levelCm} <span className="text-sm font-medium text-slate-400">cm</span></p>
            ) : (
              <span className="inline-flex rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-500">Menunggu Data</span>
            )}
            <p className="mt-1.5 text-[11px] text-slate-400 truncate">{selectedSensor?.name ?? latest.sensorName}</p>
          </div>

          {/* Rainfall */}
          <div className="relative overflow-hidden rounded-2xl bg-white p-5 shadow-sm ring-1 ring-slate-100 transition-shadow hover:shadow-md">
            <div className="absolute left-0 top-0 bottom-0 w-1 rounded-l-2xl bg-cyan-500" />
            <div className="flex items-center gap-2 mb-2">
              <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-cyan-50">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-4 w-4 text-cyan-600">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M2 12h2m4-7l1 1m7-1l-1 1m5 5h2M6.34 17.66l1.41-1.41M17.66 17.66l-1.41-1.41M12 2v2m0 16v2m5-9a5 5 0 11-10 0 5 5 0 0110 0z" />
                </svg>
              </div>
              <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Curah Hujan</p>
            </div>
            <p className="text-2xl font-extrabold text-slate-900 transition-all duration-300">{latest.rainfallMm} <span className="text-sm font-medium text-slate-400">mm/j</span></p>
            <p className="mt-1.5 text-[11px] text-slate-400 truncate">{rainfallCategory.label}</p>
          </div>

          {/* Sensors at Risk */}
          <div className="relative overflow-hidden rounded-2xl bg-white p-5 shadow-sm ring-1 ring-slate-100 transition-shadow hover:shadow-md">
            <div className={cn("absolute left-0 top-0 bottom-0 w-1 rounded-l-2xl", dangerCount > 0 ? "bg-rose-500" : alertCount > 0 ? "bg-orange-500" : warningCount > 0 ? "bg-amber-500" : "bg-emerald-500")} />
            <div className="flex items-center gap-2 mb-2">
              <div className={cn("flex h-8 w-8 items-center justify-center rounded-lg", dangerCount > 0 ? "bg-rose-50" : "bg-slate-50")}>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className={cn("h-4 w-4", dangerCount > 0 ? "text-rose-600" : "text-slate-500")}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z" />
                </svg>
              </div>
              <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Berisiko</p>
            </div>
            <p className="text-2xl font-extrabold text-slate-900">{dangerCount + alertCount + warningCount}</p>
            <div className="mt-1.5 flex items-center gap-2 text-[11px] text-slate-400">
              {dangerCount > 0 && <span className="flex items-center gap-0.5"><span className="inline-block h-1.5 w-1.5 rounded-full bg-rose-500" />{dangerCount}</span>}
              {alertCount > 0 && <span className="flex items-center gap-0.5"><span className="inline-block h-1.5 w-1.5 rounded-full bg-orange-500" />{alertCount}</span>}
              {warningCount > 0 && <span className="flex items-center gap-0.5"><span className="inline-block h-1.5 w-1.5 rounded-full bg-amber-500" />{warningCount}</span>}
              {dangerCount === 0 && alertCount === 0 && warningCount === 0 && <span>Semua aman</span>}
            </div>
          </div>

          {/* Connectivity */}
          <div className="relative overflow-hidden rounded-2xl bg-white p-5 shadow-sm ring-1 ring-slate-100 transition-shadow hover:shadow-md">
            <div className={cn("absolute left-0 top-0 bottom-0 w-1 rounded-l-2xl", onlineCount === sensorsSnapshot.length ? "bg-emerald-500" : "bg-amber-500")} />
            <div className="flex items-center gap-2 mb-2">
              <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-emerald-50">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-4 w-4 text-emerald-600">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M8.288 15.038a5.25 5.25 0 017.424 0M5.106 11.856c3.807-3.808 9.98-3.808 13.788 0M1.924 8.674c5.565-5.565 14.587-5.565 20.152 0M12.53 18.22l-.53.53-.53-.53a.75.75 0 011.06 0z" />
                </svg>
              </div>
              <p className="text-xs font-semibold text-slate-400 uppercase tracking-wider">Konektivitas</p>
            </div>
            <p className="text-2xl font-extrabold text-slate-900">{onlineCount}<span className="text-sm font-medium text-slate-400">/{sensorsSnapshot.length}</span></p>
            <p className="mt-1.5 text-[11px] text-slate-400">Sensor online aktif</p>
          </div>
        </section>

        {/* 3. MAIN SPLIT LAYOUT (2/3 Kiri, 1/3 Kanan) */}
        <div className="mb-8 grid grid-cols-1 gap-6 lg:grid-cols-3 lg:gap-8">
          
          {/* KOLOM KIRI: Detail Sensor & Rekomendasi */}
          <section className="flex flex-col gap-6 lg:col-span-2">
            <div className="rounded-3xl bg-white p-6 shadow-sm ring-1 ring-slate-100 md:p-8">
              
              {/* Header Pilihan Sensor */}
              <div className="flex flex-col gap-4 border-b border-slate-100 pb-6 md:flex-row md:items-center md:justify-between">
                <div>
                  <h3 className="text-xl font-bold text-slate-900">Monitor Sensor Spesifik</h3>
                  <p className="mt-1 text-sm text-slate-500">Pilih area untuk melihat detail metrik.</p>
                </div>
                <div className="relative">
                  <select
                    value={latest.sensorId}
                    onChange={(event) => setSelectedSensorId(event.target.value)}
                    className="w-full appearance-none rounded-xl border-0 bg-slate-100 py-3 pl-4 pr-10 text-sm font-semibold text-slate-700 ring-1 ring-inset ring-slate-200 focus:ring-2 focus:ring-inset focus:ring-blue-600 md:w-64"
                  >
                    {selectableSensors.map((sensor) => (
                      <option key={sensor.id} value={sensor.id}>
                        {sensor.name} ({sensor.riverName})
                      </option>
                    ))}
                  </select>
                  <div className="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-3">
                    <svg className="h-5 w-5 text-slate-400" viewBox="0 0 20 20" fill="currentColor">
                      <path fillRule="evenodd" d="M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z" clipRule="evenodd" />
                    </svg>
                  </div>
                </div>
              </div>

              {/* Status Spesifik Sensor */}
              <div className="mt-6 grid grid-cols-2 gap-5 md:grid-cols-4">
                <div className="rounded-2xl bg-white p-5 text-center shadow-sm ring-1 ring-slate-100">
                  <p className="text-[11px] font-bold uppercase tracking-widest text-slate-400 mb-3">Status</p>
                  <div className="flex justify-center">
                    <StatusIndicator status={latest.status} size="md" />
                  </div>
                </div>
                <div className="rounded-2xl bg-white p-5 text-center shadow-sm ring-1 ring-slate-100">
                  <p className="text-[11px] font-bold uppercase tracking-widest text-slate-400 mb-3">Tinggi Air</p>
                  {selectedSensorHasData ? (
                    <p className="text-2xl font-extrabold text-slate-800 transition-all duration-300">{latest.levelCm} <span className="text-xs font-medium text-slate-400">cm</span></p>
                  ) : (
                    <span className="inline-flex rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-500">Menunggu Data</span>
                  )}
                </div>
                <div className="rounded-2xl bg-white p-5 text-center shadow-sm ring-1 ring-slate-100">
                  <p className="text-[11px] font-bold uppercase tracking-widest text-slate-400 mb-3">Koneksi</p>
                  <div className="flex items-center justify-center gap-2">
                    <span className={cn("relative inline-flex h-3 w-3")}>{selectedSensorOnline ? <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-emerald-400 opacity-75" /> : null}<span className={cn("relative inline-flex h-3 w-3 rounded-full", selectedSensorOnline ? "bg-emerald-500" : "bg-slate-300")} /></span>
                    <p className={cn("text-lg font-bold", selectedSensorOnline ? "text-emerald-600" : "text-slate-500")}>{selectedSensorOnline ? "Online" : "Offline"}</p>
                  </div>
                </div>
                <div className="rounded-2xl bg-white p-5 text-center shadow-sm ring-1 ring-slate-100">
                  <p className="text-[11px] font-bold uppercase tracking-widest text-slate-400 mb-3">Baterai</p>
                  <p className="text-2xl font-extrabold text-slate-800">{selectedSensor?.batteryPercent ?? 0}<span className="text-xs font-medium text-slate-400">%</span></p>
                </div>
              </div>

              <div className="mt-5 flex flex-wrap items-center justify-between gap-2 rounded-2xl bg-slate-50 px-4 py-3 text-sm text-slate-600">
                <span>
                  Terakhir Update: <span className="font-semibold text-slate-800">{formatRelativeTime(selectedSensorLastSeen, nowMs)}</span>
                </span>
                <span className="text-xs text-slate-400">{formatTimestamp(selectedSensorLastSeen)}</span>
              </div>

              {/* Kotak Rekomendasi (Warna Menyesuaikan Status) */}
              <div className={cn("mt-8 rounded-2xl p-6 ring-1", activeMeta.panelClass)}>
                <h4 className="flex items-center gap-2 text-base font-bold">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" className="h-5 w-5">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                  Tindakan yang Disarankan
                </h4>
                <p className="mt-2 text-sm font-medium">{activeMeta.summary}</p>
                <ul className="mt-4 flex flex-col gap-2">
                  {activeMeta.actions.map((item) => (
                    <li key={item} className="flex items-start gap-2 text-sm">
                      <span className="mt-1 flex h-1.5 w-1.5 shrink-0 rounded-full bg-current opacity-60"></span>
                      <span className="opacity-90">{item}</span>
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          </section>

          {/* KOLOM KANAN: Aksi Cepat & Prioritas */}
          <aside className="flex flex-col gap-6">
            <div className="rounded-3xl bg-white p-6 shadow-sm ring-1 ring-slate-100">
              <h3 className="text-lg font-bold text-slate-900">Aksi Darurat & Pintasan</h3>
              <p className="mb-6 mt-1 text-sm text-slate-500">Akses cepat menu penting.</p>
              
              <div className="flex flex-col gap-3">
                <Link
                  href={routeLinks.emergency}
                  className="group flex w-full items-center justify-between rounded-xl bg-rose-600 px-5 py-3.5 text-sm font-bold text-white shadow-md shadow-rose-500/20 transition-all hover:bg-rose-700 hover:shadow-lg hover:shadow-rose-500/30"
                >
                  Kontak Darurat
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-5 w-5 transition-transform group-hover:translate-x-1">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                  </svg>
                </Link>
                <Link
                  href={routeLinks.map}
                  className="flex w-full items-center justify-between rounded-xl bg-slate-50 px-5 py-3.5 text-sm font-semibold text-slate-700 ring-1 ring-slate-200 transition-all hover:bg-slate-100 hover:text-blue-600"
                >
                  Buka Peta Sensor
                  <span>→</span>
                </Link>
                <Link
                  href={routeLinks.education}
                  className="flex w-full items-center justify-between rounded-xl bg-slate-50 px-5 py-3.5 text-sm font-semibold text-slate-700 ring-1 ring-slate-200 transition-all hover:bg-slate-100 hover:text-blue-600"
                >
                  Panduan Mitigasi
                  <span>→</span>
                </Link>
              </div>
            </div>

            {/* Kotak Sensor Prioritas */}
            <div className="rounded-3xl bg-blue-50 p-6 ring-1 ring-blue-100">
              <div className="mb-4 flex items-center gap-2">
                <div className="flex h-8 w-8 items-center justify-center rounded-full bg-blue-200/50">
                  <svg className="h-4 w-4 text-blue-700" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                    <path strokeLinecap="round" strokeLinejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                  </svg>
                </div>
                <h3 className="font-bold text-blue-900">Pantauan Prioritas</h3>
              </div>
              <div className="rounded-2xl bg-white p-4 shadow-sm">
                <p className="font-bold text-slate-900">{sortedSensors[0]?.sensorName ?? latest.sensorName}</p>
                <p className="mt-1 text-sm font-semibold text-rose-600">{sortedSensors[0]?.levelCm ?? latest.levelCm} cm • {statusMeta[sortedSensors[0]?.status ?? latest.status].label}</p>
                <p className="mt-2 text-xs leading-relaxed text-slate-500">Sensor ini menunjukkan level risiko tertinggi saat ini. Fokuskan perhatian Anda di area ini.</p>
              </div>
            </div>
          </aside>
        </div>

        {/* 4. DAFTAR SEMUA SENSOR */}
        <section className="mb-8 rounded-3xl bg-white p-6 shadow-sm ring-1 ring-slate-100 md:p-8">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="text-lg font-bold text-slate-900">Daftar Pantauan Semua Wilayah</h3>
              <p className="mt-1 text-sm text-slate-500">Diurutkan otomatis dari wilayah paling berisiko.</p>
            </div>
            <span className="hidden sm:inline-flex items-center gap-1.5 rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-500">
              <span className="inline-block h-2 w-2 rounded-full bg-emerald-500" />
              {onlineCount} online
            </span>
          </div>
          
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
            {sortedSensors.map((item) => {
              const sensor = sensorState.find((entry) => entry.id === item.sensorId);
              const online = sensor ? isSensorOnline(sensor.lastSeenAt ?? sensor.updatedAt, nowMs) : false;
              const hasData = sensor?.hasWaterLevelData ?? true;

              return (
              <div key={item.sensorId} className={cn("group relative overflow-hidden rounded-2xl bg-white p-5 ring-1 transition-all duration-200 hover:shadow-md", online ? "ring-slate-200 hover:ring-slate-300" : "ring-slate-200 opacity-70")}>
                {/* Top: Name + Status */}
                <div className="flex items-start justify-between gap-3 mb-4">
                  <div className="min-w-0">
                    <p className="font-bold text-slate-800 truncate">{item.sensorName}</p>
                    <p className="text-[11px] text-slate-400 mt-0.5 truncate">{item.sensorId}</p>
                  </div>
                  <StatusIndicator status={item.status} />
                </div>

                {/* Metrics */}
                <div className="grid grid-cols-2 gap-3 mb-4">
                  <div className="rounded-xl bg-slate-50 p-3">
                    <p className="text-[10px] font-semibold text-slate-400 uppercase tracking-wider mb-1">Tinggi Air</p>
                    {hasData ? <p className="text-base font-bold text-slate-800">{item.levelCm} <span className="text-[10px] font-medium text-slate-400">cm</span></p> : <span className="inline-flex rounded-full bg-white px-2 py-0.5 text-[10px] font-semibold text-slate-400">Menunggu</span>}
                  </div>
                  <div className="rounded-xl bg-slate-50 p-3">
                    <p className="text-[10px] font-semibold text-slate-400 uppercase tracking-wider mb-1">Curah Hujan</p>
                    <p className="text-base font-bold text-slate-800">{item.rainfallMm} <span className="text-[10px] font-medium text-slate-400">mm</span></p>
                  </div>
                </div>

                {/* Footer: Online + Last Update */}
                <div className="flex items-center justify-between pt-3 border-t border-slate-100">
                  <span className={cn("inline-flex items-center gap-1.5 text-xs font-semibold", online ? "text-emerald-600" : "text-slate-400")}>
                    <span className="relative inline-flex">
                      {online && <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-emerald-400 opacity-60" />}
                      <span className={cn("relative inline-block h-2 w-2 rounded-full", online ? "bg-emerald-500" : "bg-slate-300")} />
                    </span>
                    {online ? "Online" : "Offline"}
                  </span>
                  <span className="text-[11px] text-slate-400">{formatRelativeTime(sensor?.lastSeenAt ?? item.updatedAt, nowMs)}</span>
                </div>
              </div>
            );})}
          </div>
        </section>

        {/* 5. VISUALISASI ANALITIK (Grafik & Gauge) */}
        <section className="rounded-3xl bg-slate-100/50 p-6 md:p-8 ring-1 ring-slate-200/50">
          <div className="mb-6">
            <h3 className="text-xl font-bold text-slate-900">Visualisasi & Grafik Historis</h3>
            <p className="text-sm text-slate-500">Analisis tren ketinggian air dan cuaca untuk pengambilan keputusan.</p>
          </div>
          
          <div className="grid gap-6 lg:grid-cols-3">
            {/* Gauge Indicator */}
            <div className="flex flex-col justify-between rounded-2xl bg-white p-6 shadow-sm ring-1 ring-slate-100 lg:col-span-1">
              <WaterLevelGauge levelCm={latest.levelCm} status={latest.status} />
              <div className="mt-4 rounded-xl bg-slate-50 p-3 text-center">
                <p className="text-xs font-medium text-slate-500">Kapasitas Maksimal: 400cm</p>
              </div>
            </div>

            {/* Rainfall Widget */}
            <div className="rounded-2xl bg-white p-6 shadow-sm ring-1 ring-slate-100 lg:col-span-2">
              <RainfallCard rainfallMm={latest.rainfallMm} />
            </div>

            {/* Charts Row 1 */}
            <div className="rounded-2xl bg-white p-6 shadow-sm ring-1 ring-slate-100 lg:col-span-2">
              <WaterLevelChart points={history} />
            </div>
            <div className="rounded-2xl bg-white p-6 shadow-sm ring-1 ring-slate-100 lg:col-span-1">
              <FlowSpeedChart points={flowHistory} />
            </div>

            {/* Chart Row 2 */}
            <div className="rounded-2xl bg-white p-6 shadow-sm ring-1 ring-slate-100 lg:col-span-3">
              <RainfallChart points={history} />
            </div>
          </div>
        </section>

      </main>
    </div>
  );
}