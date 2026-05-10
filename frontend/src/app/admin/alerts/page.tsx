"use client";

import { FormEvent, useEffect, useState } from "react";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { ConfirmDialog } from "@/components/ui/ConfirmDialog";
import { formatTimestamp } from "@/lib/utils";
import api from "@/lib/api";

type AlertLevel = "Aman" | "Waspada" | "Bahaya";

export default function AdminAlertsPage() {
  const [target, setTarget] = useState("Semua Wilayah");
  const [level, setLevel] = useState<AlertLevel>("Waspada");
  const [channels, setChannels] = useState({
    whatsapp: true,
    push: true,
    email: false,
  });
  const [message, setMessage] = useState("Waspada kenaikan debit air di sektor hilir. Mohon siaga dan pantau instruksi lanjutan.");
  const [title, setTitle] = useState("Peringatan Kenaikan Debit Air");
  const [sent, setSent] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [confirmBroadcastOpen, setConfirmBroadcastOpen] = useState(false);
  const [history, setHistory] = useState<Array<{
    id: string;
    sentAt: string;
    level: AlertLevel;
    channels: string[];
    sender: string;
    status: "Berhasil" | "Gagal";
  }>>([]);

  const loadHistory = async () => {
    setErrorMessage(null);
    try {
      const response = await api.get("/alerts/history", {
        params: { page: 1, limit: 50 },
      });
      const items = (response.data?.data?.items ?? []) as Array<{
        id: string;
        sentAt: string;
        severity: "INFO" | "WARNING" | "DANGER";
        channels: string[];
        user?: { name?: string };
      }>;

      setHistory(
        items.map((item) => ({
          id: item.id,
          sentAt: item.sentAt,
          level:
            item.severity === "DANGER"
              ? "Bahaya"
              : item.severity === "WARNING"
                ? "Waspada"
                : "Aman",
          channels: item.channels,
          sender: item.user?.name ?? "Admin EWS",
          status: "Berhasil",
        })),
      );
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : "Gagal memuat riwayat peringatan.");
    }
  };

  useEffect(() => {
    const timer = window.setTimeout(() => {
      void loadHistory();
    }, 0);

    return () => {
      window.clearTimeout(timer);
    };
  }, []);

  const toggleChannel = (key: keyof typeof channels) => {
    setChannels((prev) => ({ ...prev, [key]: !prev[key] }));
  };

  const applyTemplate = (type: "evakuasi" | "waspada") => {
    if (type === "evakuasi") {
      setLevel("Bahaya");
      setTitle("Instruksi Evakuasi Segera");
      setMessage("PERHATIAN: Status BAHAYA. Segera lakukan evakuasi terarah ke titik aman terdekat sesuai prosedur BPBD.");
      return;
    }

    setLevel("Waspada");
    setTitle("Status Waspada");
    setMessage("Status WASPADA: terjadi kenaikan debit air. Mohon tingkatkan kesiapsiagaan dan pantau update resmi.");
  };

  const sendAlert = async () => {
    setErrorMessage(null);
    setSent(false);

    const usedChannels = [
      channels.whatsapp ? "whatsapp" : null,
      channels.push ? "push" : null,
      channels.email ? "email" : null,
    ].filter((item): item is string => Boolean(item));

    if (usedChannels.length === 0) {
      setErrorMessage("Pilih minimal satu saluran pengiriman.");
      return;
    }

    try {
      await api.post("/alerts/broadcast", {
        title,
        message,
        severity: level === "Bahaya" ? "DANGER" : level === "Waspada" ? "WARNING" : "INFO",
        channels: usedChannels,
        pushEnabled: channels.push,
        targetArea: target === "Semua Wilayah" ? null : target,
      });

      setSent(true);
      await loadHistory();
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : "Gagal mengirim peringatan.");
    }
  };

  const submitWithConfirm = (event: FormEvent) => {
    event.preventDefault();
    setConfirmBroadcastOpen(true);
  };

  return (
    <main className="space-y-6">
      <Card className="relative overflow-hidden border-blue-500/30 bg-linear-to-r from-blue-600 via-blue-600 to-cyan-600 text-white shadow-lg shadow-blue-900/20">
        <div className="absolute -right-2 top-4 h-24 w-24 rounded-3xl border border-white/20 bg-white/10" />
        <div className="relative z-10 space-y-1.5">
          <h1 className="text-2xl font-bold tracking-tight">Peringatan (Broadcast Alert System)</h1>
          <p className="max-w-2xl text-sm text-blue-50/95">Sebarkan peringatan darurat melalui WhatsApp, Push Notification, dan Email secara terpusat.</p>
        </div>
      </Card>

      <div className="grid gap-4 md:grid-cols-3">
        <Card className="border-slate-200 bg-white/95 shadow-sm">
          <p className="text-sm text-slate-500">Total Riwayat Broadcast</p>
          <p className="mt-1 text-3xl font-bold text-slate-900">{history.length}</p>
          <p className="text-xs text-slate-500">Data pengiriman yang tercatat</p>
        </Card>
        <Card className="border-slate-200 bg-white/95 shadow-sm">
          <p className="text-sm text-slate-500">Level Saat Ini</p>
          <p className={`mt-1 text-3xl font-bold ${level === "Bahaya" ? "text-rose-600" : level === "Waspada" ? "text-amber-600" : "text-emerald-600"}`}>
            {level}
          </p>
          <p className="text-xs text-slate-500">Draft alert aktif</p>
        </Card>
        <Card className="border-slate-200 bg-white/95 shadow-sm">
          <p className="text-sm text-slate-500">Saluran Aktif</p>
          <p className="mt-1 text-3xl font-bold text-cyan-700">{[channels.whatsapp, channels.push, channels.email].filter(Boolean).length}</p>
          <p className="text-xs text-slate-500">WhatsApp, Push, Email</p>
        </Card>
      </div>

      <Card className="border-slate-200 bg-white/95 shadow-md shadow-slate-200/40">
        <h2 className="mb-3 text-base font-semibold text-slate-900">Panel Kirim Peringatan Manual</h2>
        <form onSubmit={submitWithConfirm} className="space-y-4">
          <label className="block text-sm text-slate-700">
            Target Penerima
            <select
              value={target}
              onChange={(event) => setTarget(event.target.value)}
              className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
            >
              <option>Semua Wilayah</option>
              <option>Kecamatan Utara</option>
              <option>Kecamatan Tengah</option>
              <option>Kecamatan Hilir</option>
            </select>
          </label>

          <label className="block text-sm text-slate-700">
            Judul Peringatan
            <input
              value={title}
              onChange={(event) => setTitle(event.target.value)}
              className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
            />
          </label>

          <label className="block text-sm text-slate-700">
            Jenis/Level Peringatan
            <select
              value={level}
              onChange={(event) => setLevel(event.target.value as AlertLevel)}
              className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
            >
              <option value="Aman">Aman</option>
              <option value="Waspada">Waspada</option>
              <option value="Bahaya">Bahaya</option>
            </select>
          </label>

          <div>
            <p className="mb-2 text-sm font-medium text-slate-700">Pilih Saluran</p>
            <div className="flex flex-wrap gap-3 text-sm text-slate-700">
              <label className="inline-flex items-center gap-2 rounded-lg border border-slate-200 px-3 py-2">
                <input type="checkbox" checked={channels.whatsapp} onChange={() => toggleChannel("whatsapp")} /> WhatsApp
              </label>
              <label className="inline-flex items-center gap-2 rounded-lg border border-slate-200 px-3 py-2">
                <input type="checkbox" checked={channels.push} onChange={() => toggleChannel("push")} /> Push Notification
              </label>
              <label className="inline-flex items-center gap-2 rounded-lg border border-slate-200 px-3 py-2">
                <input type="checkbox" checked={channels.email} onChange={() => toggleChannel("email")} /> Email
              </label>
            </div>
          </div>

          <div>
            <div className="mb-2 flex flex-wrap gap-2">
              <Button type="button" variant="secondary" onClick={() => applyTemplate("evakuasi")}>
                Template Evakuasi
              </Button>
              <Button type="button" variant="secondary" onClick={() => applyTemplate("waspada")}>
                Template Waspada
              </Button>
            </div>

            <label className="block text-sm font-medium text-slate-700">Isi Pesan</label>
          </div>

          <textarea
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            className="h-30 w-full rounded-lg border border-slate-300 px-3 py-2"
          />

          <div className="flex items-center gap-3">
            <Button type="submit" className="bg-rose-600 hover:bg-rose-700">
              Siarkan Sekarang
            </Button>
            {sent && <p className="text-sm text-emerald-600">Peringatan berhasil disiarkan.</p>}
          </div>
          {errorMessage && <p className="text-sm text-rose-600">{errorMessage}</p>}
        </form>
      </Card>

      <Card className="border-slate-200 bg-white/95 shadow-md shadow-slate-200/40">
        <h2 className="mb-3 text-base font-semibold text-slate-900">Tabel Riwayat Peringatan</h2>
        <div className="overflow-x-auto">
          <table className="w-full min-w-180 text-left text-sm">
            <thead>
              <tr className="border-b border-slate-200 text-slate-500">
                <th className="py-2">Tanggal & Waktu</th>
                <th className="py-2">Jenis/Level Peringatan</th>
                <th className="py-2">Saluran Digunakan</th>
                <th className="py-2">Pengirim</th>
                <th className="py-2">Status</th>
              </tr>
            </thead>
            <tbody>
              {history.map((item) => (
                <tr key={item.id} className="border-b border-slate-100 align-top">
                  <td className="py-3 text-slate-700">{formatTimestamp(item.sentAt)}</td>
                  <td className="py-3">
                    <span
                      className={`inline-flex rounded-full px-2.5 py-1 text-xs font-semibold ${
                        item.level === "Bahaya"
                          ? "bg-rose-100 text-rose-700"
                          : item.level === "Waspada"
                            ? "bg-amber-100 text-amber-700"
                            : "bg-emerald-100 text-emerald-700"
                      }`}
                    >
                      {item.level}
                    </span>
                  </td>
                  <td className="py-3 text-slate-700">{item.channels.join(", ")}</td>
                  <td className="py-3 text-slate-700">{item.sender}</td>
                  <td className="py-3">
                    <span
                      className={`inline-flex rounded-full px-2.5 py-1 text-xs font-semibold ${
                        item.status === "Berhasil" ? "bg-emerald-100 text-emerald-700" : "bg-rose-100 text-rose-700"
                      }`}
                    >
                      {item.status}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>

      <ConfirmDialog
        open={confirmBroadcastOpen}
        title="Siarkan peringatan sekarang?"
        description="Pesan akan dikirim ke kanal aktif sesuai target wilayah. Pastikan judul dan isi pesan sudah benar."
        confirmText="Ya, siarkan"
        cancelText="Periksa lagi"
        onCancel={() => setConfirmBroadcastOpen(false)}
        onConfirm={() => {
          setConfirmBroadcastOpen(false);
          void sendAlert();
        }}
      />
    </main>
  );
}
