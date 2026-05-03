import type { Sensor } from "@/types/sensor";
import { Card } from "@/components/ui/Card";
import { StatusIndicator } from "@/components/ui/StatusIndicator";

interface SensorMapProps {
  sensors: Sensor[];
}

export function SensorMap({ sensors }: SensorMapProps) {
  return (
    <div className="grid gap-4 md:grid-cols-2">
      {sensors.map((sensor) => (
        <Card key={sensor.id}>
          <div className="mb-3 flex items-center justify-between">
            <h3 className="font-semibold text-slate-900">{sensor.name}</h3>
            <StatusIndicator status={sensor.status} />
          </div>
          <p className="text-sm text-slate-600">{sensor.riverName}</p>
          <p className="mt-2 text-xs text-slate-500">
            Lokasi: {sensor.latitude.toFixed(4)}, {sensor.longitude.toFixed(4)}
          </p>
          <a
            href={`https://www.google.com/maps?q=${sensor.latitude},${sensor.longitude}`}
            target="_blank"
            rel="noreferrer"
            className="mt-3 inline-block text-sm font-semibold text-blue-600 hover:text-blue-700"
          >
            Lihat di Google Maps
          </a>
        </Card>
      ))}
    </div>
  );
}
