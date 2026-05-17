"use client";

import { useMemo, useState } from "react";
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
import { cn, getRainfallCategory, formatTimestamp } from "@/lib/utils";
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
  const { latest, history, sensorsSnapshot, liveBySensor } = useWaterLevel({ sensorId: selectedSensorId });
  const { history: flowHistory } = useFlowRate();

  const sortedSensors = useMemo(
    () => [...liveBySensor].sort((a, b) => statusRank[b.status] - statusRank[a.status] || b.levelCm - a.levelCm),
    [liveBySensor],
  );

  const overallStatus = sortedSensors[0]?.status ?? latest.status;
  const dangerCount = liveBySensor.filter((sensor) => sensor.status === "danger").length;
  const alertCount = liveBySensor.filter((sensor) => sensor.status === "alert").length;
  const warningCount = liveBySensor.filter((sensor) => sensor.status === "warning").length;

  const selectableSensors = useMemo(
    () => sensorsSnapshot.filter((sensor) => sensor.type !== "FLOW_RATE"),
    [sensorsSnapshot],
  );

  const selectedSensor = useMemo(
    () => selectableSensors.find((sensor) => sensor.id === latest.sensorId) ?? selectableSensors[0],
    [latest.sensorId, selectableSensors],
  );

  const rainfallCategory = getRainfallCategory(latest.rainfallMm);
  const onlineCount = sensorsSnapshot.filter((sensor) => sensor.connectivity === "online").length;
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
            <p className="text-sm font-medium text-white/80">Pembaruan Terakhir</p>
            <p className="text-lg font-bold">{formatTimestamp(latest.updatedAt)}</p>
          </div>
        </section>

        {/* 2. STATISTIK CEPAT - Tanpa border kasar */}
        <section className="mb-8 grid grid-cols-2 gap-4 lg:grid-cols-4 lg:gap-6">
          <div className="flex flex-col justify-center rounded-2xl bg-white p-5 shadow-sm ring-1 ring-slate-100 transition-shadow hover:shadow-md">
            <p className="text-sm font-medium text-slate-500">Tinggi Air (Aktif)</p>
            <p className="mt-1 text-3xl font-extrabold text-slate-900">{latest.levelCm} <span className="text-lg font-medium text-slate-500">cm</span></p>
            <p className="mt-1 text-xs text-slate-400 truncate">{latest.sensorName}</p>
          </div>

          <div className="flex flex-col justify-center rounded-2xl bg-white p-5 shadow-sm ring-1 ring-slate-100 transition-shadow hover:shadow-md">
            <p className="text-sm font-medium text-slate-500">Curah Hujan</p>
            <p className="mt-1 text-3xl font-extrabold text-cyan-600">{latest.rainfallMm} <span className="text-lg font-medium text-cyan-600/70">mm/j</span></p>
            <p className="mt-1 text-xs text-slate-400 truncate">{rainfallCategory.label}</p>
          </div>

          <div className="flex flex-col justify-center rounded-2xl bg-white p-5 shadow-sm ring-1 ring-slate-100 transition-shadow hover:shadow-md">
            <p className="text-sm font-medium text-slate-500">Sensor Berisiko</p>
            <p className="mt-1 text-3xl font-extrabold text-rose-600">{dangerCount + alertCount + warningCount}</p>
            <p className="mt-1 text-xs text-slate-400 truncate">Bahaya: {dangerCount} • Siaga: {alertCount} • Waspada: {warningCount}</p>
          </div>

          <div className="flex flex-col justify-center rounded-2xl bg-white p-5 shadow-sm ring-1 ring-slate-100 transition-shadow hover:shadow-md">
            <p className="text-sm font-medium text-slate-500">Konektivitas</p>
            <p className="mt-1 text-3xl font-extrabold text-slate-900">{onlineCount}/{sensorsSnapshot.length}</p>
            <p className="mt-1 text-xs text-slate-400 truncate">Sensor online aktif</p>
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
              <div className="mt-6 grid grid-cols-2 gap-4 md:grid-cols-4">
                <div className="rounded-2xl bg-slate-50 p-4 text-center ring-1 ring-slate-100">
                  <p className="text-[11px] font-bold uppercase tracking-widest text-slate-400">Status</p>
                  <div className="mt-2 flex justify-center">
                    <StatusIndicator status={latest.status} />
                  </div>
                </div>
                <div className="rounded-2xl bg-slate-50 p-4 text-center ring-1 ring-slate-100">
                  <p className="text-[11px] font-bold uppercase tracking-widest text-slate-400">Tinggi Air</p>
                  <p className="mt-1 text-xl font-bold text-slate-800">{latest.levelCm} cm</p>
                </div>
                <div className="rounded-2xl bg-slate-50 p-4 text-center ring-1 ring-slate-100">
                  <p className="text-[11px] font-bold uppercase tracking-widest text-slate-400">Koneksi</p>
                  <p className="mt-1 text-xl font-bold text-slate-800">{selectedSensor?.connectivity === "online" ? "Online" : "Offline"}</p>
                </div>
                <div className="rounded-2xl bg-slate-50 p-4 text-center ring-1 ring-slate-100">
                  <p className="text-[11px] font-bold uppercase tracking-widest text-slate-400">Baterai</p>
                  <p className="mt-1 text-xl font-bold text-slate-800">{selectedSensor?.batteryPercent ?? 0}%</p>
                </div>
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
          <h3 className="text-lg font-bold text-slate-900">Daftar Pantauan Semua Wilayah</h3>
          <p className="mt-1 text-sm text-slate-500">Diurutkan otomatis dari wilayah paling berisiko.</p>
          
          <div className="mt-6 grid gap-4 md:grid-cols-3">
            {sortedSensors.map((item) => (
              <div key={item.sensorId} className="flex flex-col justify-between rounded-2xl bg-slate-50 p-5 ring-1 ring-slate-100 transition hover:bg-slate-100">
                <div className="flex items-start justify-between gap-2 border-b border-slate-200 pb-4">
                  <div>
                    <p className="font-bold text-slate-800">{item.sensorName}</p>
                    <p className="text-xs text-slate-500">{item.sensorId}</p>
                  </div>
                  <StatusIndicator status={item.status} />
                </div>
                <div className="mt-4 grid grid-cols-2 gap-2 text-sm">
                  <div>
                    <p className="text-xs text-slate-500">Tinggi Air</p>
                    <p className="font-bold text-slate-900">{item.levelCm} cm</p>
                  </div>
                  <div>
                    <p className="text-xs text-slate-500">Curah Hujan</p>
                    <p className="font-bold text-slate-900">{item.rainfallMm} mm</p>
                  </div>
                </div>
              </div>
            ))}
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