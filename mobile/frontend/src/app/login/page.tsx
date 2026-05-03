"use client";

import { FormEvent, useState } from "react";
import Link from "next/link";
import { Card } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";

export default function LoginPage() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [submitted, setSubmitted] = useState(false);

  const onSubmit = (event: FormEvent) => {
    event.preventDefault();
    if (!email || !password) return;
    setSubmitted(true);
  };

  return (
    <main className="mx-auto w-full max-w-lg px-6 py-10">
      <Card className="border-blue-100">
        <h1 className="text-2xl font-bold text-slate-900">Login</h1>
        <p className="mt-2 text-sm text-slate-600">Masuk ke akun kamu untuk mengakses layanan EWS.</p>

        <form className="mt-6 space-y-4" onSubmit={onSubmit}>
          <div>
            <label htmlFor="email" className="mb-1 block text-sm font-medium text-slate-700">
              Email
            </label>
            <input
              id="email"
              type="email"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
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
              className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
              placeholder="••••••••"
              required
            />
          </div>

          <Button type="submit" className="w-full bg-blue-600 hover:bg-blue-700">
            Masuk
          </Button>

          {submitted && (
            <p className="text-sm text-emerald-600">
              Form login berhasil dikirim (mode demo). Integrasi backend auth bisa ditambahkan berikutnya.
            </p>
          )}
        </form>

        <p className="mt-4 text-sm text-slate-600">
          Belum punya akun?{" "}
          <Link href="/register" className="font-semibold text-blue-700 hover:text-blue-800">
            Daftar sekarang
          </Link>
        </p>
      </Card>
    </main>
  );
}
