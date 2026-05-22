"use client";

import { useMemo, useState } from "react";
import { Card } from "@/components/ui/Card";
import { StatusIndicator } from "@/components/ui/StatusIndicator";
import { WaterLevelChart } from "@/components/charts/WaterLevelChart";
import { RainfallChart } from "@/components/charts/RainfallChart";
import { FlowSpeedChart } from "@/components/charts/FlowSpeedChart";
import { useWaterLevel } from "@/hooks/useWaterLevel";
import { useFlowRate } from "@/hooks/useFlowRate";
import { cn, formatRelativeTime, formatTimestamp, getRainfallCategory, isSensorOnline } from "@/lib/utils";
import type { Sensor } from "@/types/sensor";
import type { WaterStatus } from "@/types/water-level";

function getThermometerColor(status: WaterStatus) {
  if (status === "danger") return "bg-rose-500";
  if (status === "alert") return "bg-orange-500";
  if (status === "warning") return "bg-amber-500";
  return "bg-emerald-500";
}

function connectionBadgeClass(online: boolean) {
  return online ? "border-emerald-200 bg-emerald-50 text-emerald-700" : "border-slate-200 bg-slate-100 text-slate-600";
}

const fallbackSensor: Sensor = {
  id: "SEN-01",
  name: "Sensor Utama",
  riverName: "Batang Arau",
  latitude: -0.9478,
  longitude: 100.3615,
  connectivity: "offline" as const,
  batteryPercent: 80,
  lastLevelCm: 120,
  hasWaterLevelData: false,
  lastSeenAt: null,
  status: "safe" as const,
  updatedAt: "2026-01-01T00:00:00.000Z",
};

const sideIndicators = [
  { label: "Hijau (Normal)", color: "bg-emerald-500", text: "Kondisi aman, lanjutkan pemantauan." },
  { label: "Kuning (Waspada)", color: "bg-amber-500", text: "Siapkan kebutuhan darurat dan pantau update." },
  { label: "Oranye (Siaga)", color: "bg-orange-500", text: "Siaga evakuasi parsial dan amankan barang." },
  { label: "Merah (Bahaya)", color: "bg-rose-600", text: "Lakukan evakuasi sesuai arahan petugas." },
];

export function PublicRealtimeDashboardSection() {
  const [selectedSensorId, setSelectedSensorId] = useState("SEN-01");
  const { latest, history, sensorsSnapshot } = useWaterLevel({ sensorId: selectedSensorId, refreshMs: 12_000, showAll: true });
  const { history: flowHistory } = useFlowRate();

  const sensorState = useMemo(
    () =>
      sensorsSnapshot.map((sensor) => ({
        ...sensor,
        online: isSensorOnline(sensor.lastSeenAt ?? sensor.updatedAt),
      })),
    [sensorsSnapshot],
  );

  const selectableSensors = useMemo(
    () => sensorState.filter((sensor) => sensor.type !== "FLOW_RATE"),
    [sensorState],
  );

  const selectedSensor = useMemo(
    () => selectableSensors.find((sensor) => sensor.id === latest.sensorId) ?? selectableSensors[0] ?? fallbackSensor,
    [latest.sensorId, selectableSensors],
  );

  const selectedSensorOnline = isSensorOnline(selectedSensor.lastSeenAt ?? selectedSensor.updatedAt);
  const selectedSensorHasData = selectedSensor.hasWaterLevelData ?? true;
  const rainfallCategory = getRainfallCategory(latest.rainfallMm);
  const thermometerPercent = Math.min(100, Math.round((latest.levelCm / 250) * 100));

  return (
    <section id="realtime-dashboard" className="scroll-mt-24 bg-white">
      <div className="mx-auto flex min-h-screen w-full max-w-6xl flex-col px-6 py-20 md:py-24">
        <div className="mb-8 max-w-3xl">
          <p className="text-sm font-semibold uppercase tracking-wide text-blue-700">Fitur Utama Publik</p>
          <h2 className="mt-2 text-3xl font-bold text-slate-900">Real-Time Dashboard Pemantauan Banjir</h2>
          <p className="mt-3 text-sm text-slate-600">
            Masyarakat dapat melihat peta sensor, data real-time, grafik tren ketinggian air, dan intensitas curah hujan
            secara langsung dari dashboard ini.
          </p>
        </div>

        <div className="grid gap-4 lg:grid-cols-3">
          <Card className={cn("lg:col-span-2 transition", selectedSensorOnline ? "" : "opacity-80 grayscale-[0.08]") }>
            <div className="mb-3 flex flex-wrap items-center justify-between gap-3">
              <h3 className="text-base font-semibold text-slate-900">Peta Interaktif Sensor (Google Maps)</h3>
              <div className={cn("rounded-full border px-2.5 py-1 text-xs font-semibold", connectionBadgeClass(selectedSensorOnline))}>
                {selectedSensorOnline ? "Online" : "Offline"}
              </div>
            </div>

            <div className="overflow-hidden rounded-lg border border-slate-200">
              <iframe
                title="Peta sensor EWS"
                src={`https://maps.google.com/maps?q=${selectedSensor.latitude},${selectedSensor.longitude}&t=k&z=13&output=embed`}
                className="h-72 w-full"
                loading="lazy"
                referrerPolicy="no-referrer-when-downgrade"
              />
            </div>

            <div className="mt-4 grid gap-2 sm:grid-cols-3">
              {selectableSensors.map((sensor) => (
                <button
                  key={sensor.id}
                  type="button"
                  onClick={() => setSelectedSensorId(sensor.id)}
                  className={cn(
                    "rounded-lg border px-3 py-2 text-left text-sm transition-all",
                    selectedSensorId === sensor.id
                      ? "border-blue-300 bg-blue-50 text-blue-800"
                      : sensor.online
                        ? "border-slate-200 bg-white text-slate-700 hover:border-blue-200 hover:bg-blue-50"
                        : "border-slate-200 bg-slate-100 text-slate-500 opacity-80 grayscale-[0.05] hover:border-slate-300",
                  )}
                >
                  <div className="flex items-center gap-2">
                    <span className="relative inline-flex h-3 w-3">
                      {sensor.online && <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-emerald-400 opacity-75" />}
                      <span className={cn("relative inline-flex h-3 w-3 rounded-full", sensor.online ? "bg-emerald-500" : "bg-slate-400")} />
                    </span>
                    <p className="font-semibold">{sensor.name}</p>
                  </div>
                  <p className="text-xs text-slate-500">{sensor.riverName}</p>
                </button>
              ))}
            </div>

            <div className={cn("mt-4 rounded-lg border border-slate-200 bg-slate-50 p-3 text-sm text-slate-700 transition", selectedSensorOnline ? "" : "opacity-80 grayscale-[0.08]") }>
              Lokasi terpilih: <span className="font-semibold">{selectedSensor.name}</span> ({selectedSensor.latitude.toFixed(4)}, {" "}
              {selectedSensor.longitude.toFixed(4)}) • Terakhir Update: {formatRelativeTime(selectedSensor.lastSeenAt ?? selectedSensor.updatedAt)} • {" "}
              <a
                href={`https://www.google.com/maps?q=${selectedSensor.latitude},${selectedSensor.longitude}&t=k`}
                target="_blank"
                rel="noreferrer"
                className="font-semibold text-blue-700 hover:text-blue-800"
              >
                Buka Google Maps
              </a>
            </div>
          </Card>

          <Card className={cn("transition", selectedSensorOnline ? "" : "opacity-80 grayscale-[0.08]") }>
            <div className="flex items-center justify-between">
              <h3 className="text-base font-semibold text-slate-900">Kondisi Live Sensor</h3>
              <StatusIndicator status={latest.status} />
            </div>

            <div className="mt-4 flex items-end gap-5">
              <div className="relative h-48 w-20 rounded-full border border-slate-200 bg-slate-100 p-2">
                <div
                  className={`absolute bottom-2 left-2 right-2 rounded-full transition-all duration-500 ${getThermometerColor(latest.status)} ${
                    latest.status === "danger" ? "animate-pulse" : ""
                  }`}
                  style={{ height: `${Math.max(10, thermometerPercent)}%` }}
                />
              </div>
              <div className="space-y-2">
                {selectedSensorHasData ? (
                  <p className="text-3xl font-bold text-slate-900">{latest.levelCm} cm</p>
                ) : (
                  <span className="inline-flex rounded-full bg-slate-100 px-2.5 py-1 text-sm font-semibold text-slate-500">Menunggu Data</span>
                )}
                <p className="text-sm text-slate-600">Ketinggian air saat ini</p>
                <p className={`inline-flex rounded-full px-2 py-1 text-xs font-semibold ${rainfallCategory.color}`}>
                  Curah hujan {rainfallCategory.label} ({rainfallCategory.detail})
                </p>
                <p className="text-sm text-slate-700">{latest.rainfallMm} mm/jam</p>
                <div className="mt-2 rounded-xl border border-slate-200 bg-white px-3 py-2 text-xs text-slate-600 shadow-sm">
                  Terakhir Update: <span className="font-semibold text-slate-900">{formatRelativeTime(selectedSensor.lastSeenAt ?? selectedSensor.updatedAt)}</span>
                  <div className="text-[11px] text-slate-500">{formatTimestamp(selectedSensor.lastSeenAt ?? selectedSensor.updatedAt)}</div>
                </div>
              </div>
            </div>

            <div className="mt-5 border-t border-slate-200 pt-4">
              <h4 className="text-sm font-semibold text-slate-800">Indikator Status</h4>
              <div className="mt-3 space-y-2.5">
                {sideIndicators.map((indicator) => (
                  <div key={indicator.label} className="flex items-center gap-2.5 text-sm text-slate-700">
                    <span className={`inline-flex h-2.5 w-2.5 rounded-full ${indicator.color}`} />
                    <span className="font-medium">{indicator.label}</span>
                    <span className="text-xs text-slate-500">— {indicator.text}</span>
                  </div>
                ))}
              </div>
            </div>
          </Card>
        </div>

        <div className="mt-6 grid grid-cols-1 lg:grid-cols-3 gap-6">
          <Card className="flex flex-col h-full hover:shadow-md transition-shadow">
            <WaterLevelChart points={history} />
          </Card>
          <Card className="flex flex-col h-full hover:shadow-md transition-shadow">
            <RainfallChart points={history} />
          </Card>
          <Card className="flex flex-col h-full hover:shadow-md transition-shadow">
            <FlowSpeedChart points={flowHistory} />
          </Card>
        </div>
      </div>
    </section>
  );
}
