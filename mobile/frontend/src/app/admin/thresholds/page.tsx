"use client";

import { FormEvent, useState } from "react";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";

export default function AdminThresholdsPage() {
  const [safeMax, setSafeMax] = useState(140);
  const [alertMax, setAlertMax] = useState(190);
  const [saved, setSaved] = useState(false);

  const onSubmit = (event: FormEvent) => {
    event.preventDefault();
    setSaved(true);
  };

  return (
    <main className="space-y-4">
      <h1 className="text-2xl font-bold text-slate-900">Threshold Settings</h1>

      <Card>
        <form onSubmit={onSubmit} className="grid gap-4 md:grid-cols-3">
          <label className="text-sm text-slate-700">
            Safe Max (cm)
            <input
              type="number"
              value={safeMax}
              onChange={(e) => setSafeMax(Number(e.target.value))}
              className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
            />
          </label>
          <label className="text-sm text-slate-700">
            Alert Max (cm)
            <input
              type="number"
              value={alertMax}
              onChange={(e) => setAlertMax(Number(e.target.value))}
              className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
            />
          </label>
          <label className="text-sm text-slate-700">
            Danger Min (cm)
            <input type="number" value={alertMax + 1} readOnly className="mt-1 w-full rounded-lg border border-slate-200 bg-slate-100 px-3 py-2" />
          </label>

          <div className="md:col-span-3 flex items-center gap-3">
            <Button type="submit">Simpan Threshold</Button>
            {saved && <p className="text-sm text-emerald-600">Perubahan disimpan (mock).</p>}
          </div>
        </form>
      </Card>
    </main>
  );
}
