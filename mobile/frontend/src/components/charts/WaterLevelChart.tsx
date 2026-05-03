import type { WaterLevelPoint } from "@/types/water-level";

interface WaterLevelChartProps {
  points: WaterLevelPoint[];
}

export function WaterLevelChart({ points }: WaterLevelChartProps) {
  const max = Math.max(...points.map((p) => p.levelCm), 1);

  return (
    <div className="space-y-3">
      <h3 className="text-base font-semibold text-slate-800">Grafik Ketinggian Air</h3>
      <div className="grid grid-cols-10 gap-2">
        {points.slice(-10).map((point) => (
          <div key={point.timestamp} className="flex flex-col items-center gap-2">
            <div
              className="w-full rounded-md bg-blue-500"
              style={{ height: `${Math.max(12, (point.levelCm / max) * 120)}px` }}
              title={`${point.levelCm} cm`}
            />
            <span className="text-[10px] text-slate-500">{new Date(point.timestamp).getMinutes()}</span>
          </div>
        ))}
      </div>
      <p className="text-xs text-slate-500">* Visual ringkas untuk monitoring cepat real-time.</p>
    </div>
  );
}
