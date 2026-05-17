"use client";

import { FormEvent, useEffect, useMemo, useState } from "react";
import type { Sensor, SensorConnectivity } from "@/types/sensor";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { ConfirmDialog } from "@/components/ui/ConfirmDialog";
import { Modal } from "@/components/ui/Modal";
import { StatusIndicator } from "@/components/ui/StatusIndicator";
import { getStatusFromLevel } from "@/lib/utils";
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
};

export default function AdminSensorsPage() {
  const [sensors, setSensors] = useState<Sensor[]>([]);
  const [loading, setLoading] = useState(true);
  const [open, setOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [savedMessage, setSavedMessage] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [form, setForm] = useState<SensorFormState>(emptyForm);
  const [deleteConfirm, setDeleteConfirm] = useState<{ id: string; name: string } | null>(null);

  const loadSensors = async () => {
    setErrorMessage(null);
    try {
      const [sensorResp, waterResp] = await Promise.all([
        api.get("/sensors"),
        api.get("/water-levels/current"),
      ]);

      const sensorPayload = sensorResp.data?.data;
      const sensorRows = (Array.isArray(sensorPayload)
        ? sensorPayload
        : sensorPayload?.items ?? []) as Array<{
        id: string;
        sensorId: string;
        name: string;
        latitude: number;
        longitude: number;
        batteryLevel: number | null;
        connectivity: "ONLINE" | "OFFLINE" | "MAINTENANCE";
        lastActiveAt: string | null;
      }>;

      const waterRows = (waterResp.data?.data ?? []) as Array<{
        sensorId: string;
        waterLevel: number;
        recordedAt: string;
      }>;

      const waterMap = new Map(waterRows.map((row) => [row.sensorId, row]));
      const mapped: Sensor[] = sensorRows.map((item) => {
        const water = waterMap.get(item.sensorId);
        const level = water?.waterLevel ?? 0;
        return {
          id: item.id,
          name: item.name,
          riverName: item.name,
          latitude: item.latitude,
          longitude: item.longitude,
          connectivity: item.connectivity === "ONLINE" ? "online" : "offline",
          batteryPercent: item.batteryLevel ?? 0,
          lastLevelCm: level,
          status: getStatusFromLevel(level),
          updatedAt: water?.recordedAt ?? item.lastActiveAt ?? new Date().toISOString(),
        };
      });

      setSensors(mapped);
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : "Gagal memuat data sensor.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void loadSensors();
  }, []);

  const modalTitle = editingId ? "Edit Sensor" : "Tambah Sensor";

  const onlineCount = sensors.filter((sensor) => sensor.connectivity === "online").length;
  const offlineCount = sensors.length - onlineCount;
  const alertCount = sensors.filter((sensor) => sensor.status === "alert").length;
  const dangerCount = sensors.filter((sensor) => sensor.status === "danger").length;
  const avgBattery = Math.round(sensors.reduce((sum, sensor) => sum + sensor.batteryPercent, 0) / Math.max(sensors.length, 1));

  const mapPreviewUrl = useMemo(
    () => `https://maps.google.com/maps?q=${form.latitude},${form.longitude}&z=14&output=embed`,
    [form.latitude, form.longitude],
  );

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
      riverName: sensor.riverName,
      latitude: sensor.latitude,
      longitude: sensor.longitude,
      zeroCalibrationCm: 200,
      batteryPercent: sensor.batteryPercent,
      connectivity: sensor.connectivity,
      lastLevelCm: sensor.lastLevelCm,
    });
    setSavedMessage(null);
    setOpen(true);
  };

  const deleteSensor = async (id: string) => {
    setSavedMessage(null);
    setErrorMessage(null);
    try {
      await api.delete(`/sensors/${id}`);
      setSavedMessage("Sensor berhasil dihapus.");
      await loadSensors();
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : "Gagal menghapus sensor.");
    }
  };

  const submitForm = async (event: FormEvent) => {
    event.preventDefault();
    setSavedMessage(null);
    setErrorMessage(null);

    try {
      const payload = {
        sensorId: form.id,
        name: form.name,
        latitude: form.latitude,
        longitude: form.longitude,
        batteryLevel: form.batteryPercent,
        connectivity: form.connectivity === "online" ? "ONLINE" : "OFFLINE",
      };

      if (editingId) {
        await api.put(`/sensors/${editingId}`, payload);
        setSavedMessage("Data sensor berhasil diperbarui.");
      } else {
        await api.post("/sensors", payload);
        setSavedMessage("Sensor baru berhasil ditambahkan.");
      }

      setOpen(false);
      await loadSensors();
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : "Gagal menyimpan sensor.");
    }
  };

  return (
    <main className="space-y-6">
      <Card className="relative overflow-hidden border-blue-500/30 bg-linear-to-r from-blue-600 via-blue-600 to-cyan-600 text-white shadow-lg shadow-blue-900/20">
        <div className="absolute -right-2 top-4 h-24 w-24 rounded-3xl border border-white/20 bg-white/10" />
        <div className="relative z-10 flex flex-wrap items-start justify-between gap-4">
          <div className="space-y-1.5">
            <h1 className="text-2xl font-bold tracking-tight">Manajemen Sensor IoT</h1>
            <p className="max-w-2xl text-sm text-blue-50/95">Pantau kesehatan perangkat ultrasonik & rain gauge secara real-time.</p>
          </div>
          <Button onClick={openCreate} className="bg-white text-blue-700 hover:bg-blue-50">
            Tambah Sensor
          </Button>
        </div>
      </Card>

      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        <Card className="border-slate-200 bg-white/95 shadow-sm">
          <p className="text-sm text-slate-500">Total Sensor</p>
          <p className="mt-1 text-3xl font-bold text-slate-900">{sensors.length}</p>
          <p className="text-xs text-slate-500">Perangkat terdaftar</p>
        </Card>
        <Card className="border-slate-200 bg-white/95 shadow-sm">
          <p className="text-sm text-slate-500">Koneksi</p>
          <p className="mt-1 text-3xl font-bold text-emerald-600">{onlineCount}</p>
          <p className="text-xs text-slate-500">Online · {offlineCount} offline</p>
        </Card>
        <Card className="border-slate-200 bg-white/95 shadow-sm">
          <p className="text-sm text-slate-500">Status Risiko</p>
          <p className="mt-1 text-3xl font-bold text-amber-600">{alertCount}</p>
          <p className="text-xs text-slate-500">Waspada · {dangerCount} bahaya</p>
        </Card>
        <Card className="border-slate-200 bg-white/95 shadow-sm">
          <p className="text-sm text-slate-500">Rata-rata Baterai</p>
          <p className="mt-1 text-3xl font-bold text-cyan-700">{avgBattery}%</p>
          <p className="text-xs text-slate-500">Kesehatan daya perangkat</p>
        </Card>
      </div>

      {loading && <p className="text-sm text-slate-500">Memuat data sensor...</p>}
      {savedMessage && <p className="text-sm font-medium text-emerald-600">{savedMessage}</p>}
      {errorMessage && <p className="text-sm font-medium text-rose-600">{errorMessage}</p>}

      <Card className="overflow-x-auto border-slate-200 bg-white/95 shadow-md shadow-slate-200/40">
        <div className="mb-4 flex items-center justify-between gap-3">
          <div>
            <h2 className="text-lg font-semibold text-slate-900">Daftar Sensor</h2>
            <p className="text-sm text-slate-500">Monitoring status dan konfigurasi tiap titik sensor.</p>
          </div>
          <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">Total {sensors.length} Sensor</span>
        </div>
        <table className="w-full min-w-220 text-left text-sm">
          <thead>
            <tr className="border-b border-slate-200 text-slate-500">
              <th className="py-2">ID Perangkat</th>
              <th className="py-2">Nama/Lokasi Titik</th>
              <th className="py-2">Ketinggian Air Saat Ini</th>
              <th className="py-2">Status Koneksi</th>
              <th className="py-2">Sisa Baterai</th>
              <th className="py-2">Status</th>
              <th className="py-2">Aksi</th>
            </tr>
          </thead>
          <tbody>
            {sensors.map((sensor) => (
              <tr key={sensor.id} className="border-b border-slate-100">
                <td className="py-3 font-mono text-xs text-slate-700">{sensor.id}</td>
                <td className="py-3">
                  <p className="font-medium text-slate-800">{sensor.name}</p>
                  <p className="text-xs text-slate-500">{sensor.riverName}</p>
                </td>
                <td className="py-3 text-slate-600">{sensor.lastLevelCm} cm</td>
                <td className="py-3">
                  <span
                    className={`inline-flex rounded-full px-2.5 py-1 text-xs font-semibold ${
                      sensor.connectivity === "online" ? "bg-emerald-100 text-emerald-700" : "bg-rose-100 text-rose-700"
                    }`}
                  >
                    {sensor.connectivity === "online" ? "Online" : "Offline"}
                  </span>
                </td>
                <td className="py-3 text-slate-600">{sensor.batteryPercent}%</td>
                <td className="py-3">
                  <StatusIndicator status={sensor.status} />
                </td>
                <td className="py-3">
                  <div className="flex gap-2">
                    <Button variant="secondary" onClick={() => openEdit(sensor)}>
                      Edit
                    </Button>
                    <Button variant="danger" onClick={() => setDeleteConfirm({ id: sensor.id, name: sensor.name })}>
                      Hapus
                    </Button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </Card>

      <Modal open={open} title={modalTitle} onClose={() => setOpen(false)}>
        <form onSubmit={submitForm} className="space-y-3">
          <label className="block text-sm text-slate-700">
            ID Perangkat (MAC Address/UUID)
            <input
              required
              value={form.id}
              onChange={(event) => setForm((prev) => ({ ...prev, id: event.target.value }))}
              className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
              placeholder="ESP32-UUID-001"
            />
          </label>

          <label className="block text-sm text-slate-700">
            Nama Lokasi
            <input
              required
              value={form.name}
              onChange={(event) => setForm((prev) => ({ ...prev, name: event.target.value }))}
              className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
              placeholder="Hulu Sungai Jembatan X"
            />
          </label>

          <label className="block text-sm text-slate-700">
            Nama Sungai/Area
            <input
              required
              value={form.riverName}
              onChange={(event) => setForm((prev) => ({ ...prev, riverName: event.target.value }))}
              className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
            />
          </label>

          <div className="grid gap-3 sm:grid-cols-2">
            <label className="text-sm text-slate-700">
              Latitude
              <input
                type="number"
                step="0.0001"
                required
                value={form.latitude}
                onChange={(event) => setForm((prev) => ({ ...prev, latitude: Number(event.target.value) }))}
                className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
              />
            </label>
            <label className="text-sm text-slate-700">
              Longitude
              <input
                type="number"
                step="0.0001"
                required
                value={form.longitude}
                onChange={(event) => setForm((prev) => ({ ...prev, longitude: Number(event.target.value) }))}
                className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
              />
            </label>
          </div>

          <div className="grid gap-3 sm:grid-cols-3">
            <label className="text-sm text-slate-700">
              Kalibrasi Titik Nol (cm)
              <input
                type="number"
                required
                value={form.zeroCalibrationCm}
                onChange={(event) => setForm((prev) => ({ ...prev, zeroCalibrationCm: Number(event.target.value) }))}
                className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
              />
            </label>
            <label className="text-sm text-slate-700">
              Ketinggian Air Saat Ini (cm)
              <input
                type="number"
                required
                value={form.lastLevelCm}
                onChange={(event) => setForm((prev) => ({ ...prev, lastLevelCm: Number(event.target.value) }))}
                className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
              />
            </label>
            <label className="text-sm text-slate-700">
              Sisa Baterai (%)
              <input
                type="number"
                required
                min={0}
                max={100}
                value={form.batteryPercent}
                onChange={(event) => setForm((prev) => ({ ...prev, batteryPercent: Number(event.target.value) }))}
                className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
              />
            </label>
          </div>

          <label className="block text-sm text-slate-700">
            Status Koneksi
            <select
              value={form.connectivity}
              onChange={(event) => setForm((prev) => ({ ...prev, connectivity: event.target.value as SensorConnectivity }))}
              className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
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
              className="h-38 w-full rounded-lg border border-slate-200"
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
        description={`Sensor ${deleteConfirm?.name ?? "terpilih"} akan dihapus dari monitoring.`}
        confirmText="Ya, hapus"
        cancelText="Batal"
        onCancel={() => setDeleteConfirm(null)}
        onConfirm={() => {
          const selected = deleteConfirm;
          setDeleteConfirm(null);
          if (selected) {
            void deleteSensor(selected.id);
          }
        }}
      />
    </main>
  );
}
