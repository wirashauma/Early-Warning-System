import { Card } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { StatusIndicator } from "@/components/ui/StatusIndicator";
import { mockSensors } from "@/constants";

export default function AdminSensorsPage() {
  return (
    <main className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-slate-900">Sensor Management</h1>
        <Button>Tambah Sensor</Button>
      </div>

      <Card className="overflow-x-auto">
        <table className="w-full min-w-170 text-left text-sm">
          <thead>
            <tr className="border-b border-slate-200 text-slate-500">
              <th className="py-2">Nama</th>
              <th className="py-2">Konektivitas</th>
              <th className="py-2">Baterai</th>
              <th className="py-2">Ketinggian</th>
              <th className="py-2">Status</th>
              <th className="py-2">Aksi</th>
            </tr>
          </thead>
          <tbody>
            {mockSensors.map((sensor) => (
              <tr key={sensor.id} className="border-b border-slate-100">
                <td className="py-3 font-medium text-slate-800">{sensor.name}</td>
                <td className="py-3 text-slate-600">{sensor.connectivity}</td>
                <td className="py-3 text-slate-600">{sensor.batteryPercent}%</td>
                <td className="py-3 text-slate-600">{sensor.lastLevelCm} cm</td>
                <td className="py-3">
                  <StatusIndicator status={sensor.status} />
                </td>
                <td className="py-3">
                  <div className="flex gap-2">
                    <Button variant="secondary">Edit</Button>
                    <Button variant="danger">Hapus</Button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </Card>
    </main>
  );
}
