"use client";

import { FormEvent, useState } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { useAuth } from "@/hooks/useAuth";

export default function AdminLoginPage() {
  const router = useRouter();
  const { login, dummyAccounts } = useAuth();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    if (!email || !password) return;
    const result = login(email, password);
    if (!result.ok) {
      setError(result.message);
      return;
    }

    setError(null);
    router.push("/admin/dashboard");
  };

  const fillDummyAccount = (quickEmail: string, quickPassword: string) => {
    setEmail(quickEmail);
    setPassword(quickPassword);
    setError(null);
  };

  return (
    <Card>
      <h1 className="text-2xl font-bold text-slate-900">Admin Login</h1>
      <p className="mb-6 mt-2 text-sm text-slate-600">Masuk untuk mengelola sensor, threshold, dan broadcast alert.</p>

      <div className="mb-4 rounded-lg border border-slate-200 bg-slate-50 p-3">
        <p className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-500">Isi Cepat Akun Dummy</p>
        <div className="flex flex-wrap gap-2">
          {dummyAccounts.map((account) => (
            <button
              key={account.email}
              type="button"
              onClick={() => fillDummyAccount(account.email, account.password)}
              className="rounded-full border border-slate-200 bg-white px-2.5 py-1 text-xs font-medium text-slate-600 hover:border-blue-200 hover:bg-blue-50 hover:text-blue-700"
            >
              {account.role} · {account.name}
            </button>
          ))}
        </div>
        <ul className="mt-2 space-y-1 text-xs text-slate-500">
          {dummyAccounts.map((account) => (
            <li key={`${account.email}-hint`}>
              {account.email} / {account.password}
            </li>
          ))}
        </ul>
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label htmlFor="email" className="mb-1 block text-sm font-medium text-slate-700">
            Email
          </label>
          <input
            id="email"
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
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
            onChange={(e) => setPassword(e.target.value)}
            className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm"
          />
        </div>

        <Button type="submit" className="w-full">
          Login
        </Button>
        {error && <p className="text-sm font-medium text-rose-600">{error}</p>}
      </form>
    </Card>
  );
}
