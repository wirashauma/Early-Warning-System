import { Card } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { mockReportLogs } from "@/constants";

export default function AdminReportsPage() {
  return (
    <main className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-slate-900">Reports</h1>
        <div className="flex gap-2">
          <Button variant="secondary">Download PDF</Button>
          <Button>Download Excel</Button>
        </div>
      </div>

      <Card className="overflow-x-auto">
        <table className="w-full min-w-140 text-left text-sm">
          <thead>
            <tr className="border-b border-slate-200 text-slate-500">
              <th className="py-2">Tanggal</th>
              <th className="py-2">Tipe</th>
              <th className="py-2">Nilai</th>
              <th className="py-2">Sumber</th>
            </tr>
          </thead>
          <tbody>
            {mockReportLogs.map((log, index) => (
              <tr key={`${log.date}-${index}`} className="border-b border-slate-100">
                <td className="py-3">{log.date}</td>
                <td className="py-3">{log.type}</td>
                <td className="py-3">{log.value}</td>
                <td className="py-3">{log.sensor}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </Card>
    </main>
  );
}
