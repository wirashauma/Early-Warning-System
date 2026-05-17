"use client";

import { FormEvent, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { useAuth } from "@/hooks/useAuth";
import type { UserRole } from "@/types/user";

const getRedirectPathByRole = (role: UserRole | string) => {
  const normalized = String(role ?? "").toUpperCase();
  if (normalized === "ADMIN") {
    return "/admin/dashboard";
  }
  return "/user/dashboard";
};

export default function LoginPage() {
  const router = useRouter();
  const { login, loginWithGoogle } = useAuth();
  
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const completeLoginRedirect = (role: UserRole | string) => {
    setTimeout(() => {
      router.push(getRedirectPathByRole(role));
    }, 700);
  };

  const loginAndRedirect = async (
    selectedEmail: string,
    selectedPassword: string,
    successMessage: string,
  ) => {
    setIsSubmitting(true);
    setError(null);
    setSuccess(null);

    const result = await login(selectedEmail, selectedPassword);

    if (!result.ok) {
      setError(result.message);
      setIsSubmitting(false);
      return;
    }

    if (!result.user) {
      setError("Data user tidak ditemukan setelah login.");
      setIsSubmitting(false);
      return;
    }

    setSuccess(successMessage);
    completeLoginRedirect(result.user.role);
  };

  const onSubmit = async (event: FormEvent) => {
    event.preventDefault();
    if (!email || !password) {
      setError("Email dan password wajib diisi.");
      return;
    }

    await loginAndRedirect(email, password, "Login berhasil. Mengalihkan ke dashboard...");
  };

  const onGoogleLogin = async () => {
    setError(null);
    setSuccess(null);
    setIsSubmitting(true);

    const result = await loginWithGoogle();

    if (!result.ok) {
      setError(result.message);
      setIsSubmitting(false);
      return;
    }

    setSuccess("Login dengan Google berhasil. Mengalihkan ke dashboard...");
    setTimeout(() => {
      if (result.user) {
        router.push(getRedirectPathByRole(result.user.role));
      }
    }, 700);
  };

  const onQuickLogin = async (quickEmail: string, quickPass: string) => {
    setEmail(quickEmail);
    setPassword(quickPass);
    await loginAndRedirect(
      quickEmail,
      quickPass,
      "Login cepat berhasil. Mengalihkan ke dashboard...",
    );
  };

  return (
    <main className="relative flex min-h-screen items-center justify-center overflow-hidden bg-sky-50 px-6 py-10">
      <div className="absolute inset-0">
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_top_right,rgba(14,165,233,0.22),transparent_44%)]" />
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_bottom_left,rgba(59,130,246,0.2),transparent_48%)]" />
        <div className="absolute inset-0 bg-[linear-gradient(180deg,rgba(239,246,255,0.95),rgba(219,234,254,0.72))]" />
      </div>

      <div className="relative grid w-full max-w-5xl gap-6 lg:grid-cols-[1.05fr_1fr]">
        <section className="hidden rounded-2xl border border-blue-200/70 bg-white/75 p-8 text-slate-800 shadow-sm backdrop-blur-sm lg:block">
          <p className="inline-flex rounded-full border border-blue-200 bg-blue-50 px-3 py-1 text-xs font-semibold uppercase tracking-wide text-blue-700">
            EWS Flood Guard
          </p>
          <h1 className="mt-5 text-3xl font-bold leading-tight">Masuk ke Platform Monitoring Banjir Real-Time</h1>
          <p className="mt-3 text-sm leading-relaxed text-slate-600">
            Akses dashboard untuk memantau sensor, memvalidasi alert, dan mengoordinasikan tindakan darurat dengan
            cepat.
          </p>

          <ul className="mt-6 space-y-3 text-sm text-slate-700">
            <li className="rounded-lg border border-blue-100 bg-sky-50/70 px-3 py-2">✅ Monitoring sensor 24/7</li>
            <li className="rounded-lg border border-blue-100 bg-sky-50/70 px-3 py-2">✅ Peringatan warna level risiko</li>
            <li className="rounded-lg border border-blue-100 bg-sky-50/70 px-3 py-2">✅ Akses koordinasi tanggap darurat</li>
          </ul>
        </section>

        <Card className="border-blue-100 bg-white/95 p-6 shadow-xl md:p-7">
          <div className="mb-4">
            <Link
              href="/"
              className="inline-flex items-center gap-2 rounded-lg border border-slate-200 bg-white px-3 py-2 text-xs font-semibold text-slate-700 transition-colors hover:bg-slate-50"
            >
              <span aria-hidden="true">←</span>
              <span>Kembali ke Landing Page</span>
            </Link>
          </div>

          <h2 className="text-2xl font-bold text-slate-900">Login</h2>
          <p className="mt-2 text-sm text-slate-600">Masuk ke akun kamu untuk mengakses layanan EWS.</p>

          <button
            type="button"
            onClick={onGoogleLogin}
            disabled={isSubmitting}
            className="mt-6 inline-flex w-full items-center justify-center gap-3 rounded-lg border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-700 transition-colors hover:bg-slate-50 disabled:opacity-50"
          >
            <svg viewBox="0 0 24 24" className="size-4" aria-hidden="true">
              <path fill="#EA4335" d="M12 10.2v3.9h5.5c-.2 1.2-1.4 3.5-5.5 3.5-3.3 0-6-2.7-6-6s2.7-6 6-6c1.9 0 3.2.8 3.9 1.5l2.7-2.6C16.9 2.9 14.7 2 12 2 6.5 2 2 6.5 2 12s4.5 10 10 10c5.8 0 9.6-4.1 9.6-9.8 0-.7-.1-1.3-.2-2H12z" />
            </svg>
            Login dengan Google
          </button>



          <div className="my-4 flex items-center gap-3">
            <span className="h-px flex-1 bg-slate-200" />
            <span className="text-xs font-medium uppercase tracking-wide text-slate-400">atau</span>
            <span className="h-px flex-1 bg-slate-200" />
          </div>

          <form className="space-y-4" onSubmit={onSubmit}>
            <div>
              <label htmlFor="email" className="mb-1 block text-sm font-medium text-slate-700">
                Email
              </label>
              <input
                id="email"
                type="email"
                value={email}
                onChange={(event) => setEmail(event.target.value)}
                className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm outline-none transition focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
                placeholder="nama@email.com"
                required
              />
            </div>

            <div>
              <label htmlFor="password" className="mb-1 block text-sm font-medium text-slate-700">
                Password
              </label>
              <input
                id="password"
                type="password"
                value={password}
                onChange={(event) => setPassword(event.target.value)}
                className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm outline-none transition focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
                placeholder="••••••••"
                required
              />
            </div>

            <Button type="submit" className="w-full bg-blue-600 hover:bg-blue-700" disabled={isSubmitting}>
              {isSubmitting ? "Memproses..." : "Masuk"}
            </Button>

            {error && <p className="text-sm font-medium text-rose-600 text-center">{error}</p>}
            {success && <p className="text-sm font-medium text-emerald-600 text-center">{success}</p>}
          </form>

          <p className="mt-5 text-center text-sm text-slate-600">
            Belum punya akun?{" "}
            <Link href="/register" className="font-semibold text-blue-700 hover:text-blue-800">
              Daftar sekarang
            </Link>
          </p>

          <div className="mt-6 border-t border-slate-100 pt-4 text-center">
            <span className="text-[10px] uppercase tracking-wider text-slate-400">Quick Login (Dev):</span>
            <div className="mt-2 flex flex-wrap justify-center gap-x-3 gap-y-2">
              <button
                type="button"
                onClick={() => void onQuickLogin("admin@ews.com", "Admin123!")}
                disabled={isSubmitting}
                className="text-[11px] text-slate-500 transition-colors hover:text-blue-600 hover:underline disabled:opacity-50"
              >
                Admin 1
              </button>
              <button
                type="button"
                onClick={() => void onQuickLogin("admin2@ews.com", "AdminOps123!")}
                disabled={isSubmitting}
                className="text-[11px] text-slate-500 transition-colors hover:text-blue-600 hover:underline disabled:opacity-50"
              >
                Admin 2
              </button>
              <button
                type="button"
                onClick={() => void onQuickLogin("user1@ews.com", "User12345!")}
                disabled={isSubmitting}
                className="text-[11px] text-slate-500 transition-colors hover:text-blue-600 hover:underline disabled:opacity-50"
              >
                User 1
              </button>
              <button
                type="button"
                onClick={() => void onQuickLogin("user2@ews.com", "User12345!")}
                disabled={isSubmitting}
                className="text-[11px] text-slate-500 transition-colors hover:text-blue-600 hover:underline disabled:opacity-50"
              >
                User 2
              </button>
              <button
                type="button"
                onClick={() => void onQuickLogin("user3@ews.com", "User12345!")}
                disabled={isSubmitting}
                className="text-[11px] text-slate-500 transition-colors hover:text-blue-600 hover:underline disabled:opacity-50"
              >
                User 3
              </button>
            </div>
          </div>
        </Card>
      </div>
    </main>
  );
}