"use client";

import { FormEvent, useEffect, useMemo, useState } from "react";
import type { Sensor, SensorConnectivity, SensorType } from "@/types/sensor";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { ConfirmDialog } from "@/components/ui/ConfirmDialog";
import { Modal } from "@/components/ui/Modal";
import { StatusIndicator } from "@/components/ui/StatusIndicator";
import { cn, formatRelativeTime, formatTimestamp, isSensorOnline, SENSOR_OFFLINE_THRESHOLD_MS } from "@/lib/utils";
import { useWaterLevel } from "@/hooks/useWaterLevel";
import api from "@/lib/api";

interface SensorFormState {
  id: string;
  name: string;
  riverName: string;
  latitude: number;
  longitude: number;
  zeroCalibrationCm: number;
  batteryPercent: number;
  connectivity: SensorConnectivity;
  lastLevelCm: number;
  type: SensorType;
}

interface SensorMutationPayload {
  sensorId: string;
  name: string;
  type: SensorType;
  latitude: number;
  longitude: number;
  batteryLevel: number;
  connectivity: "ONLINE" | "OFFLINE";
}

const emptyForm: SensorFormState = {
  id: "",
  name: "",
  riverName: "",
  latitude: -0.95,
  longitude: 100.37,
  zeroCalibrationCm: 200,
  batteryPercent: 100,
  connectivity: "online",
  lastLevelCm: 0,
  type: "WATER_LEVEL",
};

const POLL_REFRESH_MS = 12_000;

function batteryTone(percent: number) {
  if (percent > 50) return { fill: "bg-emerald-500", text: "text-emerald-700" };
  if (percent > 20) return { fill: "bg-amber-400", text: "text-amber-700" };
  return { fill: "bg-rose-500", text: "text-rose-700" };
}

function connectionTone(isOnline: boolean) {
  return isOnline
    ? {
        badge: "border-emerald-200 bg-emerald-50 text-emerald-700",
        dot: "bg-emerald-500",
        ping: "bg-emerald-400",
      }
    : {
        badge: "border-rose-200 bg-rose-50 text-rose-700",
        dot: "bg-rose-500",
        ping: "bg-rose-400",
      };
}

function connectionIcon(isOnline: boolean) {
  const tone = connectionTone(isOnline);

  return (
    <span className="relative inline-flex h-3 w-3">
      {isOnline && <span className={cn("absolute inline-flex h-full w-full rounded-full opacity-75 animate-ping", tone.ping)} />}
      <span className={cn("relative inline-flex h-3 w-3 rounded-full", tone.dot)} />
    </span>
  );
}

function iconButtonClass(isDestructive = false) {
  return cn(
    "inline-flex items-center gap-2 rounded-lg border px-3 py-2 text-xs font-semibold transition-colors",
    isDestructive
      ? "border-rose-200 bg-white text-rose-700 hover:bg-rose-50"
      : "border-slate-200 bg-white text-slate-700 hover:bg-slate-50",
  );
}

function getErrorMessage(err: unknown) {
  if (err instanceof Error) {
    return err.message;
  }

  if (typeof err === "object" && err !== null && "message" in err) {
    const message = (err as { message?: unknown }).message;
    if (typeof message === "string") {
      return message;
    }
  }

  return "";
}

function StatIcon({ kind }: { kind: "total" | "conn" | "risk" | "battery" }) {
  const className = "h-8 w-8";

  if (kind === "total") {
    return (
      <svg className={className} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M12 18c1.657 0 3-1.343 3-3" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
        <path d="M5 12a9 9 0 0114 0" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
        <circle cx="12" cy="20" r="1" fill="currentColor" />
      </svg>
    );
  }

  if (kind === "conn") {
    return (
      <svg className={className} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M5 12.55a7 7 0 0114 0" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
        <path d="M8.5 15.05a4 4 0 016.99 0" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
        <circle cx="12" cy="18" r="1" fill="currentColor" />
      </svg>
    );
  }

  if (kind === "risk") {
    return (
      <svg className={className} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M12 9v4" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
        <path d="M12 17h.01" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
        <path d="M10.29 3.86L1.82 19.14A2 2 0 003.59 22h16.82a2 2 0 001.77-2.86L13.71 3.86a2 2 0 00-3.42 0z" stroke="currentColor" strokeWidth="1.2" />
      </svg>
    );
  }

  return (
    <svg className={className} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
      <rect x="2" y="7" width="18" height="10" rx="2" stroke="currentColor" strokeWidth="1.5" />
      <rect x="20" y="10" width="2" height="4" rx="1" fill="currentColor" />
    </svg>
  );
}

export default function AdminSensorsPage() {
  const { sensorsSnapshot: sensors, liveBySensor, isLoading, error, reload } = useWaterLevel({ refreshMs: POLL_REFRESH_MS, showAll: true });
  const [open, setOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [savedMessage, setSavedMessage] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [form, setForm] = useState<SensorFormState>(emptyForm);
  const [deleteConfirm, setDeleteConfirm] = useState<{ id: string; name: string } | null>(null);
  const [nowMs, setNowMs] = useState(() => Date.now());

  const liveDataMap = useMemo(() => {
    return new Map((liveBySensor || []).map((item) => [item.sensorId, item]));
  }, [liveBySensor]);

  useEffect(() => {
    const timer = window.setInterval(() => setNowMs(Date.now()), 30_000);
    return () => window.clearInterval(timer);
  }, []);

  // Data is provided by `useWaterLevel` hook (shared with landing page). Use `reload()` after mutations.

  const modalTitle = editingId ? "Edit Sensor" : "Tambah Sensor";

  const sensorHealth = sensors.map((sensor) => {
    const online = isSensorOnline(sensor.lastSeenAt ?? sensor.updatedAt, nowMs);
    return { ...sensor, online };
  });

  const onlineCount = sensorHealth.filter((sensor) => sensor.online).length;
  const offlineCount = sensorHealth.length - onlineCount;
  const alertCount = sensorHealth.filter((sensor) => sensor.status === "alert").length;
  const dangerCount = sensorHealth.filter((sensor) => sensor.status === "danger").length;
  const validBatterySensors = sensorHealth.filter((s) => s.batteryPercent > 0);
  const avgBattery = validBatterySensors.length > 0
    ? Math.round(validBatterySensors.reduce((sum, s) => sum + s.batteryPercent, 0) / validBatterySensors.length)
    : 0;
  const allOnline = sensorHealth.length > 0 && offlineCount === 0;
  const connectionToneClass = allOnline ? "text-emerald-700" : offlineCount > Math.ceil(sensorHealth.length / 2) ? "text-rose-700" : "text-amber-700";
  const riskToneClass = dangerCount > 0 ? "text-rose-700" : alertCount > 0 ? "text-amber-700" : "text-emerald-700";
  const batteryToneClass = avgBattery > 50 ? "text-emerald-700" : avgBattery > 20 ? "text-amber-700" : "text-rose-700";
  const connectionDescription = allOnline ? "Semua sensor aktif" : `${offlineCount} sensor offline`;
  const riskDescription = dangerCount > 0 ? `${dangerCount} sensor bahaya` : alertCount > 0 ? `${alertCount} sensor waspada` : "Semua sensor aman";
  const batteryDescription = avgBattery > 50 ? "Daya masih aman" : avgBattery > 20 ? "Perlu perhatian" : "Wajib cek baterai";
  const hasError = Boolean(error);

  const mapPreviewUrl = useMemo(
    () => `https://maps.google.com/maps?q=${form.latitude},${form.longitude}&z=14&output=embed`,
    [form.latitude, form.longitude],
  );

  // Auto-dismiss success and error alerts after 5 seconds for a premium feel
  useEffect(() => {
    if (savedMessage) {
      const timer = setTimeout(() => setSavedMessage(null), 5000);
      return () => clearTimeout(timer);
    }
  }, [savedMessage]);

  useEffect(() => {
    if (errorMessage) {
      const timer = setTimeout(() => setErrorMessage(null), 5000);
      return () => clearTimeout(timer);
    }
  }, [errorMessage]);

  const openCreate = () => {
    setEditingId(null);
    setForm(emptyForm);
    setSavedMessage(null);
    setOpen(true);
  };

  const openEdit = (sensor: Sensor) => {
    setEditingId(sensor.id);
    setForm({
      id: sensor.id,
      name: sensor.name,
      riverName: sensor.riverName || sensor.name,
      latitude: sensor.latitude,
      longitude: sensor.longitude,
      zeroCalibrationCm: 200,
      batteryPercent: sensor.batteryPercent,
      connectivity: sensor.connectivity,
      lastLevelCm: sensor.lastLevelCm,
      type: sensor.type || "WATER_LEVEL",
    });
    setSavedMessage(null);
    setOpen(true);
  };

  const handleAddSubmit = async (payload: SensorMutationPayload) => {
    setSavedMessage(null);
    setErrorMessage(null);
    try {
      await api.post("/sensors", payload);
      setSavedMessage("Sensor baru berhasil ditambahkan.");
      setOpen(false);
      reload();
    } catch (err: unknown) {
      const rawMsg = getErrorMessage(err);
      let friendlyMsg = "Gagal menambahkan sensor baru.";
      if (rawMsg.includes("Unique constraint failed") || rawMsg.includes("sensor_id")) {
        friendlyMsg = "ID Perangkat (MAC Address/UUID) sudah terdaftar. Silakan gunakan ID unik yang lain.";
      } else if (rawMsg) {
        friendlyMsg = rawMsg;
      }
      setErrorMessage(friendlyMsg);
    }
  };

  const handleEditSubmit = async (id: string, payload: SensorMutationPayload) => {
    setSavedMessage(null);
    setErrorMessage(null);
    try {
      await api.patch(`/sensors/${id}`, payload);
      setSavedMessage("Data sensor berhasil diperbarui.");
      setOpen(false);
      reload();
    } catch (err: unknown) {
      const rawMsg = getErrorMessage(err);
      let friendlyMsg = "Gagal memperbarui sensor.";
      if (rawMsg.includes("Unique constraint failed") || rawMsg.includes("sensor_id")) {
        friendlyMsg = "ID Perangkat (MAC Address/UUID) sudah terdaftar. Silakan gunakan ID unik yang lain.";
      } else if (rawMsg) {
        friendlyMsg = rawMsg;
      }
      setErrorMessage(friendlyMsg);
    }
  };

  const handleDelete = async (id: string) => {
    setSavedMessage(null);
    setErrorMessage(null);
    try {
      await api.delete(`/sensors/${id}`);
      setSavedMessage("Sensor berhasil dihapus.");
      reload();
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : "Gagal menghapus sensor.");
    }
  };

  const submitForm = async (event: FormEvent) => {
    event.preventDefault();
    const payload: SensorMutationPayload = {
      sensorId: form.id,
      name: form.name,
      type: form.type,
      latitude: form.latitude,
      longitude: form.longitude,
      batteryLevel: form.batteryPercent,
      connectivity: form.connectivity === "online" ? "ONLINE" : "OFFLINE",
    };

    if (editingId) {
      await handleEditSubmit(editingId, payload);
    } else {
      await handleAddSubmit(payload);
    }
  };

  const renderSkeleton = () => (
    <>
      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        {Array.from({ length: 4 }).map((_, index) => (
          <div key={index} className="animate-pulse rounded-xl border border-slate-200 bg-white/80 p-4 shadow-sm">
            <div className="flex items-start justify-between gap-4">
              <div className="space-y-3">
                <div className="h-3 w-20 rounded bg-slate-100" />
                <div className="h-8 w-16 rounded bg-slate-100" />
                <div className="h-3 w-28 rounded bg-slate-100" />
              </div>
              <div className="h-10 w-10 rounded-lg bg-slate-100" />
            </div>
          </div>
        ))}
      </div>

      <Card className="border-slate-200 bg-white/80 p-0 shadow-sm backdrop-blur-xl">
        <div className="border-b border-slate-200 px-5 py-4">
          <div className="h-5 w-44 animate-pulse rounded bg-slate-100" />
          <div className="mt-2 h-4 w-72 animate-pulse rounded bg-slate-100" />
        </div>
        <div className="divide-y divide-slate-200">
          {Array.from({ length: 5 }).map((_, index) => (
            <div key={index} className="grid gap-4 p-5 lg:grid-cols-[2.2fr_1.15fr_1.1fr_1.1fr_1.2fr_1fr]">
              <div className="space-y-3">
                <div className="h-4 w-40 animate-pulse rounded bg-slate-100" />
                <div className="h-3 w-24 animate-pulse rounded bg-slate-100" />
                <div className="h-5 w-28 animate-pulse rounded-full bg-slate-100" />
              </div>
              <div className="space-y-2">
                <div className="h-3 w-28 animate-pulse rounded bg-slate-100" />
                <div className="h-6 w-28 animate-pulse rounded bg-slate-100" />
              </div>
              <div className="space-y-2">
                <div className="h-3 w-24 animate-pulse rounded bg-slate-100" />
                <div className="h-6 w-24 animate-pulse rounded-full bg-slate-100" />
              </div>
              <div className="space-y-2">
                <div className="h-3 w-24 animate-pulse rounded bg-slate-100" />
                <div className="h-3 w-full animate-pulse rounded bg-slate-100" />
                <div className="h-3 w-12 animate-pulse rounded bg-slate-100" />
              </div>
              <div className="space-y-2">
                <div className="h-3 w-28 animate-pulse rounded bg-slate-100" />
                <div className="h-4 w-32 animate-pulse rounded bg-slate-100" />
              </div>
              <div className="space-y-2">
                <div className="h-9 w-full animate-pulse rounded-lg bg-slate-100" />
                <div className="h-9 w-full animate-pulse rounded-lg bg-slate-100" />
              </div>
            </div>
          ))}
        </div>
      </Card>
    </>
  );

  const renderErrorState = () => (
    <Card className="border-rose-200 bg-rose-50/80 shadow-sm backdrop-blur-xl">
      <div className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
        <div className="space-y-1">
          <p className="text-sm font-semibold uppercase tracking-[0.2em] text-rose-700">Gagal Memuat Data</p>
          <h3 className="text-lg font-semibold text-rose-900">Koneksi data sensor sedang bermasalah</h3>
          <p className="max-w-2xl text-sm text-rose-700">
            {error || errorMessage || "Terjadi gangguan saat memuat sensor. Silakan coba lagi beberapa saat."}
          </p>
        </div>
        <Button onClick={() => reload()} className="bg-white text-rose-700 hover:bg-rose-50">
          Coba Lagi
        </Button>
      </div>
    </Card>
  );

  return (
    <main className="space-y-6">
      <Card className="overflow-hidden border-slate-200/70 bg-white/80 shadow-sm backdrop-blur-xl">
        <div className="flex flex-wrap items-start justify-between gap-4">
          <div className="space-y-2">
            <p className="text-xs font-semibold uppercase tracking-[0.28em] text-blue-700">Command Center</p>
            <div>
              <h1 className="text-2xl font-bold tracking-tight text-slate-900">Manajemen Sensor IoT</h1>
              <p className="max-w-2xl text-sm text-slate-600">
                Pantau status koneksi, ingest terakhir, kesehatan baterai, dan ketinggian air dari ESP8266 secara real-time.
              </p>
            </div>
          </div>
          <div className="flex flex-wrap items-center gap-2">
            <span className="rounded-full border border-slate-200 bg-white px-3 py-1 text-xs font-semibold text-slate-600 shadow-sm">
              Polling aman tiap {Math.round(POLL_REFRESH_MS / 1000)} detik
            </span>
            <Button onClick={openCreate} className="bg-blue-600 text-white shadow-sm hover:bg-blue-700">
              Tambah Sensor
            </Button>
          </div>
        </div>
      </Card>

      {isLoading ? (
        renderSkeleton()
      ) : hasError ? (
        renderErrorState()
      ) : (
        <>
          <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
            <Card className="rounded-xl border-slate-200/70 bg-white/80 p-4 shadow-sm backdrop-blur-xl">
              <div className="flex items-start justify-between gap-4">
                <div>
                  <p className="text-sm text-slate-500">Total Sensor</p>
                  <p className="mt-1 text-3xl font-bold text-slate-900">{sensorHealth.length}</p>
                  <p className="text-xs text-slate-500">Perangkat terdaftar</p>
                </div>
                <div className="rounded-lg bg-slate-50 p-2 text-slate-700 shadow-sm">
                  <StatIcon kind="total" />
                </div>
              </div>
            </Card>

            <Card className="rounded-xl border-slate-200/70 bg-white/80 p-4 shadow-sm backdrop-blur-xl">
              <div className="flex items-start justify-between gap-4">
                <div>
                  <p className="text-sm text-slate-500">Koneksi</p>
                  <p className={cn("mt-1 text-3xl font-bold", connectionToneClass)}>{onlineCount}</p>
                  <p className="text-xs text-slate-500">{connectionDescription}</p>
                </div>
                <div className={cn("rounded-lg bg-slate-50 p-2 shadow-sm", connectionToneClass)}>
                  <StatIcon kind="conn" />
                </div>
              </div>
            </Card>

            <Card className="rounded-xl border-slate-200/70 bg-white/80 p-4 shadow-sm backdrop-blur-xl">
              <div className="flex items-start justify-between gap-4">
                <div>
                  <p className="text-sm text-slate-500">Status Risiko</p>
                  <p className={cn("mt-1 text-3xl font-bold", riskToneClass)}>{alertCount}</p>
                  <p className="text-xs text-slate-500">{riskDescription}</p>
                </div>
                <div className={cn("rounded-lg bg-slate-50 p-2 shadow-sm", riskToneClass)}>
                  <StatIcon kind="risk" />
                </div>
              </div>
            </Card>

            <Card className="rounded-xl border-slate-200/70 bg-white/80 p-4 shadow-sm backdrop-blur-xl">
              <div className="flex items-start justify-between gap-4">
                <div>
                  <p className="text-sm text-slate-500">Rata-rata Baterai</p>
                  <p className={cn("mt-1 text-3xl font-bold", batteryToneClass)}>
                    {validBatterySensors.length > 0 ? `${avgBattery}%` : "N/A"}
                  </p>
                  <p className="text-xs text-slate-500">
                    {validBatterySensors.length > 0 ? batteryDescription : "Perangkat tidak mengirim data baterai"}
                  </p>
                </div>
                <div className={cn("rounded-lg bg-slate-50 p-2 shadow-sm", batteryToneClass)}>
                  <StatIcon kind="battery" />
                </div>
              </div>
            </Card>
          </div>

          {savedMessage && (
            <Card className="border-emerald-200 bg-emerald-50/80 py-3 shadow-sm">
              <p className="text-sm font-medium text-emerald-700">{savedMessage}</p>
            </Card>
          )}

          {errorMessage && (
            <Card className="border-rose-200 bg-rose-50/80 py-3 shadow-sm">
              <p className="text-sm font-medium text-rose-700">{errorMessage}</p>
            </Card>
          )}

          <section className="space-y-4">
            <div className="flex flex-wrap items-end justify-between gap-3">
              <div>
                <h2 className="text-lg font-semibold text-slate-900">Daftar Sensor</h2>
                <p className="text-sm text-slate-500">
                  Status koneksi ditentukan dari {Math.round(SENSOR_OFFLINE_THRESHOLD_MS / 60000)} menit terakhir, jadi admin langsung tahu sensor mana yang benar-benar hidup.
                </p>
              </div>
              <div className="rounded-full border border-slate-200 bg-white/80 px-3 py-1 text-xs font-semibold text-slate-600 shadow-sm backdrop-blur-xl">
                {sensorHealth.length} sensor aktif
              </div>
            </div>

            <Card className="overflow-hidden border-slate-200/70 bg-white/80 p-0 shadow-sm backdrop-blur-xl">
              <div className="hidden grid-cols-[2.3fr_1.25fr_1.1fr_1.1fr_1.25fr_1fr] gap-4 border-b border-slate-200 px-5 py-4 text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 lg:grid">
                <div>Sensor</div>
                <div>Pembacaan Terakhir</div>
                <div>Status Koneksi</div>
                <div>Sisa Baterai</div>
                <div>Terakhir Update</div>
                <div className="text-right">Aksi</div>
              </div>

              <div className="divide-y divide-slate-200">
                {sensorHealth.map((sensor) => {
                  const online = sensor.online;
                  const tone = connectionTone(online);
                  const battery = batteryTone(sensor.batteryPercent);
                  const lastSeen = sensor.lastSeenAt ?? sensor.updatedAt;
                  const exactTimestamp = lastSeen ? formatTimestamp(lastSeen) : "Belum ada ingest";
                  const relativeTime = formatRelativeTime(lastSeen, nowMs);

                  return (
                    <div key={sensor.id} className="grid gap-4 px-5 py-4 lg:grid-cols-[2.3fr_1.25fr_1.1fr_1.1fr_1.25fr_1fr] lg:items-center">
                      <div className="space-y-2">
                        <div className="flex flex-wrap items-center gap-2">
                          <h3 className="text-base font-semibold text-slate-900">{sensor.name}</h3>
                          <span className="rounded-full border border-slate-200 bg-slate-50 px-2 py-0.5 text-[11px] font-mono text-slate-500">
                            {sensor.id}
                          </span>
                          <StatusIndicator status={sensor.status} />
                        </div>
                        <p className="text-sm text-slate-500">{sensor.riverName}</p>
                        <p className="text-xs text-slate-500">
                          {sensor.latitude.toFixed(4)}, {sensor.longitude.toFixed(4)}
                        </p>
                      </div>

                      <div className="space-y-2">
                        <p className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500 lg:hidden">Pembacaan Terakhir</p>
                        {(() => {
                          const live = liveDataMap.get(sensor.id);
                          const hasData = sensor.lastSeenAt !== null;
                          if (!hasData) {
                            return (
                              <span className="inline-flex rounded-full border border-slate-200 bg-slate-50 px-3 py-1.5 text-xs font-semibold text-slate-500 shadow-sm animate-pulse">
                                Menunggu Data
                              </span>
                            );
                          }
                          
                          let formattedValue = "";
                          if (sensor.type === "RAINFALL") {
                            const val = live?.rainfallMm ?? 0;
                            formattedValue = `${val.toFixed(1)} mm/jam`;
                          } else if (sensor.type === "FLOW_RATE") {
                            const val = live?.flowRateLpm ?? 0;
                            formattedValue = `${val.toFixed(1)} L/min`;
                          } else {
                            const val = live?.levelCm ?? sensor.lastLevelCm;
                            formattedValue = `${val.toFixed(1)} cm`;
                          }

                          return (
                            <div className="inline-flex items-center gap-2 rounded-full border border-slate-200 bg-slate-50 px-3 py-1.5 text-sm font-semibold text-slate-900 shadow-sm">
                              <span>{formattedValue}</span>
                            </div>
                          );
                        })()}
                      </div>

                      <div className="space-y-2">
                        <p className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500 lg:hidden">Status Koneksi</p>
                        <span className={cn("inline-flex items-center gap-2 rounded-full border px-3 py-1.5 text-xs font-semibold shadow-sm", tone.badge)}>
                          {connectionIcon(online)}
                          {online ? "Online" : "Offline"}
                        </span>
                      </div>

                      <div className="space-y-2">
                        <p className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500 lg:hidden">Sisa Baterai</p>
                        {sensor.batteryPercent === 0 ? (
                          <span className="inline-flex rounded-full border border-slate-200 bg-slate-50 px-3 py-1 text-xs font-semibold text-slate-400 shadow-sm">
                            N/A
                          </span>
                        ) : (
                          <div className="space-y-2">
                            <div className="flex items-center justify-between text-xs text-slate-500">
                              <span>{sensor.batteryPercent}%</span>
                              <span className={battery.text}>{sensor.batteryPercent > 50 ? "Aman" : sensor.batteryPercent > 20 ? "Waspada" : "Kritis"}</span>
                            </div>
                            <div className="h-2.5 w-full rounded-full bg-slate-100">
                              <div
                                className={cn("h-2.5 rounded-full transition-all", battery.fill)}
                                style={{ width: `${Math.max(0, Math.min(100, sensor.batteryPercent))}%` }}
                              />
                            </div>
                          </div>
                        )}
                      </div>

                      <div className="space-y-2">
                        <p className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500 lg:hidden">Terakhir Update</p>
                        <div>
                          <p className="text-sm font-semibold text-slate-900">{relativeTime}</p>
                          <p className="text-xs text-slate-500" title={exactTimestamp}>
                            {exactTimestamp}
                          </p>
                        </div>
                      </div>

                      <div className="flex flex-wrap gap-2 lg:justify-end">
                        <button type="button" onClick={() => openEdit(sensor)} className={iconButtonClass()}>
                          <svg className="h-4 w-4" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                            <path d="M14 4l6 6-10 10H4v-6L14 4z" stroke="currentColor" strokeWidth="1.4" strokeLinecap="round" strokeLinejoin="round" />
                          </svg>
                          Edit
                        </button>
                        <button type="button" onClick={() => setDeleteConfirm({ id: sensor.id, name: sensor.name })} className={iconButtonClass(true)}>
                          <svg className="h-4 w-4" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                            <path d="M4 7h16" stroke="currentColor" strokeWidth="1.4" strokeLinecap="round" />
                            <path d="M9 7V5.5A1.5 1.5 0 0110.5 4h3A1.5 1.5 0 0115 5.5V7" stroke="currentColor" strokeWidth="1.4" strokeLinecap="round" />
                            <path d="M7 7l1 13h8l1-13" stroke="currentColor" strokeWidth="1.4" strokeLinecap="round" />
                          </svg>
                          Hapus
                        </button>
                      </div>
                    </div>
                  );
                })}
              </div>
            </Card>
          </section>
        </>
      )}

      <Modal open={open} title={modalTitle} onClose={() => setOpen(false)}>
        <form onSubmit={submitForm} className="space-y-4">
          {errorMessage && (
            <div className="rounded-xl border border-rose-200 bg-rose-50 p-3.5 text-sm text-rose-700">
              <p className="font-semibold flex items-center gap-2">
                <svg className="h-4.5 w-4.5 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                </svg>
                Gagal Menyimpan
              </p>
              <p className="mt-1 text-xs text-rose-600">{errorMessage}</p>
            </div>
          )}
          <label className="block text-sm font-medium text-slate-700">
            ID Perangkat (MAC Address/UUID)
            <input
              required
              value={form.id}
              disabled={Boolean(editingId)}
              onChange={(event) => setForm((prev) => ({ ...prev, id: event.target.value }))}
              className="mt-1.5 w-full rounded-xl border border-slate-200 px-3.5 py-2.5 text-sm transition-all focus:border-blue-500 focus:outline-none disabled:bg-slate-50 disabled:text-slate-500 disabled:cursor-not-allowed"
              placeholder="ESP32-UUID-001"
            />
          </label>

          <label className="block text-sm font-medium text-slate-700">
            Nama Lokasi
            <input
              required
              value={form.name}
              onChange={(event) => setForm((prev) => ({ ...prev, name: event.target.value }))}
              className="mt-1.5 w-full rounded-xl border border-slate-200 px-3.5 py-2.5 text-sm transition-all focus:border-blue-500 focus:outline-none"
              placeholder="Hulu Sungai Jembatan X"
            />
          </label>

          <div className="grid gap-3 sm:grid-cols-2">
            <label className="block text-sm font-medium text-slate-700">
              Tipe Sensor
              <select
                value={form.type}
                onChange={(event) => setForm((prev) => ({ ...prev, type: event.target.value as SensorType }))}
                className="mt-1.5 w-full rounded-xl border border-slate-200 px-3.5 py-2.5 text-sm bg-white text-slate-900 focus:border-blue-500 focus:outline-none"
              >
                <option value="WATER_LEVEL">Water Level (Tinggi Air)</option>
                <option value="RAINFALL">Rainfall (Curah Hujan)</option>
                <option value="FLOW_RATE">Flow Rate (Debit Aliran)</option>
              </select>
            </label>

            <label className="block text-sm font-medium text-slate-700">
              Nama Sungai/Area
              <input
                required
                value={form.riverName}
                onChange={(event) => setForm((prev) => ({ ...prev, riverName: event.target.value }))}
                className="mt-1.5 w-full rounded-xl border border-slate-200 px-3.5 py-2.5 text-sm focus:border-blue-500 focus:outline-none"
                placeholder="Batang Arau"
              />
            </label>
          </div>

          <div className="grid gap-3 sm:grid-cols-2">
            <label className="text-sm font-medium text-slate-700">
              Latitude
              <input
                type="number"
                step="0.000001"
                required
                value={form.latitude}
                onChange={(event) => setForm((prev) => ({ ...prev, latitude: Number(event.target.value) }))}
                className="mt-1.5 w-full rounded-xl border border-slate-200 px-3.5 py-2.5 text-sm focus:border-blue-500 focus:outline-none"
              />
            </label>
            <label className="text-sm font-medium text-slate-700">
              Longitude
              <input
                type="number"
                step="0.000001"
                required
                value={form.longitude}
                onChange={(event) => setForm((prev) => ({ ...prev, longitude: Number(event.target.value) }))}
                className="mt-1.5 w-full rounded-xl border border-slate-200 px-3.5 py-2.5 text-sm focus:border-blue-500 focus:outline-none"
              />
            </label>
          </div>

          {form.type === "WATER_LEVEL" && (
            <label className="block text-sm font-medium text-slate-700">
              Kalibrasi Nol (Tinggi Tangki/cm)
              <input
                type="number"
                required
                value={form.zeroCalibrationCm}
                onChange={(event) => setForm((prev) => ({ ...prev, zeroCalibrationCm: Number(event.target.value) }))}
                className="mt-1.5 w-full rounded-xl border border-slate-200 px-3.5 py-2.5 text-sm focus:border-blue-500 focus:outline-none"
                placeholder="200"
              />
            </label>
          )}

          <label className="block text-sm font-medium text-slate-700">
            Status Koneksi
            <select
              value={form.connectivity}
              onChange={(event) => setForm((prev) => ({ ...prev, connectivity: event.target.value as SensorConnectivity }))}
              className="mt-1.5 w-full rounded-xl border border-slate-200 px-3.5 py-2.5 text-sm bg-white text-slate-900 focus:border-blue-500 focus:outline-none"
            >
              <option value="online">Online</option>
              <option value="offline">Offline</option>
            </select>
          </label>

          <div>
            <p className="mb-1 text-sm font-medium text-slate-700">Pratinjau Lokasi (Mini Map)</p>
            <iframe
              title="Mini map koordinat sensor"
              src={mapPreviewUrl}
              loading="lazy"
              className="h-38 w-full rounded-xl border border-slate-200"
            />
          </div>

          <div className="flex justify-end gap-2 pt-1">
            <Button type="button" variant="secondary" onClick={() => setOpen(false)}>
              Batal
            </Button>
            <Button type="submit">Simpan Sensor</Button>
          </div>
        </form>
      </Modal>

      <ConfirmDialog
        open={Boolean(deleteConfirm)}
        title="Hapus sensor ini?"
        description={`Apakah Anda yakin ingin menghapus sensor ${deleteConfirm?.name ?? "terpilih"}? Data histori dari sensor ini mungkin akan ikut terhapus.`}
        confirmText="Ya, hapus"
        cancelText="Batal"
        onCancel={() => setDeleteConfirm(null)}
        onConfirm={() => {
          const selected = deleteConfirm;
          setDeleteConfirm(null);
          if (selected) {
            void handleDelete(selected.id);
          }
        }}
      />
    </main>
  );
}
