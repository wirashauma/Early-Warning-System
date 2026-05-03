"use client";

import { FormEvent, useState } from "react";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { StatusIndicator } from "@/components/ui/StatusIndicator";
import { mockAlertHistory } from "@/constants";

export default function AdminAlertsPage() {
  const [message, setMessage] = useState("Waspada kenaikan debit air di sektor hilir.");
  const [sent, setSent] = useState(false);

  const sendAlert = (event: FormEvent) => {
    event.preventDefault();
    setSent(true);
  };

  return (
    <main className="space-y-4">
      <h1 className="text-2xl font-bold text-slate-900">Broadcast Alert</h1>

      <Card>
        <form onSubmit={sendAlert} className="space-y-3">
          <label className="block text-sm font-medium text-slate-700">Pesan Alert</label>
          <textarea
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            className="h-24 w-full rounded-lg border border-slate-300 px-3 py-2"
          />

          <div className="flex flex-wrap gap-3 text-sm text-slate-700">
            <label className="inline-flex items-center gap-2"><input type="checkbox" defaultChecked /> Push</label>
            <label className="inline-flex items-center gap-2"><input type="checkbox" defaultChecked /> WhatsApp</label>
            <label className="inline-flex items-center gap-2"><input type="checkbox" /> Email</label>
          </div>

          <Button type="submit">Kirim Broadcast</Button>
          {sent && <p className="text-sm text-emerald-600">Pesan berhasil dikirim (mock).</p>}
        </form>
      </Card>

      <Card>
        <h2 className="mb-3 text-base font-semibold text-slate-900">Riwayat Broadcast</h2>
        <div className="space-y-3">
          {mockAlertHistory.map((alert) => (
            <div key={alert.id} className="rounded-lg bg-slate-50 p-3">
              <div className="mb-1 flex items-center justify-between">
                <p className="font-semibold text-slate-800">{alert.title}</p>
                <StatusIndicator status={alert.status} />
              </div>
              <p className="text-sm text-slate-600">{alert.message}</p>
            </div>
          ))}
        </div>
      </Card>
    </main>
  );
}
