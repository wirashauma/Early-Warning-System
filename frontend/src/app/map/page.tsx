"use client";

import { useMemo } from "react";
import { Card } from "@/components/ui/Card";
import { PublicGoogleSensorMap } from "@/components/maps/PublicGoogleSensorMap";
import { useWaterLevel } from "@/hooks/useWaterLevel";
import { cn, formatRelativeTime, formatTimestamp, isSensorOnline } from "@/lib/utils";

export default function MapPage() {
  const { sensorsSnapshot } = useWaterLevel();
  const sensors = useMemo(
    () =>
      sensorsSnapshot.map((sensor) => ({
        ...sensor,
        online: isSensorOnline(sensor.lastSeenAt ?? sensor.updatedAt),
      })),
    [sensorsSnapshot],
  );

  return (
    <main className="mx-auto w-full max-w-6xl px-6 py-8">
      <h1 className="mb-2 text-2xl font-bold text-slate-900">Peta Lokasi Sensor</h1>
      <p className="mb-6 text-sm text-slate-600">
        Lihat titik sensor banjir secara interaktif. Klik marker untuk melihat status level air pada setiap lokasi.
      </p>

      <PublicGoogleSensorMap sensors={sensors} />

      <div className="mt-5 grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {sensors.map((sensor) => (
          <Card key={sensor.id}>
            <div className="mb-2 flex items-start justify-between gap-2">
              <div>
                <h2 className="text-base font-semibold text-slate-900">{sensor.name}</h2>
                <p className="text-xs text-slate-500">{sensor.riverName}</p>
              </div>
              <span
                className={cn(
                  "inline-flex items-center gap-2 rounded-full px-2.5 py-1 text-xs font-semibold",
                  sensor.online ? "bg-emerald-50 text-emerald-700" : "bg-slate-100 text-slate-600",
                )}
              >
                <span className={cn("relative inline-flex h-3 w-3")}>{sensor.online ? <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-emerald-400 opacity-75" /> : null}<span className={cn("relative inline-flex h-3 w-3 rounded-full", sensor.online ? "bg-emerald-500" : "bg-slate-400")} /></span>
                {sensor.online ? "Online" : "Offline"}
              </span>
            </div>

            <p className="mt-2 text-sm text-slate-700">
              Tinggi air:{" "}
              {sensor.hasWaterLevelData ? (
                <span className="font-semibold">{sensor.lastLevelCm.toFixed(1)} cm</span>
              ) : (
                <span className="inline-flex rounded-full bg-slate-100 px-2 py-1 text-xs font-semibold text-slate-500">Menunggu Data</span>
              )}
            </p>
            <p className="text-xs text-slate-500">Terakhir Update: {formatRelativeTime(sensor.lastSeenAt ?? sensor.updatedAt)}</p>
            <p className="text-xs text-slate-500">Terakhir Update (WIB): {formatTimestamp(sensor.lastSeenAt ?? sensor.updatedAt)}</p>
            <a
              href={`https://www.google.com/maps?q=${sensor.latitude},${sensor.longitude}`}
              target="_blank"
              rel="noreferrer"
              className="mt-3 inline-flex text-sm font-semibold text-blue-600 hover:text-blue-700"
            >
              Buka di Google Maps
            </a>
          </Card>
        ))}
      </div>
    </main>
  );
}
