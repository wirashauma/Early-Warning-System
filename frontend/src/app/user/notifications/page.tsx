"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { Card } from "@/components/ui/Card";
import { useUserNotifications } from "@/hooks/useUserNotifications";
import { formatTimestamp } from "@/lib/utils";
import api from "@/lib/api"; // WAJIB DIIMPORT UNTUK MEMANGGIL API BACKEND

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

export default function UserNotificationsPage() {
  const { notifications, unreadCount, markAsRead, markAllAsRead, loading, error, isUpdating } = useUserNotifications();
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  useEffect(() => {
    if (!error) return;

    const toastTimer = window.setTimeout(() => setToastMessage(error), 0);
    const timer = window.setTimeout(() => setToastMessage(null), 3500);
    return () => {
      window.clearTimeout(toastTimer);
      window.clearTimeout(timer);
    };
  }, [error]);

  // --- FUNGSI UNTUK MENGETES PUSH NOTIFICATION ---
  const handleTestNotification = async () => {
    try {
      // Kita menembak endpoint broadcast yang sudah ada di backend
      await api.post("/alerts/broadcast", {
        title: "🔔 TES SISTEM EWS",
        message: "Berhasil! Push Notification dari EWS Flood Guard sudah masuk ke perangkat Anda.",
        severity: "INFO",
        channels: ["push"],
        targetArea: "Semua Wilayah" 
      });
      
      // Tampilkan alert standar untuk memberi tahu bahwa request berhasil terkirim
      alert("Request tes notifikasi terkirim! Segera minimize browser Anda dan cek pojok layar dalam 1-3 detik.");
    } catch (error) {
      console.error("Gagal mengirim tes notifikasi:", error);
      alert("Gagal mengirim tes. Cek console browser atau terminal backend.");
    }
  };

  return (
    <main className="mx-auto w-full max-w-6xl px-6 py-8">
      <div className="mb-6 flex flex-col gap-4 md:flex-row md:items-start md:justify-between">
        <div>
          <p className="text-xs font-semibold uppercase tracking-wide text-blue-700">User Notifications</p>
          <h1 className="text-2xl font-bold text-slate-900">Notifikasi Peringatan Banjir</h1>
          <p className="mt-1 text-sm text-slate-600">Saat sensor berstatus kuning, oren, atau merah, notifikasi akan muncul di sini.</p>
        </div>

        {/* --- AREA TOMBOL-TOMBOL --- */}
        <div className="flex flex-wrap items-center gap-3">
          
          {/* TOMBOL TES PUSH NOTIFICATION */}
          <button
            onClick={handleTestNotification}
            className="flex items-center gap-2 rounded-lg bg-blue-100 px-4 py-2 text-sm font-semibold text-blue-700 shadow-sm transition hover:bg-blue-200"
          >
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-4 w-4">
              <path strokeLinecap="round" strokeLinejoin="round" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
            </svg>
            Tes Push Notifikasi
          </button>

          <span className="inline-flex items-center rounded-full bg-rose-50 px-3 py-1.5 text-xs font-semibold text-rose-700">
            Belum dibaca: {unreadCount}
          </span>
          <button
            type="button"
            onClick={() => void markAllAsRead().then(() => setToastMessage("Semua notifikasi ditandai sebagai dibaca.")).catch(() => {})}
            disabled={isUpdating}
            className="rounded-full border border-slate-300 bg-white px-3 py-1.5 text-xs font-semibold text-slate-700 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50"
          >
            {isUpdating ? "Memproses..." : "Tandai semua dibaca"}
          </button>
        </div>
      </div>

      {loading ? (
        <Card>
          <p className="text-sm text-slate-600">Memuat notifikasi...</p>
        </Card>
      ) : notifications.length === 0 ? (
        <Card>
          <h2 className="text-base font-semibold text-slate-900">Belum ada notifikasi risiko</h2>
          <p className="mt-2 text-sm text-slate-600">Notifikasi akan otomatis muncul saat salah satu sensor masuk level Kuning, Oren, atau Merah.</p>
          <div className="mt-4">
            <Link
              href="/user/education"
              className="inline-flex rounded-lg bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700"
            >
              Buka Panduan Umum
            </Link>
          </div>
        </Card>
      ) : (
        <div className="space-y-3">
          {notifications.map((item) => (
            <Link
              key={item.id}
              href={`/user/notifications/${item.id}`}
              className="group block"
              onClick={() => {
                if (!item.isRead) {
                  void markAsRead(item.id).catch(() => {
                    // error state handled by hook + toast
                  });
                }
              }}
            >
              <Card className={`transition-colors group-hover:bg-slate-50 ${item.isRead ? "border-slate-200" : "border-blue-200 bg-blue-50/30"}`}>
                <div className="flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
                  <div>
                    <div className="flex flex-wrap items-center gap-2">
                      <h2 className="text-base font-semibold text-slate-900">{item.title}</h2>
                      <span className={`inline-flex rounded-full px-2.5 py-1 text-xs font-semibold ${levelBadgeClass[item.riskLevel]}`}>
                        {levelLabel[item.riskLevel]}
                      </span>
                      {!item.isRead && <span className="text-xs font-semibold text-blue-700">Baru</span>}
                    </div>

                    <p className="mt-2 text-sm text-slate-700">{item.message}</p>
                    <p className="mt-1 text-xs text-slate-500">
                      Target: {item.sensorName} • Waktu: {formatTimestamp(item.createdAt)}
                    </p>
                    <div className="mt-2 flex flex-wrap items-center gap-2 text-xs">
                      <span
                        className={`rounded-full px-2.5 py-1 font-semibold ${
                          item.sourceType === "ADMIN"
                            ? "bg-blue-100 text-blue-700"
                            : "bg-slate-100 text-slate-700"
                        }`}
                      >
                        {item.sourceType === "ADMIN" ? "Dari Admin" : "Dari Sistem"}
                      </span>
                      <span className="text-slate-500">{item.senderName}</span>
                      {item.channels.length > 0 && (
                        <span className="rounded-full bg-slate-100 px-2.5 py-1 font-semibold text-slate-700">
                          Kanal: {item.channels.join(", ")}
                        </span>
                      )}
                    </div>
                  </div>

                  <div className="inline-flex items-center rounded-lg border border-slate-300 bg-white px-3 py-1.5 text-xs font-semibold text-slate-700 transition-colors group-hover:border-blue-300 group-hover:text-blue-700">
                    Buka Detail
                  </div>
                </div>
              </Card>
            </Link>
          ))}
        </div>
      )}

      {toastMessage && (
        <div className="fixed bottom-6 right-6 z-50 max-w-sm rounded-2xl border border-slate-200 bg-white px-4 py-3 shadow-xl shadow-slate-900/10">
          <p className="text-sm font-semibold text-blue-700">Notifikasi</p>
          <p className="mt-1 text-sm text-slate-600">{toastMessage}</p>
        </div>
      )}
    </main>
  );
}