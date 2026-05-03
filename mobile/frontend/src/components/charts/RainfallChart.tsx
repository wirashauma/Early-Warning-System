import type { WaterLevelPoint } from "@/types/water-level";

interface RainfallChartProps {
  points: WaterLevelPoint[];
}

export function RainfallChart({ points }: RainfallChartProps) {
  const max = Math.max(...points.map((p) => p.rainfallMm), 1);

  return (
    <div className="space-y-3">
      <h3 className="text-base font-semibold text-slate-800">Grafik Curah Hujan</h3>
      <div className="space-y-2">
        {points.slice(-6).map((point) => (
          <div key={point.timestamp} className="space-y-1">
            <div className="h-2 rounded-full bg-slate-200">
              <div
                className="h-2 rounded-full bg-cyan-500"
                style={{ width: `${Math.max(8, (point.rainfallMm / max) * 100)}%` }}
              />
            </div>
            <p className="text-xs text-slate-500">{point.rainfallMm} mm</p>
          </div>
        ))}
      </div>
    </div>
  );
}
