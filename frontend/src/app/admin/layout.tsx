"use client";

import { useEffect, useState } from "react";
import type { PropsWithChildren } from "react";
import Link from "next/link";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { Sidebar } from "@/components/layout/Sidebar";
import { BottomNavbar } from "@/components/layout/BottomNavbar";
import { Button } from "@/components/ui/Button";
import { ConfirmDialog } from "@/components/ui/ConfirmDialog";
import { useAuth } from "@/hooks/useAuth";
import api from "@/lib/api";

export default function AdminLayout({ children }: PropsWithChildren) {
  const router = useRouter();
  const { loading, isAuthenticated, logout, user } = useAuth();
  const [collapsed, setCollapsed] = useState(false);
  const [logoutConfirmOpen, setLogoutConfirmOpen] = useState(false);
  const [unreadCount, setUnreadCount] = useState(0);

  useEffect(() => {
    if (!isAuthenticated || user?.role !== "admin") return;

    const fetchUnreadCount = async () => {
      try {
        const [meResponse, alertsResponse] = await Promise.all([
          api.get("/auth/me"),
          api.get("/alerts/history", {
            params: { page: 1, limit: 100 },
          }),
        ]);

        const notificationReadAt = meResponse.data?.data?.notificationReadAt ?? null;
        const readNotificationIds = meResponse.data?.data?.readNotificationIds ?? [];
        const readAtTime = notificationReadAt ? new Date(notificationReadAt).getTime() : Number.NEGATIVE_INFINITY;
        const rows = (alertsResponse.data?.data?.items ?? []) as Array<{ id: string; sentAt: string }>;

        const count = rows.filter((row) => {
          if (readNotificationIds.includes(row.id)) return false;
          return new Date(row.sentAt).getTime() > readAtTime;
        }).length;
        setUnreadCount(count);
      } catch {
        // ignore
      }
    };

    void fetchUnreadCount();

    window.addEventListener("adminNotificationsUpdated", fetchUnreadCount);

    const timer = setInterval(() => {
      void fetchUnreadCount();
    }, 10000);

    return () => {
      clearInterval(timer);
      window.removeEventListener("adminNotificationsUpdated", fetchUnreadCount);
    };
  }, [isAuthenticated, user]);

  const handleLogout = () => {
    setLogoutConfirmOpen(false);
    logout();
    router.replace("/login");
  };

  if (loading) {
    return <main className="mx-auto w-full max-w-2xl px-6 py-10 text-sm text-slate-600">Memuat sesi admin...</main>;
  }

  if (!isAuthenticated || user?.role !== "admin") {
    return (
      <main className="mx-auto w-full max-w-2xl px-6 py-10">
        <h1 className="text-2xl font-bold text-slate-900">Akses Admin Diperlukan</h1>
        <p className="mt-2 text-sm text-slate-600">
          {isAuthenticated
            ? "Akun ini bukan admin. Gunakan akun admin atau lanjut ke dashboard user."
            : "Silakan login untuk mengakses dashboard admin."}
        </p>
        <div className="mt-4 flex flex-wrap gap-2">
          <Link
            href="/login"
            className="inline-flex rounded-lg bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700"
          >
            Ke Halaman Login
          </Link>
          {isAuthenticated && (
            <Link
              href="/user/dashboard"
              className="inline-flex rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-50"
            >
              Ke Dashboard User
            </Link>
          )}
        </div>
      </main>
    );
  }

  return (
    <div className="flex h-screen w-full overflow-hidden bg-slate-100">
      <Sidebar collapsed={collapsed} onToggle={() => setCollapsed((prev) => !prev)} />

      <section className="flex min-w-0 flex-1 flex-col overflow-hidden">
        <header className="sticky top-0 z-20 border-b border-slate-200/90 bg-white/95 px-4 py-3 backdrop-blur lg:px-6">
          <div className="flex items-center gap-3">
            {/* Collapse Sidebar Button - desktop only */}
            <button
              type="button"
              onClick={() => setCollapsed((prev) => !prev)}
              className="hidden lg:inline-flex h-10 w-10 shrink-0 items-center justify-center rounded-xl border border-slate-200 bg-white text-slate-600 shadow-sm transition-all hover:-translate-y-0.5 hover:bg-slate-50"
              aria-label={collapsed ? "Buka sidebar" : "Ciutkan sidebar"}
              title={collapsed ? "Buka sidebar" : "Ciutkan sidebar"}
            >
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-5 w-5" aria-hidden="true">
                <path strokeLinecap="round" strokeLinejoin="round" d="M4 7h16M4 12h16M4 17h16" />
              </svg>
            </button>

            {/* EWS Brand Logo and Name - mobile & tablet only */}
            <div className="flex items-center gap-2.5 lg:hidden">
              <Image src="/logo.png" alt="EWS Logo" width={28} height={28} className="h-7 w-7 object-contain" />
              <span className="font-bold text-slate-900 text-sm tracking-wide">EWS Flood Guard</span>
            </div>

            <div className="relative hidden min-w-0 flex-1 md:block">
              <svg
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                className="pointer-events-none absolute left-3 top-1/2 h-4.5 w-4.5 -translate-y-1/2 text-slate-400"
                aria-hidden="true"
              >
                <circle cx="11" cy="11" r="7" />
                <path strokeLinecap="round" d="M20 20l-3.2-3.2" />
              </svg>
              <input
                type="text"
                placeholder="Cari sensor, area, laporan, atau pengguna..."
                className="h-11 w-full rounded-2xl border border-slate-200 bg-slate-50 pl-10 pr-4 text-sm text-slate-700 outline-none transition-all placeholder:text-slate-400 focus:border-blue-300 focus:bg-white focus:ring-2 focus:ring-blue-100"
              />
            </div>

            <span className="hidden shrink-0 items-center gap-2 rounded-2xl border border-blue-100 bg-blue-50 px-4 py-2 text-sm font-semibold text-blue-700 md:inline-flex">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-4.5 w-4.5" aria-hidden="true">
                <rect x="3" y="4" width="18" height="17" rx="3" />
                <path strokeLinecap="round" d="M8 2.8v2.4M16 2.8v2.4M3 9h18" />
              </svg>
              Periode: {new Date().getFullYear()}/{new Date().getFullYear() + 1}
            </span>

            <Link
              href="/admin/notifications"
              className="relative inline-flex h-10 w-10 shrink-0 items-center justify-center rounded-xl border border-slate-200 bg-white text-slate-600 shadow-sm transition-all hover:-translate-y-0.5 hover:bg-slate-50"
              aria-label="Notifikasi"
              title="Notifikasi"
            >
              {unreadCount > 0 && (
                <span className="absolute -right-1.5 -top-1.5 inline-flex h-5 min-w-5 items-center justify-center rounded-full bg-rose-500 px-1.5 text-[10px] font-bold text-white animate-pulse">
                  {unreadCount}
                </span>
              )}
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="h-4.5 w-4.5" aria-hidden="true">
                <path strokeLinecap="round" strokeLinejoin="round" d="M12 4a5 5 0 00-5 5v2.4c0 .8-.3 1.6-.8 2.2L5 15.5h14l-1.2-1.9a3.5 3.5 0 01-.8-2.2V9a5 5 0 00-5-5z" />
                <path strokeLinecap="round" d="M10.2 18a2 2 0 003.6 0" />
              </svg>
            </Link>

            <div className="hidden h-8 w-px bg-slate-200 lg:block" />

            <div className="hidden items-center gap-3 lg:flex">
              <div className="text-right">
                <p className="text-sm font-semibold text-slate-800">{user?.name}</p>
                <p className="text-xs text-slate-500">Administrator</p>
              </div>
              <div className="inline-flex h-10 w-10 items-center justify-center rounded-xl bg-linear-to-br from-blue-500 to-cyan-500 text-sm font-bold text-white shadow-sm">
                {(user?.name ?? "A").slice(0, 1).toUpperCase()}
              </div>
            </div>

            <Button variant="secondary" onClick={() => setLogoutConfirmOpen(true)} className="hidden xl:inline-flex">
              Logout
            </Button>
          </div>
        </header>

        {/* Padding bottom added to main container on mobile/tablet to clear the bottom navbar */}
        <main className="flex-1 overflow-y-auto bg-slate-100 p-4 pb-24 lg:p-6 lg:pb-6">
          <div className="mx-auto max-w-7xl">{children}</div>
        </main>
      </section>

      {/* Bottom Navbar for Mobile & Tablet Views */}
      <BottomNavbar
        unreadCount={unreadCount}
        onLogoutClick={() => setLogoutConfirmOpen(true)}
        userName={user?.name}
      />

      <ConfirmDialog
        open={logoutConfirmOpen}
        title="Logout dari dashboard admin?"
        description="Sesi admin akan diakhiri dan Anda akan diarahkan ke halaman login."
        confirmText="Ya, logout"
        cancelText="Batal"
        onCancel={() => setLogoutConfirmOpen(false)}
        onConfirm={handleLogout}
      />
    </div>
  );
}
