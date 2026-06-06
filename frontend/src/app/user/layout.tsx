"use client";

import type { PropsWithChildren } from "react";
import { UserBottomNavbar } from "@/components/layout/UserBottomNavbar";
import { useAuth } from "@/hooks/useAuth";

export default function UserLayout({ children }: PropsWithChildren) {
  const { loading } = useAuth();

  if (loading) {
    return (
      <main className="mx-auto w-full max-w-2xl px-6 py-12 text-center text-sm text-slate-500">
        Memuat sesi pengguna...
      </main>
    );
  }

  return (
    <div className="relative min-h-screen bg-slate-50/50 pb-24 lg:pb-0">
      {children}
      <UserBottomNavbar />
    </div>
  );
}
