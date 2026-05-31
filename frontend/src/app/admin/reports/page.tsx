"use client";

import { useEffect, useState, useMemo } from "react";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { RainfallChart } from "@/components/charts/RainfallChart";
import { WaterLevelChart } from "@/components/charts/WaterLevelChart";
import { FlowSpeedChart } from "@/components/charts/FlowSpeedChart";
import { formatTimestamp } from "@/lib/utils";
import type { WaterLevelPoint } from "@/types/water-level";
import api from "@/lib/api";
import { ConfirmDialog } from "@/components/ui/ConfirmDialog";

interface FilterState {
  fromDate: string;
  toDate: string;
  sensorId: string;
}

type DownloadFormat = "pdf" | "excel";

const REPORT_TYPE = "combined";

export default function AdminReportsPage() {
  const today = new Date();
  const weekAgo = new Date(today.getTime() - 6 * 24 * 60 * 60 * 1000);
  const initialFromDate = weekAgo.toISOString().slice(0, 10);
  const initialToDate = today.toISOString().slice(0, 10);
  const [sensorOptions, setSensorOptions] = useState<Array<{ id: string; sensorId: string; name: string; type?: string }>>([]);
  const [filteredData, setFilteredData] = useState<WaterLevelPoint[]>([]);
  const [loading, setLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [downloadLoading, setDownloadLoading] = useState<DownloadFormat | null>(null);
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  const [filterForm, setFilterForm] = useState<FilterState>({
    fromDate: initialFromDate,
    toDate: initialToDate,
    sensorId: "all",
  });
  const [appliedFilter, setAppliedFilter] = useState<FilterState>({
    fromDate: initialFromDate,
    toDate: initialToDate,
    sensorId: "all",
  });

  const [isConfirmOpen, setIsConfirmOpen] = useState(false);
  const [deleteLoading, setDeleteLoading] = useState(false);

  const handleDeleteFiltered = async () => {
    setDeleteLoading(true);
    setErrorMessage(null);
    try {
      const response = await api.delete("/reports/delete-filtered", {
        params: {
          startDate: `${appliedFilter.fromDate}T00:00:00.000Z`,
          endDate: `${appliedFilter.toDate}T23:59:59.999Z`,
          sensorId: appliedFilter.sensorId,
        },
      });

      const deletedCounts = response.data?.data?.deletedCounts;
      const totalDeleted = deletedCounts?.total ?? 0;
      showToast(`Berhasil menghapus ${totalDeleted} baris data logs.`);

      // Reload history to refresh view
      await loadHistory(appliedFilter, sensorOptions);
    } catch (error) {
      const message = error instanceof Error ? error.message : "Gagal menghapus data.";
      setErrorMessage(message);
      showToast(message);
    } finally {
      setDeleteLoading(false);
      setIsConfirmOpen(false);
    }
  };

  useEffect(() => {
    if (!toastMessage) return;

    const timer = window.setTimeout(() => setToastMessage(null), 3500);
    return () => window.clearTimeout(timer);
  }, [toastMessage]);

  const showToast = (message: string) => {
    setToastMessage(message);
  };

  const buildDownloadFilename = (format: DownloadFormat) => {
    const extension = format === "pdf" ? "pdf" : "xlsx";
    return `ews-report-${REPORT_TYPE}-${appliedFilter.fromDate}_to_${appliedFilter.toDate}.${extension}`;
  };

  const triggerDownload = (blob: Blob, filename: string) => {
    const url = window.URL.createObjectURL(blob);
    const anchor = document.createElement("a");
    anchor.href = url;
    anchor.download = filename;
    anchor.rel = "noopener noreferrer";
    document.body.appendChild(anchor);
    anchor.click();
    document.body.removeChild(anchor);
    window.URL.revokeObjectURL(url);
  };

  const downloadReport = async (format: DownloadFormat) => {
    setDownloadLoading(format);
    setErrorMessage(null);

    try {
      const response = await api.get("/reports/generate", {
        params: {
          type: REPORT_TYPE,
          startDate: `${appliedFilter.fromDate}T00:00:00.000Z`,
          endDate: `${appliedFilter.toDate}T23:59:59.999Z`,
          format,
          sensorId: appliedFilter.sensorId,
        },
        responseType: "blob",
      });

      const blob = response.data as Blob;
      const filename = buildDownloadFilename(format);
      triggerDownload(blob, filename);
      showToast(format === "pdf" ? "Unduhan PDF sedang dimulai." : "Unduhan Excel sedang dimulai.");
    } catch (error) {
      const message = error instanceof Error ? error.message : "Gagal mengunduh laporan.";
      setErrorMessage(message);
      showToast(message);
    } finally {
      setDownloadLoading(null);
    }
  };

  const loadSensors = async () => {
    const response = await api.get("/sensors");
    const data = response.data?.data;
    const rows = Array.isArray(data) ? data : data?.items ?? [];
    setSensorOptions(rows);
    return rows;
  };

  const loadHistory = async (filter: FilterState, sensors: Array<{ sensorId: string; type?: string }>) => {
    const targets = filter.sensorId === "all" 
      ? sensors 
      : sensors.filter((s) => s.sensorId === filter.sensorId);

    const requests = targets.map(async (sensor) => {
      const isRainSensor = sensor.type === "RAINFALL";
      const isFlowSensor = sensor.type === "FLOW_RATE";
      const endpoint = isRainSensor 
        ? "/rainfall/history" 
        : isFlowSensor 
          ? "/flow-rate/history" 
          : "/water-levels/history";

      const response = await api.get(endpoint, {
        params: {
          sensorId: sensor.sensorId,
          startDate: `${filter.fromDate}T00:00:00.000Z`,
          endDate: `${filter.toDate}T23:59:59.000Z`,
          interval: "hourly",
        },
      });

      const historyPayload = response.data?.data;
      const rows = (Array.isArray(historyPayload)
        ? historyPayload
        : historyPayload?.items ?? []) as Array<{
          sensorId: string;
          waterLevel?: number;
          rainfall?: number;
          flowRate?: number;
          recordedAt: string;
        }>;

      return rows.map((row) => {
        const levelCm = isRainSensor || isFlowSensor ? 0 : row.waterLevel ?? 0;
        const rainfallMm = isRainSensor ? row.rainfall ?? 0 : 0;
        const flowRateLpm = isFlowSensor 
          ? row.flowRate ?? 0 
          : Number((Math.max(0.3, levelCm / 220 + rainfallMm / 35)).toFixed(2));

        return {
          timestamp: row.recordedAt,
          levelCm,
          rainfallMm,
          flowRateLpm,
          sensorId: row.sensorId,
        };
      });
    });

    const results = await Promise.all(requests);
    const points = results.flat();

    points.sort((a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime());
    setFilteredData(points);
  };

  useEffect(() => {
    const bootstrap = async () => {
      setErrorMessage(null);
      try {
        const sensors = await loadSensors();
        await loadHistory(
          {
            fromDate: initialFromDate,
            toDate: initialToDate,
            sensorId: "all",
          },
          sensors,
        );
      } catch (error) {
        setErrorMessage(error instanceof Error ? error.message : "Gagal memuat laporan.");
      } finally {
        setLoading(false);
      }
    };

    void bootstrap();
  }, [initialFromDate, initialToDate]);

  useEffect(() => {
    // Setup bulletproof 60-second silent background polling for reports
    const timer = window.setInterval(() => {
      if (sensorOptions.length > 0) {
        void loadHistory(appliedFilter, sensorOptions);
      }
    }, 60000);

    return () => {
      window.clearInterval(timer);
    };
  }, [appliedFilter, sensorOptions]);

  const waterLevelPoints = useMemo(() => {
    return filteredData.filter((point) => {
      const sensor = sensorOptions.find((s) => s.sensorId === point.sensorId);
      return sensor?.type === "WATER_LEVEL";
    });
  }, [filteredData, sensorOptions]);

  const rainfallPoints = useMemo(() => {
    return filteredData.filter((point) => {
      const sensor = sensorOptions.find((s) => s.sensorId === point.sensorId);
      return sensor?.type === "RAINFALL";
    });
  }, [filteredData, sensorOptions]);

  const flowRatePoints = useMemo(() => {
    return filteredData.filter((point) => {
      const sensor = sensorOptions.find((s) => s.sensorId === point.sensorId);
      return sensor?.type === "FLOW_RATE";
    });
  }, [filteredData, sensorOptions]);

  const isDownloading = downloadLoading !== null;

  return (
    <main className="space-y-6">
      <Card className="relative overflow-hidden border-blue-500/30 bg-linear-to-r from-blue-600 via-blue-600 to-cyan-600 text-white shadow-lg shadow-blue-900/20">
        <div className="absolute -right-2 top-4 h-24 w-24 rounded-3xl border border-white/20 bg-white/10" />
        <div className="relative z-10 space-y-1.5">
          <h1 className="text-2xl font-bold tracking-tight">Laporan (Data Logs & Reporting)</h1>
          <p className="max-w-2xl text-sm text-blue-50/95">Analisis historis untuk pelaporan bulanan ke pemerintah daerah dan instansi terkait.</p>
        </div>
      </Card>

      <div className="grid gap-4 md:grid-cols-3">
        <Card className="border-slate-200 bg-white/95 shadow-sm">
          <p className="text-sm text-slate-500">Total Data Terfilter</p>
          <p className="mt-1 text-3xl font-bold text-slate-900">{filteredData.length}</p>
          <p className="text-xs text-slate-500">Baris data siap diekspor</p>
        </Card>
        <Card className="border-slate-200 bg-white/95 shadow-sm">
          <p className="text-sm text-slate-500">Rentang Tanggal</p>
          <p className="mt-1 text-xl font-bold text-blue-600">{appliedFilter.fromDate || "-"}</p>
          <p className="text-xs text-slate-500">s.d. {appliedFilter.toDate || "-"}</p>
        </Card>
        <Card className="border-slate-200 bg-white/95 shadow-sm">
          <p className="text-sm text-slate-500">Filter Sensor</p>
          <p className="mt-1 text-xl font-bold text-cyan-700">{appliedFilter.sensorId === "all" ? "Semua Sensor" : appliedFilter.sensorId}</p>
          <p className="text-xs text-slate-500">Sensor yang ditampilkan</p>
        </Card>
      </div>

      <Card className="border-slate-200 bg-white/95 shadow-md shadow-slate-200/40">
        <h2 className="mb-3 text-base font-semibold text-slate-900">Filter Pencarian</h2>
        <div className="grid gap-3 md:grid-cols-4">
          <label className="text-sm text-slate-700">
            Tanggal Mulai
            <input
              type="date"
              value={filterForm.fromDate}
              onChange={(event) => setFilterForm((prev) => ({ ...prev, fromDate: event.target.value }))}
              className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
            />
          </label>

          <label className="text-sm text-slate-700">
            Tanggal Akhir
            <input
              type="date"
              value={filterForm.toDate}
              onChange={(event) => setFilterForm((prev) => ({ ...prev, toDate: event.target.value }))}
              className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
            />
          </label>

          <label className="text-sm text-slate-700">
            Pilih Sensor
            <select
              value={filterForm.sensorId}
              onChange={(event) => setFilterForm((prev) => ({ ...prev, sensorId: event.target.value }))}
              className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
            >
              <option value="all">Semua Sensor</option>
              {Array.isArray(sensorOptions) && sensorOptions.map((sensor) => (
                <option key={sensor.id} value={sensor.sensorId}>
                  {sensor.name}
                </option>
              ))}
            </select>
          </label>

          <div className="flex items-end">
            <Button
              className="w-full"
              onClick={async () => {
                setAppliedFilter(filterForm);
                setErrorMessage(null);
                try {
                  await loadHistory(filterForm, Array.isArray(sensorOptions) ? sensorOptions : []);
                } catch (error) {
                  setErrorMessage(error instanceof Error ? error.message : "Gagal memuat data filter.");
                }
              }}
            >
              Tampilkan Data
            </Button>
          </div>
        </div>
      </Card>

      <div className="grid gap-6 lg:grid-cols-3">
        <Card className="flex flex-col h-full hover:shadow-md transition-shadow border-slate-200 bg-white/95 shadow-sm">
          <WaterLevelChart points={waterLevelPoints} />
        </Card>
        <Card className="flex flex-col h-full hover:shadow-md transition-shadow border-slate-200 bg-white/95 shadow-sm">
          <RainfallChart points={rainfallPoints} />
        </Card>
        <Card className="flex flex-col h-full hover:shadow-md transition-shadow border-slate-200 bg-white/95 shadow-sm">
          <FlowSpeedChart points={flowRatePoints} />
        </Card>
      </div>

      <Card className="overflow-x-auto border-slate-200 bg-white/95 shadow-md shadow-slate-200/40">
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-base font-semibold text-slate-900">Tabel Data Mentah</h2>
          <div className="flex gap-2">
            <Button
              variant="secondary"
              onClick={() => void downloadReport("pdf")}
              disabled={isDownloading}
            >
              {downloadLoading === "pdf" ? (
                <span className="inline-flex items-center gap-2">
                  <span className="inline-flex size-4 animate-spin rounded-full border-2 border-slate-400 border-t-transparent" />
                  Memproses PDF...
                </span>
              ) : (
                "Unduh PDF"
              )}
            </Button>
            <Button onClick={() => void downloadReport("excel")} disabled={isDownloading || deleteLoading}>
              {downloadLoading === "excel" ? (
                <span className="inline-flex items-center gap-2">
                  <span className="inline-flex size-4 animate-spin rounded-full border-2 border-white/70 border-t-transparent" />
                  Memproses Excel...
                </span>
              ) : (
                "Unduh Excel (.xlsx)"
              )}
            </Button>
            <Button
              variant="danger"
              onClick={() => setIsConfirmOpen(true)}
              disabled={isDownloading || deleteLoading}
            >
              {deleteLoading ? (
                <span className="inline-flex items-center gap-2">
                  <span className="inline-flex size-4 animate-spin rounded-full border-2 border-white/70 border-t-transparent" />
                  Menghapus...
                </span>
              ) : (
                "Hapus Data Terfilter"
              )}
            </Button>
          </div>
        </div>

        <table className="w-full min-w-180 text-left text-sm">
          <thead>
            <tr className="border-b border-slate-200 text-slate-500">
              <th className="py-2">Waktu</th>
              <th className="py-2">Sensor</th>
              <th className="py-2">Ketinggian</th>
              <th className="py-2">Intensitas Hujan</th>
              <th className="py-2">Debit Air</th>
            </tr>
          </thead>
          <tbody>
            {filteredData.length === 0 ? (
              <tr>
                <td colSpan={5} className="py-6 text-center text-sm text-slate-500">
                  Tidak ada data pada rentang filter ini.
                </td>
              </tr>
            ) : (
              filteredData.map((row, index) => (
                <tr key={`${row.sensorId}-${row.timestamp}-${index}`} className="border-b border-slate-100">
                  <td className="py-3 text-slate-700">{formatTimestamp(row.timestamp)}</td>
                  <td className="py-3 text-slate-700">{row.sensorId}</td>
                  <td className="py-3 text-slate-700">{row.levelCm} cm</td>
                  <td className="py-3 text-slate-700">{row.rainfallMm} mm/jam</td>
                  <td className="py-3 text-slate-700">{row.flowRateLpm ?? 0} LPM</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </Card>

      {loading && <p className="text-sm text-slate-500">Memuat data laporan...</p>}
      {errorMessage && <p className="text-sm text-rose-600">{errorMessage}</p>}

      {toastMessage && (
        <div className="fixed bottom-6 right-6 z-50 max-w-sm rounded-2xl border border-slate-200 bg-white px-4 py-3 shadow-xl shadow-slate-900/10">
          <p className="text-sm font-semibold text-blue-700">Laporan</p>
          <p className="mt-1 text-sm text-slate-600">{toastMessage}</p>
        </div>
      )}

      <ConfirmDialog
        open={isConfirmOpen}
        title="Hapus Data Terfilter"
        description={`Apakah Anda yakin ingin menghapus seluruh data logs untuk sensor "${
          appliedFilter.sensorId === "all" ? "Semua Sensor" : appliedFilter.sensorId
        }" dari tanggal ${appliedFilter.fromDate} s.d. ${
          appliedFilter.toDate
        } dari database secara permanen? Tindakan ini bersifat destruktif dan tidak dapat dibatalkan.`}
        confirmText="Ya, Hapus Data"
        cancelText="Batal"
        onConfirm={handleDeleteFiltered}
        onCancel={() => setIsConfirmOpen(false)}
      />
    </main>
  );
}
