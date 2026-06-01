"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { Card } from "@/components/ui/Card";
import api from "@/lib/api";
import { formatTimestamp } from "@/lib/utils";
import type { UserNotificationItem } from "@/types/user-notification";

const levelBadgeClass = {
  yellow: "bg-amber-100 text-amber-700",
  orange: "bg-orange-100 text-orange-700",
  red: "bg-rose-100 text-rose-700",
} as const;

const levelLabel = {
  yellow: "Kuning",
  orange: "Oren",
  red: "Merah",
} as const;

const levelQuickAction = {
  yellow: "Pantau dashboard tiap 10-15 menit dan siapkan tas siaga keluarga.",
  orange: "Mulai pra-evakuasi, pindahkan barang penting, dan prioritaskan anggota rentan.",
  red: "Lakukan evakuasi segera ke titik aman resmi dan hubungi layanan darurat jika diperlukan.",
} as const;

function parseReadMap(raw: string | null): Record<string, boolean> {
  if (!raw) {
    return {};
  }

  try {
    const parsed = JSON.parse(raw) as Record<string, boolean>;
    return parsed && typeof parsed === "object" ? parsed : {};
  } catch {
    return {};
  }
}

function mapSeverityToRiskLevel(severity: string): UserNotificationItem["riskLevel"] {
  if (severity === "DANGER") {
    return "red";
  }

  if (severity === "WARNING") {
    return "orange";
  }

  return "yellow";
}

function mapSeverityToGuideHref(severity: string): string {
  if (severity === "DANGER") {
    return "/user/education#aksi-merah";
  }

  if (severity === "WARNING") {
    return "/user/education#aksi-oren";
  }

  return "/user/education#aksi-kuning";
}

function isNotificationRead(sentAt: string, notificationReadAt: string | null, id: string, readNotificationIds: string[]) {
  if (readNotificationIds.includes(id)) {
    return true;
  }
  if (!notificationReadAt) {
    return false;
  }

  return new Date(sentAt).getTime() <= new Date(notificationReadAt).getTime();
}

export default function UserNotificationDetailPage() {
  const params = useParams<{ notificationId: string | string[] }>();
  const notificationId = useMemo(() => {
    if (!params?.notificationId) {
      return "";
    }

    return Array.isArray(params.notificationId) ? params.notificationId[0] : params.notificationId;
  }, [params]);

  const [loading, setLoading] = useState(true);
  const [notification, setNotification] = useState<UserNotificationItem | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;

    const loadDetail = async () => {
      setErrorMessage(null);

      if (!notificationId) {
        if (!cancelled) {
          setNotification(null);
          setLoading(false);
        }
        return;
      }

      try {
        const [meResponse, response] = await Promise.all([
          api.get("/auth/me"),
          api.get(`/alerts/${notificationId}`),
        ]);

        const notificationReadAt = meResponse.data?.data?.notificationReadAt ?? null;
        const readNotificationIds = meResponse.data?.data?.readNotificationIds ?? [];
        const row = response.data?.data as {
          id: string;
          title: string;
          message: string;
          severity: string;
          channels?: string[];
          sourceType?: "ADMIN" | "SYSTEM";
          user?: {
            name?: string | null;
          } | null;
          targetArea?: string | null;
          sentAt: string;
        };

        if (!isNotificationRead(row.sentAt, notificationReadAt, row.id, readNotificationIds)) {
          await api.put(`/auth/notifications/${row.id}/read`);
          window.dispatchEvent(new CustomEvent("notificationsUpdated"));
        }

        const sourceType = row.sourceType ?? (row.user?.name ? "ADMIN" : "SYSTEM");

        const mapped: UserNotificationItem = {
          id: row.id,
          sensorId: row.targetArea || "WILAYAH",
          sensorName: row.targetArea || "Wilayah Umum",
          levelCm: 0,
          riskLevel: mapSeverityToRiskLevel(row.severity),
          title: row.title,
          message: row.message,
          createdAt: row.sentAt,
          isRead: true,
          guideHref: mapSeverityToGuideHref(row.severity),
          senderName: row.user?.name?.trim() || (sourceType === "ADMIN" ? "Admin EWS" : "Sistem EWS"),
          sourceType,
          channels: row.channels ?? [],
        };

        if (!cancelled) {
          setNotification(mapped);
          setLoading(false);
        }
      } catch {
        if (!cancelled) {
          setNotification(null);
          setErrorMessage("Gagal memuat detail notifikasi.");
          setLoading(false);
        }
      }
    };

    void loadDetail();

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

  if (!notification) {
    return (
      <main className="mx-auto w-full max-w-4xl px-6 py-8">
        <Card>
          <h1 className="text-lg font-bold text-slate-900">Detail notifikasi tidak ditemukan</h1>
          <p className="mt-2 text-sm text-slate-600">
            {errorMessage ?? "Notifikasi mungkin sudah tidak tersedia. Kembali ke daftar notifikasi untuk melihat data terbaru."}
          </p>
          <div className="mt-4">
            <Link
              href="/user/notifications"
              className="inline-flex rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50"
            >
              Kembali ke Notifikasi
            </Link>
          </div>
        </Card>
      </main>
    );
  }

  return (
    <main className="mx-auto w-full max-w-4xl px-6 py-8">
      <div className="mb-4 flex flex-wrap items-center gap-2 text-sm text-slate-500">
        <Link href="/user/dashboard" className="hover:text-blue-700">Dashboard</Link>
        <span>›</span>
        <Link href="/user/notifications" className="hover:text-blue-700">Notifikasi</Link>
        <span>›</span>
        <span className="text-slate-700">Detail</span>
      </div>

      <Card className={notification.isRead ? "border-slate-200" : "border-blue-200 bg-blue-50/30"}>
        <div className="flex flex-wrap items-start justify-between gap-3">
          <div>
            <p className="text-xs font-semibold uppercase tracking-wide text-blue-700">Detail Notifikasi</p>
            <h1 className="mt-1 text-2xl font-bold text-slate-900">{notification.title}</h1>
            <p className="mt-2 text-sm leading-relaxed text-slate-700">{notification.message}</p>
          </div>

          <span className={`inline-flex rounded-full px-3 py-1 text-xs font-semibold ${levelBadgeClass[notification.riskLevel]}`}>
            {levelLabel[notification.riskLevel]}
          </span>
        </div>

        <div className="mt-4 grid gap-3 md:grid-cols-3">
          <div className="rounded-lg border border-slate-200 bg-white px-3 py-2">
            <p className="text-xs text-slate-500">Sensor</p>
            <p className="text-sm font-semibold text-slate-800">{notification.sensorName} ({notification.sensorId})</p>
          </div>
          <div className="rounded-lg border border-slate-200 bg-white px-3 py-2">
            <p className="text-xs text-slate-500">Level Air</p>
            <p className="text-sm font-semibold text-slate-800">{notification.levelCm} cm</p>
          </div>
          <div className="rounded-lg border border-slate-200 bg-white px-3 py-2">
            <p className="text-xs text-slate-500">Waktu Notifikasi</p>
            <p className="text-sm font-semibold text-slate-800">{formatTimestamp(notification.createdAt)}</p>
          </div>
        </div>

        <div className="mt-3 grid gap-3 md:grid-cols-2">
          <div className="rounded-lg border border-slate-200 bg-white px-3 py-2">
            <p className="text-xs text-slate-500">Sumber</p>
            <p className="text-sm font-semibold text-slate-800">
              {notification.sourceType === "ADMIN" ? "Admin" : "Sistem"} • {notification.senderName}
            </p>
          </div>
          <div className="rounded-lg border border-slate-200 bg-white px-3 py-2">
            <p className="text-xs text-slate-500">Kanal Notifikasi</p>
            <p className="text-sm font-semibold text-slate-800">
              {notification.channels.length > 0 ? notification.channels.join(", ") : "push"}
            </p>
          </div>
        </div>

        <div className="mt-4 rounded-xl border border-blue-100 bg-blue-50 p-4">
          <h2 className="text-sm font-semibold text-blue-900">Rekomendasi Cepat</h2>
          <p className="mt-1 text-sm text-blue-900/90">{levelQuickAction[notification.riskLevel]}</p>
        </div>

        <div className="mt-5 flex flex-wrap items-center gap-2">
          <Link
            href={notification.guideHref}
            className="inline-flex rounded-lg bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700"
          >
            Buka Tab Panduan Sesuai Level
          </Link>
          <Link
            href="/user/notifications"
            className="inline-flex rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50"
          >
            Kembali ke Daftar Notifikasi
          </Link>
        </div>
      </Card>
    </main>
  );
}
