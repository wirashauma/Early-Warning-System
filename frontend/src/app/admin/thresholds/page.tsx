"use client";

import { FormEvent, useEffect, useState } from "react";
import { Card } from "@/components/ui/Card";
import api from "@/lib/api";
import { useThresholdIotData } from "@/hooks/useThresholdIotData";

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

  const { error: iotError, lastUpdated: iotLastUpdated } = useThresholdIotData();

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


  return (
    <main className="space-y-6 bg-slate-50/60">
      <section className="flex flex-col gap-4 border-b border-slate-200/70 pb-5 md:flex-row md:items-end md:justify-between">
        <div className="space-y-2">
          <div className="inline-flex items-center gap-2 rounded-full border border-slate-200 bg-white px-3 py-1 text-xs font-medium text-slate-600 shadow-sm">
            <span className="inline-block h-2 w-2 rounded-full bg-cyan-500" />
            Threshold Settings
          </div>
          <div className="flex items-start gap-3">
            <div className="mt-1 inline-flex h-10 w-10 items-center justify-center rounded-xl border border-slate-200 bg-white text-slate-700 shadow-sm">
              <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true">
                <path d="M4 8h8" strokeLinecap="round" />
                <path d="M14 8h6" strokeLinecap="round" />
                <circle cx="17" cy="8" r="2.25" />
                <path d="M4 16h4" strokeLinecap="round" />
                <path d="M10 16h10" strokeLinecap="round" />
                <circle cx="7" cy="16" r="2.25" />
              </svg>
            </div>
            <div>
              <h1 className="text-2xl font-bold tracking-tight text-slate-900">Ambang Batas</h1>
              <p className="mt-1 text-sm text-slate-500">
                Kelola level ketinggian air dan curah hujan dengan tampilan yang lebih ringkas, modern, dan mudah dipindai.
              </p>
            </div>
          </div>
        </div>
      </section>

      <div className="grid gap-4 md:grid-cols-3">
        <Card className="rounded-xl border border-slate-200 bg-white shadow-sm">
          <p className="text-sm font-medium text-slate-500">Sensor Terkonfigurasi</p>
          <div className="mt-3 flex items-end gap-3">
            <p className="text-3xl font-bold tracking-tight text-slate-800">{sensorCount}</p>
            <span className="mb-1 rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-700">Aktif</span>
          </div>
          <p className="mt-2 text-xs text-slate-500">Sudah memiliki rule threshold</p>
        </Card>
        <Card className="rounded-xl border border-slate-200 bg-white shadow-sm">
          <p className="text-sm font-medium text-slate-500">Auto Broadcast Aktif</p>
          <div className="mt-3 flex items-end gap-3">
            <p className="text-3xl font-bold tracking-tight text-slate-800">{autoBroadcastCount}</p>
            <span className="mb-1 rounded-full bg-blue-50 px-2.5 py-1 text-xs font-semibold text-blue-700">Siaga</span>
          </div>
          <p className="mt-2 text-xs text-slate-500">Sensor siap kirim peringatan otomatis</p>
        </Card>
        <Card className="rounded-xl border border-slate-200 bg-white shadow-sm">
          <p className="text-sm font-medium text-slate-500">Mode Konfigurasi</p>
          <div className="mt-3 flex items-end gap-3">
            <p className="truncate text-3xl font-bold tracking-tight text-slate-800">Global</p>
            <span className="mb-1 rounded-full bg-cyan-50 px-2.5 py-1 text-xs font-semibold text-cyan-700">EWS</span>
          </div>
          <p className="mt-2 text-xs text-slate-500">Berlaku untuk seluruh sensor</p>
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

      <div className="mx-auto w-full max-w-4xl">
        <Card className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm md:p-8">
          <div className="mb-6 flex items-start gap-3 border-b border-slate-100 pb-4">
            <div className="inline-flex h-11 w-11 items-center justify-center rounded-xl border border-slate-200 bg-slate-50 text-slate-700 shadow-sm">
              <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true">
                <path d="M12 3v18" strokeLinecap="round" strokeLinejoin="round" />
                <path d="M5 8c2-3 5-4 7-4s5 1 7 4" strokeLinecap="round" strokeLinejoin="round" />
                <path d="M5 16c2 3 5 4 7 4s5-1 7-4" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </div>
            <div>
              <h2 className="text-lg font-semibold text-slate-900">Form Pengaturan Ambang Batas</h2>
              <p className="mt-1 text-sm text-slate-500">Pastikan konfigurasi level air dan hujan sesuai kondisi lapangan tiap sensor.</p>
            </div>
          </div>

          <form id="threshold-settings-form" onSubmit={handleSubmit} className="space-y-8">
            <p className="text-sm leading-6 text-slate-600">
              Pengaturan ini disimpan di database dan diterapkan sebagai threshold global. {iotLastUpdated ? `Pembaruan IoT terakhir: ${new Date(iotLastUpdated).toLocaleTimeString("id-ID", { hour: "2-digit", minute: "2-digit" })}.` : ""}
            </p>

            <section className="space-y-5">
              <div className="border-b border-slate-100 pb-2">
                <div className="flex items-center justify-between gap-3">
                  <div>
                    <h3 className="text-base font-semibold text-slate-900">Konfigurasi Ketinggian Air</h3>
                    <p className="mt-1 text-xs text-slate-500">Gunakan indikator warna untuk membedakan tingkat risiko pada input.</p>
                  </div>
                  <span className="rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-600">cm</span>
                </div>
              </div>

              <div className="grid gap-4 md:grid-cols-2">
                <label className="block text-sm text-slate-700">
                  <span className="mb-1.5 flex items-center gap-2 font-medium text-slate-700">
                    <span className="inline-flex items-center gap-1.5 rounded-full bg-emerald-50 px-2 py-1 text-xs font-semibold text-emerald-700">
                      <span className="h-2 w-2 rounded-full bg-emerald-500" />
                      Normal
                    </span>
                    Level Normal Maks
                  </span>
                  <div className="relative rounded-lg border border-slate-300 bg-white shadow-sm transition focus-within:border-slate-400 focus-within:ring-2 focus-within:ring-slate-200">
                    <input
                      type="number"
                      step="0.1"
                      inputMode="decimal"
                      value={form.normalMax}
                      onChange={(event) => setForm((prev) => ({ ...prev, normalMax: Number(event.target.value) }))}
                      className="h-12 w-full rounded-lg bg-transparent px-4 text-slate-900 outline-none placeholder:text-slate-400"
                    />
                    <span className="pointer-events-none absolute inset-y-0 right-0 flex items-center px-4 text-sm font-medium text-slate-400">cm</span>
                  </div>
                </label>

                <label className="block text-sm text-slate-700">
                  <span className="mb-1.5 flex items-center gap-2 font-medium text-slate-700">
                    <span className="inline-flex items-center gap-1.5 rounded-full bg-amber-50 px-2 py-1 text-xs font-semibold text-amber-700">
                      <span className="h-2 w-2 rounded-full bg-amber-500" />
                      Waspada
                    </span>
                    Level Waspada Min
                  </span>
                  <div className="relative rounded-lg border border-slate-300 bg-white shadow-sm transition focus-within:border-slate-400 focus-within:ring-2 focus-within:ring-slate-200">
                    <input
                      type="number"
                      step="0.1"
                      inputMode="decimal"
                      value={form.waspadaMin}
                      onChange={(event) => setForm((prev) => ({ ...prev, waspadaMin: Number(event.target.value) }))}
                      className="h-12 w-full rounded-lg bg-transparent px-4 text-slate-900 outline-none placeholder:text-slate-400"
                    />
                    <span className="pointer-events-none absolute inset-y-0 right-0 flex items-center px-4 text-sm font-medium text-slate-400">cm</span>
                  </div>
                </label>

                <label className="block text-sm text-slate-700">
                  <span className="mb-1.5 flex items-center gap-2 font-medium text-slate-700">
                    <span className="inline-flex items-center gap-1.5 rounded-full bg-amber-50 px-2 py-1 text-xs font-semibold text-amber-700">
                      <span className="h-2 w-2 rounded-full bg-amber-500" />
                      Waspada
                    </span>
                    Level Waspada Maks
                  </span>
                  <div className="relative rounded-lg border border-slate-300 bg-white shadow-sm transition focus-within:border-slate-400 focus-within:ring-2 focus-within:ring-slate-200">
                    <input
                      type="number"
                      step="0.1"
                      inputMode="decimal"
                      value={form.waspadaMax}
                      onChange={(event) => setForm((prev) => ({ ...prev, waspadaMax: Number(event.target.value) }))}
                      className="h-12 w-full rounded-lg bg-transparent px-4 text-slate-900 outline-none placeholder:text-slate-400"
                    />
                    <span className="pointer-events-none absolute inset-y-0 right-0 flex items-center px-4 text-sm font-medium text-slate-400">cm</span>
                  </div>
                </label>

                <label className="block text-sm text-slate-700">
                  <span className="mb-1.5 flex items-center gap-2 font-medium text-slate-700">
                    <span className="inline-flex items-center gap-1.5 rounded-full bg-rose-50 px-2 py-1 text-xs font-semibold text-rose-700">
                      <span className="h-2 w-2 rounded-full bg-rose-500" />
                      Bahaya
                    </span>
                    Level Bahaya Min
                  </span>
                  <div className="relative rounded-lg border border-slate-300 bg-white shadow-sm transition focus-within:border-slate-400 focus-within:ring-2 focus-within:ring-slate-200">
                    <input
                      type="number"
                      step="0.1"
                      inputMode="decimal"
                      value={form.bahayaMin}
                      onChange={(event) => setForm((prev) => ({ ...prev, bahayaMin: Number(event.target.value) }))}
                      className="h-12 w-full rounded-lg bg-transparent px-4 text-slate-900 outline-none placeholder:text-slate-400"
                    />
                    <span className="pointer-events-none absolute inset-y-0 right-0 flex items-center px-4 text-sm font-medium text-slate-400">cm</span>
                  </div>
                </label>
              </div>
            </section>

            <section className="space-y-5">
              <div className="border-b border-slate-100 pb-2">
                <div className="flex items-center justify-between gap-3">
                  <div>
                    <h3 className="text-base font-semibold text-slate-900">Konfigurasi Curah Hujan</h3>
                    <p className="mt-1 text-xs text-slate-500">Membantu pemetaan intensitas hujan untuk trigger alert otomatis.</p>
                  </div>
                  <span className="rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-600">mm/jam</span>
                </div>
              </div>

              <div className="grid gap-4 md:grid-cols-2">
                <label className="block text-sm text-slate-700">
                  <span className="mb-1.5 flex items-center gap-2 font-medium text-slate-700">
                    <span className="inline-flex items-center gap-1.5 rounded-full bg-emerald-50 px-2 py-1 text-xs font-semibold text-emerald-700">
                      <span className="h-2 w-2 rounded-full bg-emerald-500" />
                      Ringan
                    </span>
                    Curah Hujan Maks
                  </span>
                  <div className="relative rounded-lg border border-slate-300 bg-white shadow-sm transition focus-within:border-slate-400 focus-within:ring-2 focus-within:ring-slate-200">
                    <input
                      type="number"
                      step="0.1"
                      inputMode="decimal"
                      value={form.ringanMax}
                      onChange={(event) => setForm((prev) => ({ ...prev, ringanMax: Number(event.target.value) }))}
                      className="h-12 w-full rounded-lg bg-transparent px-4 pr-20 text-slate-900 outline-none placeholder:text-slate-400"
                    />
                    <span className="pointer-events-none absolute inset-y-0 right-0 flex items-center px-4 text-sm font-medium text-slate-400">mm/jam</span>
                  </div>
                </label>

                <label className="block text-sm text-slate-700">
                  <span className="mb-1.5 flex items-center gap-2 font-medium text-slate-700">
                    <span className="inline-flex items-center gap-1.5 rounded-full bg-amber-50 px-2 py-1 text-xs font-semibold text-amber-700">
                      <span className="h-2 w-2 rounded-full bg-amber-500" />
                      Sedang
                    </span>
                    Curah Hujan Maks
                  </span>
                  <div className="relative rounded-lg border border-slate-300 bg-white shadow-sm transition focus-within:border-slate-400 focus-within:ring-2 focus-within:ring-slate-200">
                    <input
                      type="number"
                      step="0.1"
                      inputMode="decimal"
                      value={form.sedangMax}
                      onChange={(event) => setForm((prev) => ({ ...prev, sedangMax: Number(event.target.value) }))}
                      className="h-12 w-full rounded-lg bg-transparent px-4 pr-20 text-slate-900 outline-none placeholder:text-slate-400"
                    />
                    <span className="pointer-events-none absolute inset-y-0 right-0 flex items-center px-4 text-sm font-medium text-slate-400">mm/jam</span>
                  </div>
                </label>

                <label className="block text-sm text-slate-700 md:col-span-2">
                  <span className="mb-1.5 flex items-center gap-2 font-medium text-slate-700">
                    <span className="inline-flex items-center gap-1.5 rounded-full bg-rose-50 px-2 py-1 text-xs font-semibold text-rose-700">
                      <span className="h-2 w-2 rounded-full bg-rose-500" />
                      Bahaya
                    </span>
                    Curah Hujan Min
                  </span>
                  <div className="relative rounded-lg border border-slate-300 bg-white shadow-sm transition focus-within:border-slate-400 focus-within:ring-2 focus-within:ring-slate-200">
                    <input
                      type="number"
                      step="0.1"
                      inputMode="decimal"
                      value={form.lebatMin}
                      onChange={(event) => setForm((prev) => ({ ...prev, lebatMin: Number(event.target.value) }))}
                      className="h-12 w-full rounded-lg bg-transparent px-4 pr-20 text-slate-900 outline-none placeholder:text-slate-400"
                    />
                    <span className="pointer-events-none absolute inset-y-0 right-0 flex items-center px-4 text-sm font-medium text-slate-400">mm/jam</span>
                  </div>
                </label>
              </div>
            </section>

            <section className="rounded-2xl border border-slate-200 bg-slate-50/60 p-5 shadow-sm">
              <div className="flex items-start gap-4">
                <div className="inline-flex h-11 w-11 items-center justify-center rounded-xl border border-amber-200 bg-amber-50 text-amber-700 shadow-sm">
                  <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true">
                    <path d="M12 9v4" strokeLinecap="round" strokeLinejoin="round" />
                    <circle cx="12" cy="17" r="1" />
                    <path d="M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z" strokeLinecap="round" strokeLinejoin="round" />
                  </svg>
                </div>
                <div className="flex-1 space-y-4">
                  <div>
                    <h3 className="text-sm font-semibold text-slate-900">Auto-Broadcast saat Level Bahaya</h3>
                    <p className="mt-1 text-xs leading-5 text-slate-500">Pengaturan kritikal untuk mengaktifkan penyebaran otomatis ketika threshold bahaya tercapai.</p>
                  </div>

                  <button
                    type="button"
                    onClick={toggleAutoBroadcast}
                    aria-label="Toggle auto broadcast"
                    className={`inline-flex w-full items-center justify-between rounded-xl border px-4 py-3 text-left shadow-sm transition-all sm:w-auto sm:min-w-[320px] ${form.autoBroadcast ? "border-cyan-200 bg-cyan-50" : "border-slate-200 bg-white hover:border-slate-300"}`}
                  >
                    <span>
                      <span className="block text-sm font-medium text-slate-800">Aktifkan Auto-Broadcast</span>
                      <span className="block text-xs text-slate-500">Trigger notifikasi otomatis untuk status bahaya</span>
                    </span>
                    <span className={`relative inline-flex h-7 w-12 items-center rounded-full transition-colors ${form.autoBroadcast ? "bg-cyan-600" : "bg-slate-300"}`}>
                      <span className={`inline-block h-5 w-5 transform rounded-full bg-white shadow-sm transition-transform ${form.autoBroadcast ? "translate-x-6" : "translate-x-1"}`} />
                    </span>
                  </button>
                </div>
              </div>
            </section>

            <div className="flex flex-wrap items-center gap-3 border-t border-slate-100 pt-2">
              <button
                type="button"
                onClick={openSaveConfirmation}
                className="inline-flex items-center gap-2 rounded-lg bg-slate-900 px-5 py-3 text-sm font-semibold text-white shadow-sm transition-all hover:-translate-y-0.5 hover:bg-slate-800 hover:shadow-md"
              >
                <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true">
                  <path d="M5 12h14" strokeLinecap="round" strokeLinejoin="round" />
                  <path d="M12 5v14" strokeLinecap="round" strokeLinejoin="round" />
                </svg>
                Simpan Konfigurasi
              </button>
              {saved && <p className="text-sm text-emerald-600">Perubahan ambang batas berhasil disimpan.</p>}
            </div>
          </form>
        </Card>
      </div>

      {confirmSaveOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center px-4">
          <div className="absolute inset-0 bg-slate-900/50 backdrop-blur-sm" onClick={() => setConfirmSaveOpen(false)} />

          <div className="relative z-10 w-full max-w-lg rounded-3xl border border-slate-100 bg-white p-6 shadow-2xl shadow-slate-950/20">
            <div className="flex items-start gap-3">
              <div className="rounded-2xl bg-amber-100 p-2.5 text-amber-700 shadow-sm">
                <svg viewBox="0 0 24 24" className="h-6 w-6" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true"><path d="M12 9v4" strokeLinecap="round" strokeLinejoin="round"/><circle cx="12" cy="17" r="1"/><path d="M10.29 3.86L1.82 18a2 2 0 001.71 3h16.94a2 2 0 001.71-3L13.71 3.86a2 2 0 00-3.42 0z" strokeLinecap="round" strokeLinejoin="round"/></svg>
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
                <svg viewBox="0 0 24 24" className="h-4 w-4" fill="none" stroke="currentColor" strokeWidth="1.8" aria-hidden="true"><path d="M5 12h14" strokeLinecap="round" strokeLinejoin="round"/><path d="M12 5v14" strokeLinecap="round" strokeLinejoin="round"/></svg>
                Ya, Simpan Perubahan
              </button>
            </div>
          </div>
        </div>
      )}
    </main>
  );
}
