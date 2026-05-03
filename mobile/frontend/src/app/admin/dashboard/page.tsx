import { Card } from "@/components/ui/Card";
import { StatusIndicator } from "@/components/ui/StatusIndicator";
import { mockAlertHistory, mockSensors } from "@/constants";

export default function AdminDashboardPage() {
  const online = mockSensors.filter((sensor) => sensor.connectivity === "online").length;
  const offline = mockSensors.length - online;

  return (
    <main className="space-y-4">
      <h1 className="text-2xl font-bold text-slate-900">Admin Overview Dashboard</h1>

      <div className="grid gap-4 md:grid-cols-3">
        <Card>
          <p className="text-sm text-slate-500">Sensor Aktif</p>
          <p className="mt-1 text-2xl font-bold text-emerald-600">{online}</p>
        </Card>
        <Card>
          <p className="text-sm text-slate-500">Sensor Offline</p>
          <p className="mt-1 text-2xl font-bold text-rose-600">{offline}</p>
        </Card>
        <Card>
          <p className="text-sm text-slate-500">Alert Terbaru</p>
          <p className="mt-1 text-sm font-semibold text-slate-800">{mockAlertHistory[0]?.title}</p>
        </Card>
      </div>

      <Card>
        <h2 className="mb-3 text-base font-semibold text-slate-900">Status Titik Pemantauan</h2>
        <div className="space-y-2">
          {mockSensors.map((sensor) => (
            <div key={sensor.id} className="flex items-center justify-between rounded-lg bg-slate-50 p-3">
              <div>
                <p className="text-sm font-semibold text-slate-800">{sensor.name}</p>
                <p className="text-xs text-slate-500">{sensor.riverName}</p>
              </div>
              <StatusIndicator status={sensor.status} />
            </div>
          ))}
        </div>
      </Card>
    </main>
  );
}
