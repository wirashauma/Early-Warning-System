"use client";

import type { PropsWithChildren } from "react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Sidebar } from "@/components/layout/Sidebar";
import { Button } from "@/components/ui/Button";
import { useAuth } from "@/hooks/useAuth";

export default function AdminLayout({ children }: PropsWithChildren) {
  const pathname = usePathname();
  const { loading, isAuthenticated, logout, user } = useAuth();

  if (pathname === "/admin/login") {
    return <main className="mx-auto w-full max-w-lg px-6 py-10">{children}</main>;
  }

  if (loading) {
    return <main className="mx-auto w-full max-w-2xl px-6 py-10 text-sm text-slate-600">Memuat sesi admin...</main>;
  }

  if (!isAuthenticated) {
    return (
      <main className="mx-auto w-full max-w-2xl px-6 py-10">
        <h1 className="text-2xl font-bold text-slate-900">Akses Admin Diperlukan</h1>
        <p className="mt-2 text-sm text-slate-600">Silakan login untuk mengakses dashboard admin.</p>
        <Link
          href="/admin/login"
          className="mt-4 inline-flex rounded-lg bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700"
        >
          Ke Halaman Login
        </Link>
      </main>
    );
  }

  return (
    <div className="mx-auto flex w-full max-w-6xl flex-col gap-4 px-6 py-8 md:flex-row">
      <Sidebar />
      <section className="w-full space-y-4">
        <div className="flex items-center justify-between rounded-xl border border-slate-200 bg-white p-4">
          <div>
            <p className="text-xs uppercase tracking-wide text-slate-500">Admin Session</p>
            <h2 className="text-sm font-semibold text-slate-800">{user?.name}</h2>
          </div>
          <Button variant="secondary" onClick={logout}>
            Logout
          </Button>
        </div>
        {children}
      </section>
    </div>
  );
}
