"use client";

import { useMemo, useState, useSyncExternalStore } from "react";
import { Card } from "@/components/ui/Card";
import { PublicGoogleSensorMap } from "@/components/maps/PublicGoogleSensorMap";
import { useWaterLevel } from "@/hooks/useWaterLevel";
import { cn } from "@/lib/utils";
import { formatTimestamp } from "@/lib/utils";
import type { WaterStatus } from "@/types/water-level";

const statusMeta: Record<
  WaterStatus,
  {
    label: string;
    badgeClass: string;
    dotClass: string;
  }
> = {
  safe: {
    label: "Normal",
    badgeClass: "bg-emerald-100 text-emerald-700",
    dotClass: "bg-emerald-500",
  },
  warning: {
    label: "Waspada",
    badgeClass: "bg-yellow-100 text-yellow-700",
    dotClass: "bg-yellow-500",
  },
  alert: {
    label: "Siaga",
    badgeClass: "bg-amber-100 text-amber-700",
    dotClass: "bg-amber-500",
  },
  danger: {
    label: "Bahaya",
    badgeClass: "bg-rose-100 text-rose-700",
    dotClass: "bg-rose-500",
  },
};

const statusRank: Record<WaterStatus, number> = {
  safe: 0,
  warning: 1,
  alert: 2,
  danger: 3,
};

type StatusFilter = "all" | WaterStatus;

export default function UserMapPage() {
  const { sensorsSnapshot } = useWaterLevel();
  const isHydrated = useSyncExternalStore(
    () => () => {},
    () => true,
    () => false,
  );
  const [searchQuery, setSearchQuery] = useState("");
  const [statusFilter, setStatusFilter] = useState<StatusFilter>("all");
  const [selectedSensorId, setSelectedSensorId] = useState<string>(sensorsSnapshot[0]?.id ?? "");

  const sortedSensors = useMemo(
    () => [...sensorsSnapshot].sort((a, b) => statusRank[b.status] - statusRank[a.status] || b.lastLevelCm - a.lastLevelCm),
    [sensorsSnapshot],
  );

  const filteredSensors = useMemo(() => {
    const query = searchQuery.trim().toLowerCase();

    return sortedSensors.filter((sensor) => {
      const matchesStatus = statusFilter === "all" ? true : sensor.status === statusFilter;
      const matchesQuery =
        query.length === 0
          ? true
          : sensor.name.toLowerCase().includes(query) ||
            sensor.id.toLowerCase().includes(query) ||
            sensor.riverName.toLowerCase().includes(query);

      return matchesStatus && matchesQuery;
    });
  }, [searchQuery, sortedSensors, statusFilter]);

  const activeSensors = filteredSensors.length > 0 ? filteredSensors : sortedSensors;

  const effectiveSelectedSensorId = useMemo(() => {
    if (activeSensors.length === 0) {
      return "";
    }

    const selectedExists = activeSensors.some((sensor) => sensor.id === selectedSensorId);
    return selectedExists ? selectedSensorId : activeSensors[0].id;
  }, [activeSensors, selectedSensorId]);

  const selectedSensor = useMemo(
    () => activeSensors.find((sensor) => sensor.id === effectiveSelectedSensorId) ?? activeSensors[0] ?? null,
    [activeSensors, effectiveSelectedSensorId],
  );

  const riskCount = sensorsSnapshot.filter((sensor) => sensor.status !== "safe").length;
  const dangerCount = sensorsSnapshot.filter((sensor) => sensor.status === "danger").length;
  const alertCount = sensorsSnapshot.filter((sensor) => sensor.status === "alert").length;
  const normalCount = sensorsSnapshot.filter((sensor) => sensor.status === "safe").length;
  const onlineCount = sensorsSnapshot.filter((sensor) => sensor.connectivity === "online").length;

  const latestUpdate = useMemo(() => {
    if (sensorsSnapshot.length === 0) {
      return "-";
    }

    const latest = [...sensorsSnapshot].sort(
      (a, b) => new Date(b.updatedAt).getTime() - new Date(a.updatedAt).getTime(),
    )[0];

    return formatTimestamp(latest.updatedAt);
  }, [sensorsSnapshot]);

  const hasNoFilteredResult = filteredSensors.length === 0;

  if (!isHydrated) {
    return (
      <main className="mx-auto w-full max-w-6xl px-6 py-8">
        <section className="rounded-2xl border border-blue-100 bg-linear-to-br from-blue-50 to-white p-5 shadow-sm md:p-6">
          <p className="text-xs font-semibold uppercase tracking-wide text-blue-700">User Map Center</p>
          <h1 className="mt-1 text-3xl font-bold text-slate-900">Peta Sensor (Mode User)</h1>
          <p className="mt-2 max-w-3xl text-sm text-slate-600">Menyiapkan tampilan peta sensor...</p>
        </section>

        <section className="mt-5 rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
          <div className="h-80 animate-pulse rounded-xl bg-slate-100" />
        </section>
      </main>
    );
  }

  return (
    <main className="mx-auto w-full max-w-6xl px-6 py-8">
      <section className="rounded-2xl border border-blue-100 bg-linear-to-br from-blue-50 to-white p-5 shadow-sm md:p-6">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-wide text-blue-700">User Map Center</p>
            <h1 className="mt-1 text-3xl font-bold text-slate-900">Peta Sensor (Mode User)</h1>
            <p className="mt-2 max-w-3xl text-sm text-slate-600">
              Pantau posisi sensor, identifikasi titik paling berisiko, dan fokuskan respons lebih cepat langsung dari peta.
            </p>

            <div className="mt-3 flex flex-wrap gap-2 text-xs">
              <span className="inline-flex items-center gap-1.5 rounded-full border border-slate-200 bg-white px-2.5 py-1 text-slate-600">
                <span className="font-semibold text-slate-800">Fokus:</span>
                {selectedSensor ? `${selectedSensor.name} (${statusMeta[selectedSensor.status].label})` : "-"}
              </span>
              <span className="inline-flex items-center gap-1.5 rounded-full border border-slate-200 bg-white px-2.5 py-1 text-slate-600">
                Normal: <span className="font-semibold text-slate-800">{normalCount}</span>
              </span>
              <span className="inline-flex items-center gap-1.5 rounded-full border border-slate-200 bg-white px-2.5 py-1 text-slate-600">
                Waspada: <span className="font-semibold text-slate-800">{alertCount}</span>
              </span>
              <span className="inline-flex items-center gap-1.5 rounded-full border border-slate-200 bg-white px-2.5 py-1 text-slate-600">
                Bahaya: <span className="font-semibold text-slate-800">{dangerCount}</span>
              </span>
            </div>
          </div>

          <div className="grid gap-2 sm:grid-cols-2 lg:w-110">
            <Card className="border-slate-200 bg-white p-3">
              <p className="text-xs text-slate-500">Total Sensor</p>
              <p className="mt-1 text-xl font-bold text-slate-900">{sensorsSnapshot.length}</p>
            </Card>
            <Card className="border-slate-200 bg-white p-3">
              <p className="text-xs text-slate-500">Sensor Berisiko</p>
              <p className="mt-1 text-xl font-bold text-slate-900">{riskCount}</p>
            </Card>
            <Card className="border-slate-200 bg-white p-3">
              <p className="text-xs text-slate-500">Konektivitas</p>
              <p className="mt-1 text-xl font-bold text-slate-900">{onlineCount}/{sensorsSnapshot.length}</p>
            </Card>
            <Card className="border-slate-200 bg-white p-3">
              <p className="text-xs text-slate-500">Pembaruan Terakhir</p>
              <p className="mt-1 text-sm font-bold text-slate-900">{latestUpdate}</p>
            </Card>
          </div>
        </div>
      </section>

      <section className="mt-5 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm md:p-5">
        <div className="flex flex-col gap-3 lg:flex-row lg:items-end lg:justify-between">
          <div>
            <h2 className="text-lg font-semibold text-slate-900">Peta Interaktif Sensor</h2>
            <p className="mt-1 text-sm text-slate-600">
              Klik marker di peta atau pilih kartu sensor di bawah untuk melihat fokus titik terpilih.
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-2 text-xs">
            {(["safe", "alert", "danger"] as WaterStatus[]).map((status) => (
              <span key={status} className="inline-flex items-center gap-1.5 rounded-full border border-slate-200 bg-white px-2.5 py-1 text-slate-600">
                <span className={cn("inline-flex h-2 w-2 rounded-full", statusMeta[status].dotClass)} aria-hidden="true" />
                {statusMeta[status].label}
              </span>
            ))}
          </div>
        </div>

        <div className="mt-4 grid gap-3 lg:grid-cols-[1fr_300px]">
          <PublicGoogleSensorMap
            sensors={activeSensors}
            selectedSensorId={effectiveSelectedSensorId}
            onMarkerSelect={setSelectedSensorId}
            className="h-105"
          />

          <div className="rounded-xl border border-slate-200 bg-slate-50 p-4">
            <p className="text-xs font-semibold uppercase tracking-wide text-slate-500">Sensor Terfokus</p>
            {selectedSensor ? (
              <>
                <h3 className="mt-1 text-3xl/9 font-bold text-slate-900">{selectedSensor.name}</h3>
                <p className="mt-1 text-sm text-slate-600">{selectedSensor.riverName} • {selectedSensor.id}</p>

                <div className="my-3 border-t border-slate-200" />

                <dl className="space-y-2 text-sm text-slate-700">
                  <div className="grid grid-cols-[98px_1fr] items-start gap-2">
                    <dt className="text-slate-500">Tinggi air</dt>
                    <dd className="font-semibold text-slate-900">{selectedSensor.lastLevelCm} cm</dd>
                  </div>

                  <div className="grid grid-cols-[98px_1fr] items-center gap-2">
                    <dt className="text-slate-500">Status</dt>
                    <dd>
                      <span className={cn("inline-flex rounded-full px-2 py-0.5 text-xs font-semibold", statusMeta[selectedSensor.status].badgeClass)}>
                        {statusMeta[selectedSensor.status].label}
                      </span>
                    </dd>
                  </div>

                  <div className="grid grid-cols-[98px_1fr] items-start gap-2">
                    <dt className="text-slate-500">Baterai</dt>
                    <dd className="font-semibold text-slate-900">{selectedSensor.batteryPercent}%</dd>
                  </div>

                  <div className="grid grid-cols-[98px_1fr] items-start gap-2">
                    <dt className="text-slate-500">Konektivitas</dt>
                    <dd className="font-semibold text-slate-900">{selectedSensor.connectivity === "online" ? "Online" : "Offline"}</dd>
                  </div>

                  <div className="grid grid-cols-[98px_1fr] items-start gap-2">
                    <dt className="text-slate-500">Pembaruan</dt>
                    <dd className="font-semibold text-slate-900">{formatTimestamp(selectedSensor.updatedAt)}</dd>
                  </div>
                </dl>

                <a
                  href={`https://www.google.com/maps?q=${selectedSensor.latitude},${selectedSensor.longitude}`}
                  target="_blank"
                  rel="noreferrer"
                  className="mt-4 inline-flex w-full items-center justify-center rounded-lg bg-blue-600 px-3 py-2 text-sm font-semibold text-white transition-colors hover:bg-blue-700"
                >
                  Buka Lokasi di Google Maps
                </a>
              </>
            ) : (
              <p className="mt-2 text-sm text-slate-600">Tidak ada sensor yang bisa ditampilkan.</p>
            )}
          </div>
        </div>
      </section>

      <section className="mt-5 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm md:p-5">
        <div className="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
          <div>
            <h2 className="text-lg font-semibold text-slate-900">Daftar Sensor</h2>
            <p className="mt-1 text-sm text-slate-600">Gunakan pencarian dan filter status untuk menemukan sensor lebih cepat.</p>
          </div>

          <div className="flex w-full flex-col gap-2 lg:w-140">
            <input
              type="text"
              value={searchQuery}
              onChange={(event) => setSearchQuery(event.target.value)}
              placeholder="Cari nama sensor, id, atau sungai..."
              className="h-10 w-full rounded-lg border border-slate-300 px-3 text-sm text-slate-700 outline-none ring-blue-100 transition focus:border-blue-300 focus:ring-2"
            />

            <div className="grid grid-cols-2 gap-2 sm:grid-cols-4">
              {([
                { value: "all", label: "Semua" },
                { value: "safe", label: "Normal" },
                { value: "alert", label: "Waspada" },
                { value: "danger", label: "Bahaya" },
              ] as Array<{ value: StatusFilter; label: string }>).map((item) => (
                <button
                  key={item.value}
                  type="button"
                  onClick={() => setStatusFilter(item.value)}
                  className={cn(
                    "w-full rounded-full border px-3 py-1.5 text-xs font-semibold transition-colors",
                    statusFilter === item.value
                      ? "border-blue-200 bg-blue-50 text-blue-700"
                      : "border-slate-200 bg-white text-slate-600 hover:bg-slate-50",
                  )}
                >
                  {item.label}
                </button>
              ))}
            </div>
          </div>
        </div>

        {hasNoFilteredResult ? (
          <div className="mt-4 rounded-xl border border-slate-200 bg-slate-50 p-6 text-center">
            <p className="text-sm font-semibold text-slate-800">Tidak ada sensor yang cocok</p>
            <p className="mt-1 text-sm text-slate-600">Coba ubah kata pencarian atau reset filter status.</p>
            <button
              type="button"
              onClick={() => {
                setSearchQuery("");
                setStatusFilter("all");
              }}
              className="mt-3 rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-100"
            >
              Reset Filter
            </button>
          </div>
        ) : (
          <div className="mt-4 grid gap-4 md:grid-cols-2 xl:grid-cols-3">
            {filteredSensors.map((sensor) => {
              const isActive = sensor.id === effectiveSelectedSensorId;

              return (
                <Card key={sensor.id} className={cn("border transition-all", isActive ? "border-blue-300 bg-blue-50/40" : "border-slate-200 bg-white")}>
                  <button
                    type="button"
                    onClick={() => setSelectedSensorId(sensor.id)}
                    className="w-full text-left"
                  >
                    <div className="mb-2 flex items-start justify-between gap-2">
                      <div>
                        <h3 className="text-base font-semibold text-slate-900">{sensor.name}</h3>
                        <p className="text-sm text-slate-600">{sensor.riverName} • {sensor.id}</p>
                      </div>
                      <span className={cn("inline-flex rounded-full px-2.5 py-1 text-xs font-semibold", statusMeta[sensor.status].badgeClass)}>
                        {statusMeta[sensor.status].label}
                      </span>
                    </div>

                    <div className="grid grid-cols-2 gap-2 text-xs text-slate-600">
                      <div className="rounded-lg border border-slate-200 bg-white px-2.5 py-2">
                        <p className="text-slate-500">Tinggi air</p>
                        <p className="mt-0.5 text-sm font-semibold text-slate-800">{sensor.lastLevelCm} cm</p>
                      </div>
                      <div className="rounded-lg border border-slate-200 bg-white px-2.5 py-2">
                        <p className="text-slate-500">Baterai</p>
                        <p className="mt-0.5 text-sm font-semibold text-slate-800">{sensor.batteryPercent}%</p>
                      </div>
                      <div className="rounded-lg border border-slate-200 bg-white px-2.5 py-2">
                        <p className="text-slate-500">Konektivitas</p>
                        <p className="mt-0.5 text-sm font-semibold text-slate-800">{sensor.connectivity === "online" ? "Online" : "Offline"}</p>
                      </div>
                      <div className="rounded-lg border border-slate-200 bg-white px-2.5 py-2">
                        <p className="text-slate-500">Pembaruan</p>
                        <p className="mt-0.5 text-sm font-semibold text-slate-800">{formatTimestamp(sensor.updatedAt)}</p>
                      </div>
                    </div>
                  </button>

                  <div className="mt-3 flex flex-wrap gap-2">
                    <a
                      href={`https://www.google.com/maps?q=${sensor.latitude},${sensor.longitude}`}
                      target="_blank"
                      rel="noreferrer"
                      className="inline-flex rounded-lg border border-slate-300 bg-white px-3 py-1.5 text-xs font-semibold text-slate-700 hover:bg-slate-50"
                    >
                      Buka Google Maps
                    </a>
                    <button
                      type="button"
                      onClick={() => setSelectedSensorId(sensor.id)}
                      className="inline-flex rounded-lg bg-blue-600 px-3 py-1.5 text-xs font-semibold text-white hover:bg-blue-700"
                    >
                      Fokuskan di Peta
                    </button>
                  </div>
                </Card>
              );
            })}
          </div>
        )}
      </section>
    </main>
  );
}
