"use client";

import { FormEvent, useEffect, useMemo, useState } from "react";
import { ThresholdFlowRateChart } from "@/components/charts/ThresholdFlowRateChart";
import { ThresholdRainfallChart } from "@/components/charts/ThresholdRainfallChart";
import { Card } from "@/components/ui/Card";
import api from "@/lib/api";
import { useThresholdIotData, type ThresholdIotPoint } from "@/hooks/useThresholdIotData";

interface ThresholdForm {
  normalMax: number;
  waspadaMin: number;
  waspadaMax: number;
  bahayaMin: number;
  ringanMax: number;
  sedangMax: number;
  lebatMin: number;
  autoBroadcast: boolean;
}

interface ChartPlaceholderProps {
  title: string;
  subtitle: string;
  statusLabel: string;
  accent: "emerald" | "sky" | "amber";
  data: ThresholdIotPoint[];
  loading: boolean;
  emptyLabel: string;
}

const accentClasses = {
  emerald: {
    chip: "bg-emerald-50 text-emerald-700",
    border: "border-emerald-200",
    gradient: "bg-linear-to-br from-emerald-50/80 via-white to-cyan-50/60",
    icon: "bg-emerald-100 text-emerald-700",
  },
  sky: {
    chip: "bg-sky-50 text-sky-700",
    border: "border-sky-200",
    gradient: "bg-linear-to-br from-sky-50/80 via-white to-blue-50/60",
    icon: "bg-sky-100 text-sky-700",
  },
  amber: {
    chip: "bg-amber-50 text-amber-700",
    border: "border-amber-200",
    gradient: "bg-linear-to-br from-amber-50/80 via-white to-rose-50/60",
    icon: "bg-amber-100 text-amber-700",
  },
} as const;

function ChartPlaceholder({ title, subtitle, statusLabel, accent, data, loading, emptyLabel }: ChartPlaceholderProps) {
  const styles = accentClasses[accent];
  const latestPoint = data[0];

  return (
    <Card className="min-h-62.5 rounded-2xl border border-slate-100 bg-white/80 shadow-sm backdrop-blur">
      <div className="mb-4 flex items-start justify-between gap-3">
        <div>
          <h2 className="text-base font-semibold text-slate-900">{title}</h2>
          <p className="mt-1 text-sm text-slate-500">{subtitle}</p>
        </div>
        <span className={`rounded-full px-2.5 py-1 text-xs font-medium ${styles.chip}`}>{statusLabel}</span>
      </div>

      <div className={`flex min-h-45 items-center justify-center rounded-2xl border border-dashed p-6 text-center ${styles.border} ${styles.gradient}`}>
        <div className="max-w-xs space-y-2">
          <div className={`mx-auto flex h-12 w-12 items-center justify-center rounded-2xl shadow-sm ${styles.icon}`}>
            <svg viewBox="0 0 24 24" className="h-6 w-6" fill="none" stroke="currentColor" strokeWidth="1.8">
              <path d="M4 18V6" strokeLinecap="round" strokeLinejoin="round" />
              <path d="M4 18h16" strokeLinecap="round" strokeLinejoin="round" />
              <path d="M7 14l3-3 3 2 4-5" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          </div>
          {loading ? (
            <>
              <p className="text-sm font-medium text-slate-700">Memuat data real-time...</p>
              <p className="text-xs leading-5 text-slate-500">Menyiapkan stream IoT untuk {title.toLowerCase()}.</p>
            </>
          ) : latestPoint ? (
            <>
              <p className="text-sm font-medium text-slate-700">{latestPoint.sensorName}</p>
              <p className="text-xs leading-5 text-slate-500">
                Nilai terakhir: <span className="font-semibold text-slate-700">{latestPoint.value}</span> pada {new Date(latestPoint.recordedAt).toLocaleTimeString("id-ID", { hour: "2-digit", minute: "2-digit" })}
              </p>
            </>
          ) : (
            <>
              <p className="text-sm font-medium text-slate-700">{emptyLabel}</p>
              <p className="text-xs leading-5 text-slate-500">Tempat ini siap menerima komponen chart saat stream terhubung.</p>
            </>
          )}
        </div>
      </div>
    </Card>
  );
}

export default function AdminThresholdsPage() {
  const [sensorCount, setSensorCount] = useState(0);
  const [autoBroadcastCount, setAutoBroadcastCount] = useState(0);
  const [saved, setSaved] = useState(false);
  const [toastMessage, setToastMessage] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [confirmSaveOpen, setConfirmSaveOpen] = useState(false);

  const [form, setForm] = useState<ThresholdForm>({
    normalMax: 150,
    waspadaMin: 151,
    waspadaMax: 250,
    bahayaMin: 251,
    ringanMax: 5,
    sedangMax: 20,
    lebatMin: 21,
    autoBroadcast: false,
  });

  const { rainfallData, flowRateData, waterLevelData, isLoading: isIotLoading, error: iotError, lastUpdated: iotLastUpdated } = useThresholdIotData();

  const loadData = async () => {
    setErrorMessage(null);
    try {
      const [thresholdResp, sensorResp] = await Promise.all([api.get("/thresholds"), api.get("/sensors")]);

      const thresholdData = thresholdResp.data?.data as {
        waterLevel: {
          normal: { min: number; max: number };
          warning: { min: number; max: number };
          danger: { min: number; max: number | null };
        } | null;
        rainfall: {
          light: { min: number; max: number };
          moderate: { min: number; max: number };
          heavy: { min: number; max: number | null };
        } | null;
      };

      const sensorPayload = sensorResp.data?.data;
      const sensors = (Array.isArray(sensorPayload) ? sensorPayload : sensorPayload?.items ?? []) as Array<{ id: string }>;
      setSensorCount(sensors.length);

      const waterLevel = thresholdData?.waterLevel;
      const rainfall = thresholdData?.rainfall;

      if (waterLevel && rainfall) {
        setForm((prev) => ({
          ...prev,
          normalMax: waterLevel.normal.max,
          waspadaMin: waterLevel.warning.min,
          waspadaMax: waterLevel.warning.max,
          bahayaMin: waterLevel.danger.min,
          ringanMax: rainfall.light.max,
          sedangMax: rainfall.moderate.max,
          lebatMin: rainfall.heavy.min,
        }));
      }

      setAutoBroadcastCount(0);
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : "Gagal memuat konfigurasi ambang batas.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void loadData();
  }, []);

  useEffect(() => {
    if (!toastMessage) return;

    const timer = window.setTimeout(() => setToastMessage(null), 3500);
    return () => window.clearTimeout(timer);
  }, [toastMessage]);

  const toggleAutoBroadcast = () => {
    setForm((prev) => ({ ...prev, autoBroadcast: !prev.autoBroadcast }));
  };

  const openSaveConfirmation = () => {
    setSaved(false);
    setErrorMessage(null);
    setConfirmSaveOpen(true);
  };

  const handleSaveThresholds = async () => {
    setSaved(false);
    setErrorMessage(null);

    try {
      await api.put("/thresholds", {
        waterLevel: {
          normal: { min: 0, max: form.normalMax },
          warning: { min: form.waspadaMin, max: form.waspadaMax },
          danger: { min: form.bahayaMin, max: null },
        },
        rainfall: {
          light: { min: 0, max: form.ringanMax },
          moderate: { min: form.ringanMax + 0.1, max: form.sedangMax },
          heavy: { min: form.lebatMin, max: null },
        },
      });

      setSaved(true);
      setAutoBroadcastCount(form.autoBroadcast ? sensorCount : 0);
      setToastMessage("Perubahan ambang batas berhasil disimpan.");
      setConfirmSaveOpen(false);
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : "Gagal menyimpan ambang batas.");
    }
  };

  const handleSubmit = (event: FormEvent) => {
    event.preventDefault();
    openSaveConfirmation();
  };

  const chartSummary = useMemo(
    () => ({
      rainfallCount: rainfallData.length,
      flowCount: flowRateData.length,
      waterLevelCount: waterLevelData.length,
    }),
    [flowRateData.length, rainfallData.length, waterLevelData.length],
  );

  return (
    <main className="space-y-6">
      <Card className="relative overflow-hidden border border-slate-200 bg-linear-to-r from-blue-600 via-indigo-600 to-cyan-500 text-white shadow-xl shadow-blue-950/10">
        <div className="absolute -right-6 top-6 h-28 w-28 rounded-3xl border border-white/15 bg-white/10 blur-[1px]" />
        <div className="relative z-10 space-y-3 p-1">
          <div className="inline-flex items-center gap-2 rounded-full border border-white/15 bg-white/10 px-3 py-1 text-xs font-medium text-blue-50/95 backdrop-blur">
            <span className="inline-block h-2 w-2 rounded-full bg-emerald-300 shadow-[0_0_0_4px_rgba(134,239,172,0.18)]" />
            IoT Threshold Center
          </div>
          <div className="space-y-1.5">
            <h1 className="text-2xl font-bold tracking-tight md:text-3xl">Ambang Batas (Threshold Settings)</h1>
            <p className="max-w-3xl text-sm text-blue-50/95 md:text-base">
              Atur level ketinggian air dan curah hujan per sensor untuk logika notifikasi otomatis, sambil memantau konteks IoT real-time dalam satu tampilan.
            </p>
          </div>
        </div>
      </Card>

      <div className="grid gap-4 md:grid-cols-3">
        <Card className="border border-slate-200 bg-white/90 shadow-sm shadow-slate-200/50 backdrop-blur">
          <p className="text-sm text-slate-500">Sensor Terkonfigurasi</p>
          <div className="mt-2 flex items-end gap-2">
            <p className="text-3xl font-bold text-slate-900">{sensorCount}</p>
            <span className="mb-1 text-xs font-medium text-emerald-600">Aktif</span>
          </div>
          <p className="mt-1 text-xs text-slate-500">Sudah memiliki rule threshold</p>
        </Card>
        <Card className="border border-slate-200 bg-white/90 shadow-sm shadow-slate-200/50 backdrop-blur">
          <p className="text-sm text-slate-500">Auto Broadcast Aktif</p>
          <div className="mt-2 flex items-end gap-2">
            <p className="text-3xl font-bold text-blue-600">{autoBroadcastCount}</p>
            <span className="mb-1 text-xs font-medium text-blue-500">Siaga</span>
          </div>
          <p className="mt-1 text-xs text-slate-500">Sensor siap kirim peringatan otomatis</p>
        </Card>
        <Card className="border border-slate-200 bg-white/90 shadow-sm shadow-slate-200/50 backdrop-blur">
          <p className="text-sm text-slate-500">Mode Konfigurasi</p>
          <div className="mt-2 flex items-end gap-2">
            <p className="truncate text-2xl font-bold text-cyan-700">Global</p>
            <span className="mb-1 text-xs font-medium text-cyan-500">EWS</span>
          </div>
          <p className="mt-1 text-xs text-slate-500">Berlaku untuk seluruh sensor</p>
        </Card>
      </div>

      {loading && <p className="text-sm text-slate-500">Memuat konfigurasi ambang batas...</p>}
      {errorMessage && <p className="text-sm font-medium text-rose-600">{errorMessage}</p>}
      {iotError && <p className="text-sm font-medium text-amber-600">Data IoT: {iotError}</p>}

      {toastMessage && (
        <div className="fixed bottom-6 right-6 z-50 max-w-sm rounded-2xl border border-emerald-200 bg-white px-4 py-3 shadow-xl shadow-slate-900/10">
          <p className="text-sm font-semibold text-emerald-700">Berhasil</p>
          <p className="mt-1 text-sm text-slate-600">{toastMessage}</p>
        </div>
      )}

      <div className="grid gap-6 xl:grid-cols-[1.35fr_0.95fr]">
        <section className="space-y-6">
          <div className="grid gap-4 lg:grid-cols-2">
            <ThresholdRainfallChart data={rainfallData} loading={isIotLoading} />
            <ThresholdFlowRateChart data={flowRateData} loading={isIotLoading} />
          </div>

          <Card className="min-h-62.5 rounded-2xl border border-slate-100 bg-white/80 p-5 shadow-sm backdrop-blur">
            <div className="mb-4 flex items-start justify-between gap-3">
              <div>
                <h2 className="text-base font-semibold text-slate-900">Grafik Ketinggian Air (Menunggu Koneksi)</h2>
                <p className="mt-1 text-sm text-slate-500">Placeholder untuk sensor water level yang akan dihubungkan berikutnya.</p>
              </div>
              <span className="rounded-full bg-amber-50 px-2.5 py-1 text-xs font-medium text-amber-700">Pending</span>
            </div>
            <div className="flex min-h-45 items-center justify-center rounded-2xl border border-dashed border-amber-200 bg-linear-to-br from-amber-50/80 via-white to-rose-50/60 p-6 text-center">
              <div className="max-w-sm space-y-2">
                <div className="mx-auto flex h-12 w-12 items-center justify-center rounded-2xl bg-amber-100 text-amber-700 shadow-sm">
                  <svg viewBox="0 0 24 24" className="h-6 w-6" fill="none" stroke="currentColor" strokeWidth="1.8"><path d="M12 6v6l4 2" strokeLinecap="round" strokeLinejoin="round"/><circle cx="12" cy="12" r="9" /></svg>
                </div>
                <p className="text-sm font-medium text-slate-700">Grafik ini menunggu koneksi sensor water level</p>
                <p className="text-xs leading-5 text-slate-500">Anda bisa menempatkan chart realtime ketika IoT water level sudah aktif.</p>
              </div>
            </div>
          </Card>
        </section>

        <section className="space-y-6">
          <Card className="rounded-2xl border border-slate-100 bg-white/90 shadow-md shadow-slate-200/40 backdrop-blur">
            <div className="mb-4 flex items-start gap-3">
              <div className="rounded-2xl bg-blue-50 p-2.5 text-blue-700 shadow-sm">
                <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="1.8"><path d="M12 3v18" strokeLinecap="round" strokeLinejoin="round"/><path d="M5 8c2-3 5-4 7-4s5 1 7 4" strokeLinecap="round" strokeLinejoin="round"/><path d="M5 16c2 3 5 4 7 4s5-1 7-4" strokeLinecap="round" strokeLinejoin="round"/></svg>
              </div>
              <div>
                <h2 className="text-lg font-semibold text-slate-900">Form Pengaturan Ambang Batas</h2>
                <p className="text-sm text-slate-500">Pastikan konfigurasi level air dan hujan sesuai kondisi lapangan tiap sensor.</p>
              </div>
            </div>

            <form id="threshold-settings-form" onSubmit={handleSubmit} className="space-y-6">
              <p className="text-sm text-slate-600">
                Pengaturan ini disimpan di database dan diterapkan sebagai threshold global. {iotLastUpdated ? `Pembaruan IoT terakhir: ${new Date(iotLastUpdated).toLocaleTimeString("id-ID", { hour: "2-digit", minute: "2-digit" })}.` : ""}
              </p>

              <div className="space-y-4 rounded-2xl border border-emerald-100 bg-linear-to-br from-emerald-50/80 to-white p-4 shadow-sm">
                <div className="flex items-center justify-between gap-3">
                  <div>
                    <h2 className="text-sm font-semibold text-slate-800">Konfigurasi Ketinggian Air</h2>
                    <p className="text-xs text-slate-500">Gunakan warna hijau/amber/rose sebagai isyarat risiko pada range level.</p>
                  </div>
                  <span className="rounded-full bg-emerald-100 px-2.5 py-1 text-xs font-medium text-emerald-700">cm</span>
                </div>

                <div className="grid gap-3 md:grid-cols-2">
                  <label className="block text-sm text-slate-700">
                    <span className="mb-1.5 block font-medium text-slate-700">Level Normal (Hijau) Maks</span>
                    <div className="group relative overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm transition focus-within:border-emerald-300 focus-within:ring-2 focus-within:ring-emerald-200/70">
                      <div className="pointer-events-none absolute inset-y-0 left-0 w-1.5 bg-emerald-500" />
                      <input
                        type="number"
                        step="0.1"
                        inputMode="decimal"
                        value={form.normalMax}
                        onChange={(event) => setForm((prev) => ({ ...prev, normalMax: Number(event.target.value) }))}
                        className="h-12 w-full bg-transparent px-4 py-2 pl-5 pr-14 text-slate-900 outline-none placeholder:text-slate-400"
                      />
                      <span className="pointer-events-none absolute inset-y-0 right-0 flex items-center px-4 text-sm font-medium text-slate-400">cm</span>
                    </div>
                  </label>

                  <label className="block text-sm text-slate-700">
                    <span className="mb-1.5 block font-medium text-slate-700">Level Waspada Min</span>
                    <div className="group relative overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm transition focus-within:border-amber-300 focus-within:ring-2 focus-within:ring-amber-200/70">
                      <div className="pointer-events-none absolute inset-y-0 left-0 w-1.5 bg-amber-500" />
                      <input
                        type="number"
                        step="0.1"
                        inputMode="decimal"
                        value={form.waspadaMin}
                        onChange={(event) => setForm((prev) => ({ ...prev, waspadaMin: Number(event.target.value) }))}
                        className="h-12 w-full bg-transparent px-4 py-2 pl-5 pr-14 text-slate-900 outline-none placeholder:text-slate-400"
                      />
                      <span className="pointer-events-none absolute inset-y-0 right-0 flex items-center px-4 text-sm font-medium text-slate-400">cm</span>
                    </div>
                  </label>

                  <label className="block text-sm text-slate-700">
                    <span className="mb-1.5 block font-medium text-slate-700">Level Waspada Maks</span>
                    <div className="group relative overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm transition focus-within:border-amber-300 focus-within:ring-2 focus-within:ring-amber-200/70">
                      <div className="pointer-events-none absolute inset-y-0 left-0 w-1.5 bg-amber-500" />
                      <input
                        type="number"
                        step="0.1"
                        inputMode="decimal"
                        value={form.waspadaMax}
                        onChange={(event) => setForm((prev) => ({ ...prev, waspadaMax: Number(event.target.value) }))}
                        className="h-12 w-full bg-transparent px-4 py-2 pl-5 pr-14 text-slate-900 outline-none placeholder:text-slate-400"
                      />
                      <span className="pointer-events-none absolute inset-y-0 right-0 flex items-center px-4 text-sm font-medium text-slate-400">cm</span>
                    </div>
                  </label>

                  <label className="block text-sm text-slate-700">
                    <span className="mb-1.5 block font-medium text-slate-700">Level Bahaya (Merah) Min</span>
                    <div className="group relative overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm transition focus-within:border-rose-300 focus-within:ring-2 focus-within:ring-rose-200/70">
                      <div className="pointer-events-none absolute inset-y-0 left-0 w-1.5 bg-rose-500" />
                      <input
                        type="number"
                        step="0.1"
                        inputMode="decimal"
                        value={form.bahayaMin}
                        onChange={(event) => setForm((prev) => ({ ...prev, bahayaMin: Number(event.target.value) }))}
                        className="h-12 w-full bg-transparent px-4 py-2 pl-5 pr-14 text-slate-900 outline-none placeholder:text-slate-400"
                      />
                      <span className="pointer-events-none absolute inset-y-0 right-0 flex items-center px-4 text-sm font-medium text-slate-400">cm</span>
                    </div>
                  </label>
                </div>
              </div>

              <div className="space-y-4 rounded-2xl border border-slate-100 bg-linear-to-br from-sky-50/70 to-white p-4 shadow-sm">
                <div className="flex items-center justify-between gap-3">
                  <div>
                    <h2 className="text-sm font-semibold text-slate-800">Konfigurasi Curah Hujan</h2>
                    <p className="text-xs text-slate-500">Membantu pemetaan intensitas hujan untuk trigger alert otomatis.</p>
                  </div>
                  <span className="rounded-full bg-sky-100 px-2.5 py-1 text-xs font-medium text-sky-700">mm/jam</span>
                </div>

                <div className="grid gap-3 md:grid-cols-2">
                  <label className="block text-sm text-slate-700">
                    <span className="mb-1.5 block font-medium text-slate-700">Ringan (Maks)</span>
                    <div className="group relative overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm transition focus-within:border-emerald-300 focus-within:ring-2 focus-within:ring-emerald-200/70">
                      <div className="pointer-events-none absolute inset-y-0 left-0 w-1.5 bg-emerald-500" />
                      <input
                        type="number"
                        step="0.1"
                        inputMode="decimal"
                        value={form.ringanMax}
                        onChange={(event) => setForm((prev) => ({ ...prev, ringanMax: Number(event.target.value) }))}
                        className="h-12 w-full bg-transparent px-4 py-2 pl-5 pr-20 text-slate-900 outline-none placeholder:text-slate-400"
                      />
                      <span className="pointer-events-none absolute inset-y-0 right-0 flex items-center px-4 text-sm font-medium text-slate-400">mm/jam</span>
                    </div>
                  </label>

                  <label className="block text-sm text-slate-700">
                    <span className="mb-1.5 block font-medium text-slate-700">Sedang (Maks)</span>
                    <div className="group relative overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm transition focus-within:border-amber-300 focus-within:ring-2 focus-within:ring-amber-200/70">
                      <div className="pointer-events-none absolute inset-y-0 left-0 w-1.5 bg-amber-500" />
                      <input
                        type="number"
                        step="0.1"
                        inputMode="decimal"
                        value={form.sedangMax}
                        onChange={(event) => setForm((prev) => ({ ...prev, sedangMax: Number(event.target.value) }))}
                        className="h-12 w-full bg-transparent px-4 py-2 pl-5 pr-20 text-slate-900 outline-none placeholder:text-slate-400"
                      />
                      <span className="pointer-events-none absolute inset-y-0 right-0 flex items-center px-4 text-sm font-medium text-slate-400">mm/jam</span>
                    </div>
                  </label>

                  <label className="block text-sm text-slate-700 md:col-span-2">
                    <span className="mb-1.5 block font-medium text-slate-700">Lebat (Min)</span>
                    <div className="group relative overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm transition focus-within:border-rose-300 focus-within:ring-2 focus-within:ring-rose-200/70">
                      <div className="pointer-events-none absolute inset-y-0 left-0 w-1.5 bg-rose-500" />
                      <input
                        type="number"
                        step="0.1"
                        inputMode="decimal"
                        value={form.lebatMin}
                        onChange={(event) => setForm((prev) => ({ ...prev, lebatMin: Number(event.target.value) }))}
                        className="h-12 w-full bg-transparent px-4 py-2 pl-5 pr-20 text-slate-900 outline-none placeholder:text-slate-400"
                      />
                      <span className="pointer-events-none absolute inset-y-0 right-0 flex items-center px-4 text-sm font-medium text-slate-400">mm/jam</span>
                    </div>
                  </label>
                </div>
              </div>

              <div className="rounded-2xl border border-amber-200 bg-linear-to-r from-amber-50 via-white to-rose-50 p-4 shadow-sm">
                <div className="flex items-start gap-4">
                  <div className="rounded-2xl bg-amber-100 p-2.5 text-amber-700 shadow-sm">
                    <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="1.8"><path d="M12 9v4" strokeLinecap="round" strokeLinejoin="round"/><circle cx="12" cy="17" r="1"/><path d="M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z" strokeLinecap="round" strokeLinejoin="round"/></svg>
                  </div>
                  <div className="flex-1 space-y-3">
                    <div>
                      <h3 className="text-sm font-semibold text-slate-900">Auto-Broadcast saat Level Bahaya</h3>
                      <p className="mt-1 text-xs leading-5 text-slate-500">Pengaturan kritikal untuk mengaktifkan penyebaran otomatis ketika threshold bahaya tercapai.</p>
                    </div>

                    <button
                      type="button"
                      onClick={toggleAutoBroadcast}
                      aria-label="Toggle auto broadcast"
                      className={`inline-flex w-full items-center justify-between rounded-2xl border px-4 py-3 text-left transition-all sm:w-auto sm:min-w-[320px] ${form.autoBroadcast ? "border-blue-200 bg-blue-50/70" : "border-slate-200 bg-white"}`}
                    >
                      <span>
                        <span className="block text-sm font-medium text-slate-800">Aktifkan Auto-Broadcast</span>
                        <span className="block text-xs text-slate-500">Trigger notifikasi otomatis untuk status bahaya</span>
                      </span>
                      <span className={`relative inline-flex h-7 w-12 items-center rounded-full transition-colors ${form.autoBroadcast ? "bg-blue-600" : "bg-slate-300"}`}>
                        <span className={`inline-block h-5 w-5 transform rounded-full bg-white shadow-sm transition-transform ${form.autoBroadcast ? "translate-x-6" : "translate-x-1"}`} />
                      </span>
                    </button>
                  </div>
                </div>
              </div>

              <div className="flex flex-wrap items-center gap-3 border-t border-slate-100 pt-2">
                <button
                  type="button"
                  onClick={openSaveConfirmation}
                  className="inline-flex items-center gap-2 rounded-lg bg-blue-600 px-5 py-3 text-sm font-semibold text-white shadow-md shadow-blue-900/15 transition-all hover:-translate-y-0.5 hover:bg-blue-700 hover:shadow-lg"
                >
                  <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="1.8"><path d="M5 12h14" strokeLinecap="round" strokeLinejoin="round"/><path d="M12 5v14" strokeLinecap="round" strokeLinejoin="round"/></svg>
                  Simpan Konfigurasi
                </button>
                {saved && <p className="text-sm text-emerald-600">Perubahan ambang batas berhasil disimpan.</p>}
              </div>
            </form>
          </Card>
        </section>
      </div>

      {confirmSaveOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center px-4">
          <div className="absolute inset-0 bg-slate-900/50 backdrop-blur-sm" onClick={() => setConfirmSaveOpen(false)} />

          <div className="relative z-10 w-full max-w-lg rounded-3xl border border-slate-100 bg-white p-6 shadow-2xl shadow-slate-950/20">
            <div className="flex items-start gap-3">
              <div className="rounded-2xl bg-amber-100 p-2.5 text-amber-700 shadow-sm">
                <svg viewBox="0 0 24 24" className="h-6 w-6" fill="none" stroke="currentColor" strokeWidth="1.8"><path d="M12 9v4" strokeLinecap="round" strokeLinejoin="round"/><circle cx="12" cy="17" r="1"/><path d="M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z" strokeLinecap="round" strokeLinejoin="round"/></svg>
              </div>
              <div className="flex-1">
                <h3 className="text-lg font-semibold text-slate-900">Konfirmasi Perubahan Ambang Batas</h3>
                <p className="mt-2 text-sm leading-6 text-slate-600">
                  Perubahan pada threshold akan langsung berdampak pada logika notifikasi otomatis dan status bahaya di seluruh sistem. Pastikan angka yang dimasukkan sudah sesuai dengan standar operasional.
                </p>
              </div>
            </div>

            <div className="mt-6 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
              <button
                type="button"
                onClick={() => setConfirmSaveOpen(false)}
                className="inline-flex items-center justify-center rounded-lg border border-slate-200 bg-white px-4 py-2.5 text-sm font-medium text-slate-700 transition hover:bg-slate-50"
              >
                Batal
              </button>
              <button
                type="button"
                onClick={() => void handleSaveThresholds()}
                className="inline-flex items-center justify-center gap-2 rounded-lg bg-blue-600 px-4 py-2.5 text-sm font-semibold text-white shadow-md shadow-blue-900/15 transition hover:bg-blue-700 hover:shadow-lg"
              >
                <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="1.8"><path d="M5 12h14" strokeLinecap="round" strokeLinejoin="round"/><path d="M12 5v14" strokeLinecap="round" strokeLinejoin="round"/></svg>
                Ya, Simpan Perubahan
              </button>
            </div>
          </div>
        </div>
      )}
    </main>
  );
}
