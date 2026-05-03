interface WaterLevelGaugeProps {
  levelCm: number;
}

export function WaterLevelGauge({ levelCm }: WaterLevelGaugeProps) {
  const normalized = Math.min(100, Math.round((levelCm / 250) * 100));

  return (
    <div className="space-y-2">
      <p className="text-sm font-semibold text-slate-700">Water Level Gauge</p>
      <div className="relative h-48 w-20 rounded-full border border-slate-200 bg-slate-100 p-2">
        <div className="absolute bottom-2 left-2 right-2 rounded-full bg-blue-500" style={{ height: `${normalized}%` }} />
      </div>
      <p className="text-sm text-slate-600">{levelCm} cm</p>
    </div>
  );
}
