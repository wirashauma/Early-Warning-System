"use client";

import { useEffect, useMemo, useState } from "react";
import { createPortal } from "react-dom";
import { useRouter } from "next/navigation";
import { Card } from "@/components/ui/Card";
import { formatTimestamp } from "@/lib/utils";
import api from "@/lib/api";

type NotificationConditionLevel = "Aman" | "Waspada" | "Bahaya";

const levelDotClass: Record<NotificationConditionLevel, string> = {
  Aman: "bg-emerald-500",
  Waspada: "bg-amber-500",
  Bahaya: "bg-rose-500",
};

const ADMIN_NOTIFICATION_STORAGE_KEY = "ews_admin_notifications_read_map";

function parseReadMap(raw: string | null): Record<string, boolean> {
  if (!raw) return {};
  try {
    const parsed = JSON.parse(raw) as Record<string, boolean>;
    return parsed && typeof parsed === "object" ? parsed : {};
  } catch {
    return {};
  }
}

export default function AdminNotificationsPage() {
  const router = useRouter();
  const [items, setItems] = useState<Array<{
    id: string;
    subject: string;
    message: string;
    level: NotificationConditionLevel;
    sender: string;
    channel: string;
    receivedAt: string;
    isRead: boolean;
  }>>([]);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [deleteConfirm, setDeleteConfirm] = useState<{ id: string; subject: string } | null>(null);
  const [openMenu, setOpenMenu] = useState<string | null>(null);
  const mounted = typeof window !== "undefined";

  useEffect(() => {
    const load = async () => {
      setErrorMessage(null);
      try {
        const response = await api.get("/alerts/history", {
          params: { page: 1, limit: 100 },
        });

        const rows = (response.data?.data?.items ?? []) as Array<{
          id: string;
          title: string;
          message: string;
          severity: "INFO" | "WARNING" | "DANGER";
          channels: string[];
          sentAt: string;
          user?: { name?: string };
        }>;

        const savedReadMap = typeof window !== "undefined"
          ? parseReadMap(localStorage.getItem(ADMIN_NOTIFICATION_STORAGE_KEY))
          : {};

        setItems(
          rows.map((row) => ({
            id: row.id,
            subject: row.title,
            message: row.message,
            level: row.severity === "DANGER" ? "Bahaya" : row.severity === "WARNING" ? "Waspada" : "Aman",
            sender: row.user?.name ?? "Sistem EWS",
            channel: row.channels?.[0] ?? "push",
            receivedAt: row.sentAt,
            isRead: Boolean(savedReadMap[row.id]),
          })),
        );
      } catch (error) {
        setErrorMessage(error instanceof Error ? error.message : "Gagal memuat notifikasi.");
      }
    };

    void load();
  }, []);

  const handleDelete = (id: string) => {
    setItems((prev) => prev.filter((item) => item.id !== id));
    setDeleteConfirm(null);
    setOpenMenu(null);

    if (typeof window !== "undefined") {
      const savedReadMap = parseReadMap(localStorage.getItem(ADMIN_NOTIFICATION_STORAGE_KEY));
      savedReadMap[id] = true;
      localStorage.setItem(ADMIN_NOTIFICATION_STORAGE_KEY, JSON.stringify(savedReadMap));
      window.dispatchEvent(new CustomEvent("adminNotificationsUpdated"));
    }
  };

  const handleMarkAsRead = (id: string) => {
    setItems((prev) => prev.map((item) => (item.id === id ? { ...item, isRead: true } : item)));
    setOpenMenu(null);

    if (typeof window !== "undefined") {
      const savedReadMap = parseReadMap(localStorage.getItem(ADMIN_NOTIFICATION_STORAGE_KEY));
      savedReadMap[id] = true;
      localStorage.setItem(ADMIN_NOTIFICATION_STORAGE_KEY, JSON.stringify(savedReadMap));
      window.dispatchEvent(new CustomEvent("adminNotificationsUpdated"));
    }
  };

  useEffect(() => {
    if (!openMenu) return;

    const handler = () => setOpenMenu(null);
    document.addEventListener("click", handler);
    return () => document.removeEventListener("click", handler);
  }, [openMenu]);

  const unreadCount = useMemo(() => items.filter((item) => !item.isRead).length, [items]);
  const dangerCount = useMemo(() => items.filter((item) => item.level === "Bahaya").length, [items]);
  const conditionCount = useMemo(() => {
    const levels = new Set(items.map((item) => item.level));
    return levels.size;
  }, [items]);

  return (
    <main className="space-y-6 bg-slate-50/40 pb-8">
      <div className="relative overflow-hidden rounded-3xl border border-blue-100/80 bg-linear-to-br from-white via-sky-50/60 to-blue-50/85 p-6 shadow-[0_18px_50px_-28px_rgba(15,23,42,0.35)] md:p-8">
        <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_top_right,rgba(59,130,246,0.12),transparent_40%)]" />
        <div className="pointer-events-none absolute inset-y-0 right-0 w-56 bg-[linear-gradient(180deg,rgba(59,130,246,0.05),transparent_60%,rgba(14,165,233,0.05))]" />

        <div className="relative flex flex-col gap-4 md:items-start md:justify-between md:gap-6">
          <div className="max-w-3xl space-y-3">
            <div className="inline-flex items-center gap-2 rounded-full border border-blue-100 bg-white/75 px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.18em] text-blue-700 shadow-sm backdrop-blur">
              <span className="size-2 rounded-full bg-blue-500" />
              Flood Guard · Admin Inbox
            </div>
            <div className="space-y-2">
              <h1 className="text-3xl font-semibold tracking-tight text-slate-900 md:text-4xl">Notifikasi & Inbox Admin</h1>
              <p className="max-w-2xl text-sm leading-6 text-slate-600 md:text-[15px]">
                Ringkasan kondisi peringatan dari Aman hingga Bahaya, lengkap dengan pesan inbox lintas kanal komunikasi.
              </p>
            </div>
          </div>
        </div>
      </div>

      <div className="grid gap-4 md:grid-cols-3">
        <Card className="border border-slate-100 bg-white/95 p-5 shadow-sm shadow-slate-200/60 backdrop-blur-sm">
          <div className="flex items-start justify-between gap-4">
            <div>
              <p className="text-sm font-medium text-slate-500">Kondisi Peringatan</p>
              <p className="mt-2 text-3xl font-semibold tracking-tight text-slate-900">{conditionCount}</p>
              <p className="mt-1 text-xs text-slate-500">Aman, Waspada, Bahaya</p>
            </div>
            <div className="flex size-11 items-center justify-center rounded-2xl bg-blue-100 text-blue-700">
              <svg viewBox="0 0 24 24" className="size-5" fill="none" aria-hidden="true">
                <path d="M12 3v18M3 12h18" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
              </svg>
            </div>
          </div>
        </Card>

        <Card className="border border-slate-100 bg-white/95 p-5 shadow-sm shadow-slate-200/60 backdrop-blur-sm">
          <div className="flex items-start justify-between gap-4">
            <div>
              <p className="text-sm font-medium text-slate-500">Total Pesan Inbox</p>
              <p className="mt-2 text-3xl font-semibold tracking-tight text-cyan-700">{items.length}</p>
              <p className="mt-1 text-xs text-slate-500">Push, WhatsApp, Email, SMS</p>
            </div>
            <div className="flex size-11 items-center justify-center rounded-2xl bg-cyan-100 text-cyan-700">
              <svg viewBox="0 0 24 24" className="size-5" fill="none" aria-hidden="true">
                <path d="M20 4H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h14l4 4V6c0-1.1-.9-2-2-2Z" stroke="currentColor" strokeWidth="1.8" strokeLinejoin="round" />
              </svg>
            </div>
          </div>
        </Card>

        <Card className="border border-slate-100 bg-white/95 p-5 shadow-sm shadow-slate-200/60 backdrop-blur-sm">
          <div className="flex items-start justify-between gap-4">
            <div>
              <p className="text-sm font-medium text-slate-500">Belum Dibaca</p>
              <p className="mt-2 text-3xl font-semibold tracking-tight text-amber-600">{unreadCount}</p>
              <p className="mt-1 text-xs text-slate-500">Pesan butuh atensi admin</p>
            </div>
            <div className="flex size-11 items-center justify-center rounded-2xl bg-amber-100 text-amber-600">
              <svg viewBox="0 0 24 24" className="size-5" fill="none" aria-hidden="true">
                <circle cx="12" cy="12" r="1" fill="currentColor" />
                <circle cx="19" cy="12" r="1" fill="currentColor" />
                <circle cx="5" cy="12" r="1" fill="currentColor" />
              </svg>
            </div>
          </div>
        </Card>
      </div>

      <Card className="border border-slate-100 bg-white/96 p-0 shadow-[0_18px_50px_-32px_rgba(15,23,42,0.28)] backdrop-blur-sm">
          <div className="flex flex-col gap-3 border-b border-slate-100 px-6 py-5 md:flex-row md:items-center md:justify-between">
            <div>
              <h2 className="text-lg font-semibold tracking-tight text-slate-900">Inbox Notifikasi</h2>
              <p className="mt-1 text-sm text-slate-500">Pesan masuk berdasarkan beragam kondisi peringatan.</p>
            </div>
            <div className="inline-flex items-center gap-2 self-start rounded-full border border-rose-200 bg-rose-50 px-3 py-1.5 text-xs font-semibold text-rose-700 md:self-auto">
              <span className="size-2 rounded-full bg-rose-500" />
              {dangerCount} pesan level Bahaya
            </div>
          </div>

          <div className="divide-y divide-slate-100">
                {items.map((item) => (
                  <article
                    key={item.id}
                    role="button"
                    onClick={() => {
                      try {
                        handleMarkAsRead(item.id);
                        router.push(`/admin/notifications/${item.id}`);
                      } catch {
                        // ignore
                      }
                    }}
                    className={`group relative px-6 py-4 transition-all duration-150 cursor-pointer ${
                      item.isRead ? "bg-white hover:bg-slate-50/60" : "bg-blue-50/30 hover:bg-blue-50/50"
                    }`}
                  >
                <div className="flex flex-col gap-3">
                      <div className="flex items-center justify-between gap-3">
                    <div className="flex-1 min-w-0">
                      <div className="flex flex-wrap items-center gap-2">
                        <span className={`h-2.5 w-2.5 shrink-0 rounded-full ${levelDotClass[item.level]}`} />
                        <h3 className="text-sm font-semibold text-slate-900">{item.subject}</h3>
                        {!item.isRead && (
                          <span className="inline-flex items-center gap-1 rounded-full bg-blue-100 px-2.5 py-0.5 text-[10px] font-semibold text-blue-700">
                            <span className="size-1.5 animate-pulse rounded-full bg-blue-600" />
                            Baru
                          </span>
                        )}
                      </div>
                      <p className="mt-2 line-clamp-2 text-sm text-slate-600">{item.message}</p>
                    </div>

                    <div className="relative shrink-0">
                      <button
                        type="button"
                        onClick={(e) => {
                          e.stopPropagation();
                          setOpenMenu(openMenu === item.id ? null : item.id);
                        }}
                        className="rounded-lg p-2 text-slate-500 transition-all hover:bg-slate-100 hover:text-slate-700"
                        aria-label="Menu aksi notifikasi"
                      >
                        <svg viewBox="0 0 24 24" className="size-5" fill="currentColor" aria-hidden="true">
                          <circle cx="12" cy="5" r="1.5" />
                          <circle cx="12" cy="12" r="1.5" />
                          <circle cx="12" cy="19" r="1.5" />
                        </svg>
                      </button>

                      {openMenu === item.id && (
                        <div className="absolute right-0 top-full mt-1 w-48 overflow-hidden rounded-xl border border-slate-200 bg-white shadow-[0_16px_40px_-20px_rgba(15,23,42,0.45)]" onClick={(e) => e.stopPropagation()}>
                          <button
                            type="button"
                            onClick={(e) => {
                              e.stopPropagation();
                              handleMarkAsRead(item.id);
                            }}
                            disabled={item.isRead}
                            className="flex w-full items-center gap-3 px-4 py-3 text-sm font-medium text-slate-700 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50 disabled:hover:bg-white"
                          >
                            <svg viewBox="0 0 24 24" className="size-4" fill="none" aria-hidden="true">
                              <path d="M5 13l4 4L19 7" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
                            </svg>
                            Tandai telah dibaca
                          </button>
                          <div className="border-t border-slate-100" />
                          <button
                            type="button"
                            onClick={(e) => {
                              e.stopPropagation();
                              setDeleteConfirm({ id: item.id, subject: item.subject });
                            }}
                            className="flex w-full items-center gap-3 px-4 py-3 text-sm font-medium text-rose-600 transition hover:bg-rose-50"
                          >
                            <svg viewBox="0 0 24 24" className="size-4" fill="none" aria-hidden="true">
                              <path d="M4 7h16M8 7V5.5A1.5 1.5 0 0 1 9.5 4h5A1.5 1.5 0 0 1 16 5.5V7m-7 0v11a1 1 0 0 0 1 1h4a1 1 0 0 0 1-1V7" stroke="currentColor" strokeWidth="1.8" strokeLinejoin="round" />
                              <path d="M10 11v4M14 11v4" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
                            </svg>
                            Hapus pesan
                          </button>
                        </div>
                      )}
                    </div>
                  </div>

                  <div className="flex flex-wrap items-center gap-2 text-xs">
                    <span
                      className={`inline-flex items-center rounded-full px-2.5 py-1 font-semibold ring-1 ring-inset ${
                        item.level === "Bahaya"
                          ? "bg-rose-50 text-rose-700 ring-rose-100"
                          : item.level === "Waspada"
                            ? "bg-amber-50 text-amber-700 ring-amber-100"
                            : "bg-emerald-50 text-emerald-700 ring-emerald-100"
                      }`}
                    >
                      {item.level}
                    </span>
                    <span className="inline-flex rounded-full border border-slate-200 bg-slate-50 px-2.5 py-1 font-semibold text-slate-600">{item.channel}</span>
                    <span className="text-slate-500">{item.sender}</span>
                    <span className="text-slate-400">•</span>
                    <span className="text-slate-400">{formatTimestamp(item.receivedAt)}</span>
                  </div>
                </div>
              </article>
            ))}
          </div>
        </Card>

      {errorMessage && (
        <div className="rounded-2xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm font-medium text-rose-700 shadow-sm">
          {errorMessage}
        </div>
      )}

      {mounted &&
        deleteConfirm &&
        createPortal(
          <div className="fixed inset-0 z-70 flex items-center justify-center bg-slate-950/35 p-4 backdrop-blur-[2px]">
            <div className="w-full max-w-md overflow-hidden rounded-3xl border border-slate-100 bg-white shadow-[0_24px_70px_-32px_rgba(15,23,42,0.55)]">
              <div className="border-b border-slate-100 bg-rose-50/70 px-5 py-4">
                <div className="inline-flex items-center gap-2 rounded-full border border-rose-200 bg-white px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.18em] text-rose-700">
                  <span className="size-2 rounded-full bg-rose-500" />
                  Konfirmasi Aksi
                </div>
              </div>

              <div className="px-5 py-5">
                <h3 className="text-lg font-semibold tracking-tight text-slate-900">Hapus Notifikasi?</h3>
                <p className="mt-2 text-sm leading-relaxed text-slate-600">
                  Tindakan ini akan menghapus notifikasi &quot;{deleteConfirm.subject}&quot; dari inbox Anda. Perubahan ini tidak dapat dibatalkan.
                </p>

                <div className="mt-6 flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
                  <button
                    type="button"
                    onClick={() => setDeleteConfirm(null)}
                    className="rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-700 transition hover:bg-slate-50"
                  >
                    Batal
                  </button>
                  <button
                    type="button"
                    onClick={() => handleDelete(deleteConfirm.id)}
                    className="rounded-xl bg-rose-600 px-4 py-2.5 text-sm font-semibold text-white shadow-sm transition hover:bg-rose-700"
                  >
                    Hapus
                  </button>
                </div>
              </div>
            </div>
          </div>,
          document.body,
        )}
    </main>
  );
}
