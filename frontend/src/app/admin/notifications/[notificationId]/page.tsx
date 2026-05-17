"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { Card } from "@/components/ui/Card";
import api from "@/lib/api";
import { formatTimestamp } from "@/lib/utils";

export default function AdminNotificationDetailPage() {
  const params = useParams<{ notificationId: string | string[] }>();
  const notificationId = useMemo(() => {
    if (!params?.notificationId) return "";
    return Array.isArray(params.notificationId) ? params.notificationId[0] : params.notificationId;
  }, [params]);

  const [loading, setLoading] = useState(true);
  const [data, setData] = useState<any | null>(null);

  useEffect(() => {
    let cancelled = false;

    const load = async () => {
      if (!notificationId) {
        if (!cancelled) {
          setData(null);
          setLoading(false);
        }
        return;
      }

      try {
        const res = await api.get(`/alerts/${notificationId}`);
        if (!cancelled) {
          setData(res.data?.data ?? null);
          setLoading(false);
        }
      } catch (err) {
        if (!cancelled) {
          setData(null);
          setLoading(false);
        }
      }
    };

    void load();

    return () => {
      cancelled = true;
    };
  }, [notificationId]);

  if (loading) {
    return (
      <main className="mx-auto w-full max-w-4xl px-6 py-8">
        <Card>
          <p className="text-sm text-slate-600">Memuat detail notifikasi...</p>
        </Card>
      </main>
    );
  }

  if (!data) {
    return (
      <main className="mx-auto w-full max-w-4xl px-6 py-8">
        <Card>
          <h1 className="text-lg font-bold text-slate-900">Detail notifikasi tidak ditemukan</h1>
          <p className="mt-2 text-sm text-slate-600">Notifikasi mungkin sudah dihapus atau tidak dapat diambil.</p>
          <div className="mt-4">
            <Link href="/admin/notifications" className="inline-flex rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50">
              Kembali ke Inbox Admin
            </Link>
          </div>
        </Card>
      </main>
    );
  }

  const severity = data.severity ?? "INFO";

  return (
    <main className="mx-auto w-full max-w-4xl px-6 py-8">
      <div className="mb-4 flex flex-wrap items-center gap-2 text-sm text-slate-500">
        <Link href="/admin" className="hover:text-blue-700">Admin</Link>
        <span>›</span>
        <Link href="/admin/notifications" className="hover:text-blue-700">Inbox Notifikasi</Link>
        <span>›</span>
        <span className="text-slate-700">Detail</span>
      </div>

      <Card>
        <div className="flex items-start justify-between gap-4">
          <div>
            <p className="text-xs font-semibold uppercase tracking-wide text-blue-700">Detail Inbox</p>
            <h1 className="mt-1 text-2xl font-bold text-slate-900">{data.title}</h1>
            <p className="mt-2 text-sm leading-relaxed text-slate-700">{data.message}</p>
            <p className="mt-3 text-xs text-slate-500">Dikirim: {formatTimestamp(data.sentAt || data.receivedAt || new Date().toISOString())}</p>
          </div>

          <div className="shrink-0">
            <span className={`inline-flex rounded-full px-3 py-1 text-xs font-semibold ${
              severity === 'DANGER' ? 'bg-rose-100 text-rose-700' : severity === 'WARNING' ? 'bg-orange-100 text-orange-700' : 'bg-amber-100 text-amber-700'
            }`}>
              {severity}
            </span>
          </div>
        </div>

        <div className="mt-6 grid gap-3 md:grid-cols-3">
          <div className="rounded-lg border border-slate-200 bg-white px-3 py-2">
            <p className="text-xs text-slate-500">Pengirim</p>
            <p className="text-sm font-semibold text-slate-800">{data.user?.name ?? data.source ?? 'Sistem EWS'}</p>
          </div>

          <div className="rounded-lg border border-slate-200 bg-white px-3 py-2">
            <p className="text-xs text-slate-500">Kanal</p>
            <p className="text-sm font-semibold text-slate-800">{(data.channels || []).join(', ') || 'push'}</p>
          </div>

          <div className="rounded-lg border border-slate-200 bg-white px-3 py-2">
            <p className="text-xs text-slate-500">Target Area</p>
            <p className="text-sm font-semibold text-slate-800">{data.targetArea ?? 'Semua Wilayah'}</p>
          </div>
        </div>
      </Card>
    </main>
  );
}
