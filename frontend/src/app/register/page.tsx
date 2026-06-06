"use client";

import { FormEvent, useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/Button";
import { useAuth } from "@/hooks/useAuth";
import api from "@/lib/api"; // Wajib ditambahkan untuk memanggil backend
import { User, Mail, Building, Lock, Eye, EyeOff, ArrowLeft, AlertCircle, CheckCircle2 } from "lucide-react";

const getRedirectPathByRole = (role: string) => 
  (role === "ADMIN" || role === "admin" ? "/admin/dashboard" : "/user/dashboard");

export default function RegisterPage() {
  const router = useRouter();
  const { login, loginWithGoogle } = useAuth();
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [institution, setInstitution] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  const onSubmit = async (event: FormEvent) => {
    event.preventDefault();
    setError(null);
    setMessage(null);

    if (!name || !email || !institution || !password || !confirmPassword) {
      setError("Mohon lengkapi semua field.");
      return;
    }

    if (password !== confirmPassword) {
      setError("Konfirmasi password belum sama.");
      return;
    }

    if (password.length < 8) {
      setError("Password minimal 8 karakter.");
      return;
    }

    setIsSubmitting(true);

    try {
      // Mengirim request ke backend (institution tidak dikirim karena belum ada di DB)
      await api.post("/auth/register", {
        name,
        email,
        password,
        institution,
      });

      setMessage("Pendaftaran berhasil! Mengalihkan ke dashboard...");

      // Auto-login setelah registrasi
      setTimeout(async () => {
        const result = await login(email, password);
        if (result.ok && result.user) {
          router.push(getRedirectPathByRole(result.user.role));
        } else {
          // Jika auto-login gagal, arahkan ke login page
          router.push("/login");
        }
      }, 1000);
    } catch (err: unknown) {
      // Menangkap pesan error dari backend (misal: "Email sudah terdaftar")
      const errorMessage =
        err instanceof Error ? err.message : "Terjadi kesalahan saat mendaftar.";
      setError(errorMessage);
    } finally {
      setIsSubmitting(false);
    }
  };

  const onGoogleRegister = async () => {
    setError(null);
    setMessage(null);
    setIsSubmitting(true);

    const result = await loginWithGoogle();

    if (!result.ok) {
      setError(result.message);
      setIsSubmitting(false);
      return;
    }

    setMessage("Pendaftaran/Login Google berhasil! Mengalihkan ke dashboard...");
    setTimeout(() => {
      if (result.user) {
        router.push(getRedirectPathByRole(result.user.role));
      }
    }, 700);
  };

  return (
    <main className="relative flex min-h-screen items-center justify-center overflow-x-hidden bg-blue-50/40 px-4 py-8 sm:px-6 lg:px-8">
      <div className="absolute inset-0">
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_top_right,rgba(59,130,246,0.18),transparent_40%)]" />
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_bottom_left,rgba(99,102,241,0.14),transparent_42%)]" />
        <div className="absolute inset-0 bg-[linear-gradient(180deg,rgba(248,250,252,0.96),rgba(239,246,255,0.92))]" />
      </div>

      <div className="relative w-full max-w-md md:max-w-4xl lg:max-w-5xl overflow-hidden rounded-2xl bg-white shadow-2xl ring-1 ring-slate-200/70">
        <div className="flex flex-col md:flex-row">
          {/* Side Brand Banner - hidden on mobile/portrait-tablet */}
          <section className="relative hidden md:flex md:w-[38%] lg:w-[32%] flex-col justify-between bg-linear-to-br from-blue-600 via-blue-700 to-indigo-900 px-6 py-8 text-white sm:px-7 md:px-8 md:py-10">
            <div className="absolute inset-0">
              <div className="absolute inset-0 bg-[radial-gradient(circle_at_top_right,rgba(255,255,255,0.18),transparent_35%)]" />
              <div className="absolute inset-0 bg-[radial-gradient(circle_at_bottom_left,rgba(125,211,252,0.16),transparent_40%)]" />
            </div>

            <div className="relative z-10 flex h-full flex-col justify-between">
              <div>
                <Image src="/logo.png" alt="EWS Logo" width={120} height={40} className="mb-6 h-auto w-24 sm:w-28" />

                <div className="max-w-sm">
                  <p className="inline-flex rounded-full border border-white/20 bg-white/10 px-3 py-1 text-[10px] font-semibold uppercase tracking-[0.18em] text-blue-50/90 backdrop-blur-sm">
                    Daftar Akun EWS
                  </p>
                  <h1 className="mt-4 text-xl font-bold leading-tight text-white lg:text-2xl">
                    Buat Akun Baru untuk Monitoring Banjir
                  </h1>
                  <p className="mt-3 text-xs leading-5 text-blue-100">
                    Daftarkan akun admin atau user untuk mengelola sensor dan memantau peringatan darurat.
                  </p>
                </div>
              </div>

              <ul className="mt-8 space-y-2.5 text-xs text-blue-50">
                {[
                  "Aktivasi akun cepat",
                  "Akses dashboard real-time",
                ].map((item) => (
                  <li
                    key={item}
                    className="flex items-center gap-2.5 rounded-xl border border-white/15 bg-white/10 px-3.5 py-2.5 backdrop-blur-sm"
                  >
                    <span className="inline-flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-white/15 text-white shadow-sm">
                      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" className="h-3.5 w-3.5" aria-hidden="true">
                        <path strokeLinecap="round" strokeLinejoin="round" d="M20 6L9 17l-5-5" />
                      </svg>
                    </span>
                    <span className="font-medium text-white/95">{item}</span>
                  </li>
                ))}
              </ul>
            </div>
          </section>

          {/* Form Section */}
          <section className="flex-1 bg-white px-6 py-8 sm:px-10 md:px-12 md:py-10 lg:px-16 max-h-[85vh] md:max-h-none overflow-y-auto">
            <div className="mx-auto flex h-full w-full max-w-xl flex-col justify-center">
              
              {/* Back Button */}
              <div className="mb-6">
                <Link
                  href="/"
                  className="inline-flex items-center gap-2 rounded-lg border border-slate-200 bg-slate-50/50 px-3 py-1.5 text-xs font-semibold text-slate-600 transition-all hover:bg-white hover:text-slate-800 hover:shadow-xs"
                >
                  <ArrowLeft className="h-3.5 w-3.5" />
                  <span>Kembali</span>
                </Link>
              </div>

              {/* Mobile Brand Header (only visible on mobile/portrait-tablet) */}
              <div className="flex flex-col items-center mb-6 text-center md:hidden">
                <div className="mb-2 flex h-11 w-11 items-center justify-center rounded-xl bg-blue-600 shadow-md shadow-blue-500/20">
                  <Image src="/logo.png" alt="EWS Logo" width={32} height={32} className="h-auto w-6.5 object-contain" />
                </div>
                <span className="inline-flex rounded-full bg-blue-50 px-2 py-0.5 text-[9px] font-bold uppercase tracking-wider text-blue-600">
                  Daftar Akun EWS
                </span>
                <h1 className="mt-2 text-xl font-bold tracking-tight text-slate-900">
                  Daftar Akun Baru
                </h1>
                <p className="mt-1 text-xs text-slate-500">
                  Lengkapi formulir di bawah untuk bergabung.
                </p>
              </div>

              {/* Desktop Header */}
              <div className="hidden md:block">
                <h2 className="text-2xl font-bold tracking-tight text-slate-900 lg:text-3xl">Register</h2>
                <p className="mt-1.5 text-sm text-slate-500">Buat akun baru untuk menggunakan layanan EWS.</p>
              </div>

              <button
                type="button"
                onClick={onGoogleRegister}
                disabled={isSubmitting}
                className="mt-6 inline-flex w-full items-center justify-center gap-2.5 rounded-lg border border-slate-200 bg-white px-4 py-2.5 text-sm font-semibold text-slate-700 shadow-2xs transition-all hover:bg-slate-50 hover:border-slate-300 active:scale-[0.995] disabled:cursor-not-allowed disabled:opacity-50"
              >
                <svg viewBox="0 0 24 24" aria-hidden="true" className="h-4.5 w-4.5 shrink-0">
                  <path fill="#4285F4" d="M21.805 10.023H12v3.95h5.62c-.48 2.33-2.43 4.01-5.62 4.01a6.04 6.04 0 1 1 0-12.08c1.74 0 3.31.62 4.55 1.83l2.95-2.95A10.01 10.01 0 0 0 12 2C6.48 2 2 6.48 2 12s4.48 10 10 10c5.38 0 9.92-3.89 9.92-10 0-.67-.07-1.21-.12-1.98Z" />
                  <path fill="#34A853" d="M3.27 7.59 6.7 10.1A5.99 5.99 0 0 1 12 7.92c1.74 0 3.31.62 4.55 1.83l2.95-2.95A10.01 10.01 0 0 0 12 2a9.98 9.98 0 0 0-8.73 5.59Z" />
                  <path fill="#FBBC05" d="M12 22c2.68 0 5.14-.97 7.03-2.58l-3.25-2.67c-1.16.78-2.66 1.24-3.78 1.24-3.18 0-5.88-2.11-6.85-4.97l-3.47 2.67A9.99 9.99 0 0 0 12 22Z" />
                  <path fill="#EA4335" d="M21.805 10.023H12v3.95h5.62c-.56 2.74-2.8 4.01-5.62 4.01-2.22 0-4.1-.93-5.06-2.63l-3.47 2.67C5.05 20.55 8.22 22 12 22c5.38 0 9.92-3.89 9.92-10 0-.67-.07-1.21-.12-1.98Z" />
                </svg>
                <span>Daftar dengan Google</span>
              </button>

              <div className="my-5 flex items-center gap-3">
                <span className="h-px flex-1 bg-slate-100" />
                <span className="text-[10px] font-bold uppercase tracking-widest text-slate-400">ATAU</span>
                <span className="h-px flex-1 bg-slate-100" />
              </div>

              <form className="space-y-4" onSubmit={onSubmit}>
                <div>
                  <label htmlFor="name" className="mb-1.5 block text-xs font-bold uppercase tracking-wider text-slate-600">
                    Nama Lengkap
                  </label>
                  <div className="relative">
                    <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3.5 text-slate-400">
                      <User className="h-[18px] w-[18px]" />
                    </div>
                    <input
                      id="name"
                      type="text"
                      value={name}
                      onChange={(event) => setName(event.target.value)}
                      className="w-full rounded-lg border border-slate-200 bg-white py-2.5 pl-10 pr-4 text-sm text-slate-900 outline-none transition-all placeholder:text-slate-400 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/15"
                      placeholder="Nama lengkap"
                      required
                    />
                  </div>
                </div>

                <div>
                  <label htmlFor="institution" className="mb-1.5 block text-xs font-bold uppercase tracking-wider text-slate-600">
                    Instansi / Organisasi
                  </label>
                  <div className="relative">
                    <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3.5 text-slate-400">
                      <Building className="h-[18px] w-[18px]" />
                    </div>
                    <input
                      id="institution"
                      type="text"
                      value={institution}
                      onChange={(event) => setInstitution(event.target.value)}
                      className="w-full rounded-lg border border-slate-200 bg-white py-2.5 pl-10 pr-4 text-sm text-slate-900 outline-none transition-all placeholder:text-slate-400 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/15"
                      placeholder="Contoh: BPBD Padang"
                      required
                    />
                  </div>
                </div>

                <div>
                  <label htmlFor="email" className="mb-1.5 block text-xs font-bold uppercase tracking-wider text-slate-600">
                    Email
                  </label>
                  <div className="relative">
                    <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3.5 text-slate-400">
                      <Mail className="h-[18px] w-[18px]" />
                    </div>
                    <input
                      id="email"
                      type="email"
                      value={email}
                      onChange={(event) => setEmail(event.target.value)}
                      className="w-full rounded-lg border border-slate-200 bg-white py-2.5 pl-10 pr-4 text-sm text-slate-900 outline-none transition-all placeholder:text-slate-400 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/15"
                      placeholder="nama@email.com"
                      required
                    />
                  </div>
                </div>

                <div>
                  <label htmlFor="password" className="mb-1.5 block text-xs font-bold uppercase tracking-wider text-slate-600">
                    Password
                  </label>
                  <div className="relative">
                    <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3.5 text-slate-400">
                      <Lock className="h-[18px] w-[18px]" />
                    </div>
                    <input
                      id="password"
                      type={showPassword ? "text" : "password"}
                      value={password}
                      onChange={(event) => setPassword(event.target.value)}
                      className="w-full rounded-lg border border-slate-200 bg-white py-2.5 pl-10 pr-10 text-sm text-slate-900 outline-none transition-all placeholder:text-slate-400 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/15"
                      placeholder="Minimal 8 karakter"
                      required
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword(!showPassword)}
                      className="absolute inset-y-0 right-0 flex items-center pr-3 text-slate-400 transition-colors hover:text-slate-600 focus:outline-none"
                    >
                      {showPassword ? (
                        <EyeOff className="h-[18px] w-[18px]" />
                      ) : (
                        <Eye className="h-[18px] w-[18px]" />
                      )}
                    </button>
                  </div>
                </div>

                <div>
                  <label htmlFor="confirmPassword" className="mb-1.5 block text-xs font-bold uppercase tracking-wider text-slate-600">
                    Konfirmasi Password
                  </label>
                  <div className="relative">
                    <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3.5 text-slate-400">
                      <Lock className="h-[18px] w-[18px]" />
                    </div>
                    <input
                      id="confirmPassword"
                      type={showConfirmPassword ? "text" : "password"}
                      value={confirmPassword}
                      onChange={(event) => setConfirmPassword(event.target.value)}
                      className="w-full rounded-lg border border-slate-200 bg-white py-2.5 pl-10 pr-10 text-sm text-slate-900 outline-none transition-all placeholder:text-slate-400 focus:border-blue-500 focus:ring-2 focus:ring-blue-500/15"
                      placeholder="Ulangi password"
                      required
                    />
                    <button
                      type="button"
                      onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                      className="absolute inset-y-0 right-0 flex items-center pr-3 text-slate-400 transition-colors hover:text-slate-600 focus:outline-none"
                    >
                      {showConfirmPassword ? (
                        <EyeOff className="h-[18px] w-[18px]" />
                      ) : (
                        <Eye className="h-[18px] w-[18px]" />
                      )}
                    </button>
                  </div>
                </div>

                <Button
                  type="submit"
                  className="w-full h-10.5 rounded-lg bg-blue-600 text-sm font-semibold text-white shadow-sm transition-all hover:bg-blue-700 active:scale-[0.99] disabled:cursor-not-allowed disabled:opacity-50 flex items-center justify-center"
                  disabled={isSubmitting}
                >
                  {isSubmitting ? "Memproses..." : "Daftar"}
                </Button>

                {error && (
                  <div className="flex items-start gap-2.5 rounded-lg border border-rose-100 bg-rose-50/80 p-3 text-xs text-rose-700">
                    <AlertCircle className="mt-0.5 h-4 w-4 shrink-0 text-rose-600" />
                    <span className="font-semibold">{error}</span>
                  </div>
                )}
                {message && (
                  <div className="flex items-start gap-2.5 rounded-lg border border-emerald-100 bg-emerald-50/80 p-3 text-xs text-emerald-700">
                    <CheckCircle2 className="mt-0.5 h-4 w-4 shrink-0 text-emerald-600" />
                    <span className="font-semibold">{message}</span>
                  </div>
                )}
              </form>

              <p className="mt-5 text-center text-sm text-slate-500">
                Sudah punya akun?{" "}
                <Link href="/login" className="font-semibold text-blue-600 transition-colors hover:text-blue-700">
                  Login di sini
                </Link>
              </p>
            </div>
          </section>
        </div>
      </div>
    </main>
  );
}