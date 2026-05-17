"use client";

import { FormEvent, useEffect, useState } from "react";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import api from "@/lib/api";

interface ThresholdForm {
  normalMaxCm: number;
  warningMinCm: number;
  warningMaxCm: number;
  dangerMinCm: number;
  rainLightMax: number;
  rainModerateMax: number;
  rainHeavyMin: number;
  autoBroadcast: boolean;
}

export default function AdminThresholdsPage() {
  const [sensorCount, setSensorCount] = useState(0);
  const [autoBroadcastCount, setAutoBroadcastCount] = useState(0);
  const [saved, setSaved] = useState(false);
  const [loading, setLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const [form, setForm] = useState<ThresholdForm>({
    normalMaxCm: 150,
    warningMinCm: 151,
    warningMaxCm: 250,
    dangerMinCm: 251,
    rainLightMax: 5,
    rainModerateMax: 20,
    rainHeavyMin: 21,
    autoBroadcast: false,
  });

  const loadData = async () => {
    setErrorMessage(null);
    try {
      const [thresholdResp, sensorResp] = await Promise.all([
        api.get("/thresholds"),
        api.get("/sensors"),
      ]);

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
      const sensors = (Array.isArray(sensorPayload)
        ? sensorPayload
        : sensorPayload?.items ?? []) as Array<{ id: string }>;
      setSensorCount(sensors.length);

      const waterLevel = thresholdData?.waterLevel;
      const rainfall = thresholdData?.rainfall;

      if (waterLevel && rainfall) {
        setForm((prev) => ({
          ...prev,
          normalMaxCm: waterLevel.normal.max,
          warningMinCm: waterLevel.warning.min,
          warningMaxCm: waterLevel.warning.max,
          dangerMinCm: waterLevel.danger.min,
          rainLightMax: rainfall.light.max,
          rainModerateMax: rainfall.moderate.max,
          rainHeavyMin: rainfall.heavy.min,
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

  const onSubmit = async (event: FormEvent) => {
    event.preventDefault();
    setSaved(false);
    setErrorMessage(null);
    try {
      await api.put("/thresholds", {
        waterLevel: {
          normal: { min: 0, max: form.normalMaxCm },
          warning: { min: form.warningMinCm, max: form.warningMaxCm },
          danger: { min: form.dangerMinCm, max: null },
        },
        rainfall: {
          light: { min: 0, max: form.rainLightMax },
          moderate: { min: form.rainLightMax + 0.1, max: form.rainModerateMax },
          heavy: { min: form.rainHeavyMin, max: null },
        },
      });
      setSaved(true);
      setAutoBroadcastCount(form.autoBroadcast ? sensorCount : 0);
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : "Gagal menyimpan ambang batas.");
    }
  };

  return (
    <main className="space-y-6">
      <Card className="relative overflow-hidden border-blue-500/30 bg-linear-to-r from-blue-600 via-blue-600 to-cyan-600 text-white shadow-lg shadow-blue-900/20">
        <div className="absolute -right-2 top-4 h-24 w-24 rounded-3xl border border-white/20 bg-white/10" />
        <div className="relative z-10 space-y-1.5">
          <h1 className="text-2xl font-bold tracking-tight">Ambang Batas (Threshold Settings)</h1>
          <p className="max-w-2xl text-sm text-blue-50/95">Atur level ketinggian air dan curah hujan per sensor untuk logika notifikasi otomatis.</p>
        </div>
      </Card>

      <div className="grid gap-4 md:grid-cols-3">
        <Card className="border-slate-200 bg-white/95 shadow-sm">
          <p className="text-sm text-slate-500">Sensor Terkonfigurasi</p>
          <p className="mt-1 text-3xl font-bold text-slate-900">{sensorCount}</p>
          <p className="text-xs text-slate-500">Sudah memiliki rule threshold</p>
        </Card>
        <Card className="border-slate-200 bg-white/95 shadow-sm">
          <p className="text-sm text-slate-500">Auto Broadcast Aktif</p>
          <p className="mt-1 text-3xl font-bold text-blue-600">{autoBroadcastCount}</p>
          <p className="text-xs text-slate-500">Sensor siap kirim peringatan otomatis</p>
        </Card>
        <Card className="border-slate-200 bg-white/95 shadow-sm">
          <p className="text-sm text-slate-500">Mode Konfigurasi</p>
          <p className="mt-1 truncate text-xl font-bold text-cyan-700">Global</p>
          <p className="text-xs text-slate-500">Berlaku untuk seluruh sensor</p>
        </Card>
      </div>

      {loading && <p className="text-sm text-slate-500">Memuat konfigurasi ambang batas...</p>}
      {errorMessage && <p className="text-sm font-medium text-rose-600">{errorMessage}</p>}

      <Card className="border-slate-200 bg-white/95 shadow-md shadow-slate-200/40">
        <div className="mb-4">
          <h2 className="text-lg font-semibold text-slate-900">Form Pengaturan Ambang Batas</h2>
          <p className="text-sm text-slate-500">Pastikan konfigurasi level air dan hujan sesuai kondisi lapangan tiap sensor.</p>
        </div>
        <form onSubmit={onSubmit} className="space-y-5">
          <p className="text-sm text-slate-600">Pengaturan ini disimpan di database dan diterapkan sebagai threshold global.</p>

          <div>
            <h2 className="mb-2 text-sm font-semibold text-slate-800">Konfigurasi Ketinggian Air</h2>
            <div className="grid gap-3 md:grid-cols-3">
              <label className="text-sm text-slate-700">
                Level Normal (Hijau) Maks (cm)
                <input
                  type="number"
                  value={form.normalMaxCm}
                  onChange={(event) => setForm((prev) => ({ ...prev, normalMaxCm: Number(event.target.value) }))}
                  className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
                />
              </label>

              <label className="text-sm text-slate-700">
                Level Waspada Min (cm)
                <input
                  type="number"
                  value={form.warningMinCm}
                  onChange={(event) => setForm((prev) => ({ ...prev, warningMinCm: Number(event.target.value) }))}
                  className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
                />
              </label>

              <label className="text-sm text-slate-700">
                Level Waspada Maks (cm)
                <input
                  type="number"
                  value={form.warningMaxCm}
                  onChange={(event) => setForm((prev) => ({ ...prev, warningMaxCm: Number(event.target.value) }))}
                  className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
                />
              </label>

              <label className="text-sm text-slate-700 md:col-span-3">
                Level Bahaya (Merah) Min (cm)
                <input
                  type="number"
                  value={form.dangerMinCm}
                  onChange={(event) => setForm((prev) => ({ ...prev, dangerMinCm: Number(event.target.value) }))}
                  className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2 md:max-w-xs"
                />
              </label>
            </div>
          </div>

          <div>
            <h2 className="mb-2 text-sm font-semibold text-slate-800">Konfigurasi Curah Hujan (mm/jam)</h2>
            <div className="grid gap-3 md:grid-cols-3">
              <label className="text-sm text-slate-700">
                Ringan (Maks)
                <input
                  type="number"
                  value={form.rainLightMax}
                  onChange={(event) => setForm((prev) => ({ ...prev, rainLightMax: Number(event.target.value) }))}
                  className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
                />
              </label>
              <label className="text-sm text-slate-700">
                Sedang (Maks)
                <input
                  type="number"
                  value={form.rainModerateMax}
                  onChange={(event) => setForm((prev) => ({ ...prev, rainModerateMax: Number(event.target.value) }))}
                  className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
                />
              </label>
              <label className="text-sm text-slate-700">
                Lebat (Min)
                <input
                  type="number"
                  value={form.rainHeavyMin}
                  onChange={(event) => setForm((prev) => ({ ...prev, rainHeavyMin: Number(event.target.value) }))}
                  className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
                />
              </label>
            </div>
          </div>

          <label className="flex items-center justify-between rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-700">
            <span>Aktifkan Auto-Broadcast saat mencapai Level Bahaya</span>
            <button
              type="button"
              onClick={() => setForm((prev) => ({ ...prev, autoBroadcast: !prev.autoBroadcast }))}
              aria-label="Toggle auto broadcast"
              className={`relative inline-flex h-7 w-12 items-center rounded-full transition-colors ${
                form.autoBroadcast ? "bg-blue-600" : "bg-slate-300"
              }`}
            >
              <span
                className={`inline-block h-5 w-5 transform rounded-full bg-white transition-transform ${
                  form.autoBroadcast ? "translate-x-6" : "translate-x-1"
                }`}
              />
            </button>
          </label>

          <div className="flex items-center gap-3">
            <Button type="submit">Simpan Konfigurasi</Button>
            {saved && <p className="text-sm text-emerald-600">Perubahan ambang batas berhasil disimpan.</p>}
          </div>
        </form>
      </Card>
    </main>
  );
}
