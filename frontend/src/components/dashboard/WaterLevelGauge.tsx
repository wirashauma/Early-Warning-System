import type { WaterStatus } from "@/types/water-level";

interface WaterLevelGaugeProps {
  levelCm: number;
  status: WaterStatus;
}

export function WaterLevelGauge({ levelCm, status }: WaterLevelGaugeProps) {
  const normalized = Math.min(100, Math.round((levelCm / 250) * 100));
  
  // Mapping warna sesuai dengan 4 level peringatan
  const colorClass =
    status === "danger" 
      ? "bg-rose-500" 
      : status === "alert" 
      ? "bg-orange-500" 
      : status === "warning" 
      ? "bg-amber-500" 
      : "bg-emerald-500";

  return (
    <div className="space-y-2">
      <p className="text-sm font-semibold text-slate-700">Water Level Gauge</p>
      <div className="relative h-48 w-20 rounded-full border border-slate-200 bg-slate-100 p-2">
        <div 
          className={`absolute bottom-2 left-2 right-2 rounded-full transition-all duration-500 ${colorClass} ${status === "danger" ? "animate-pulse" : ""}`} 
          style={{ height: `${Math.max(10, normalized)}%` }} 
        />
      </div>
      <p className="text-sm font-bold text-slate-900">{levelCm} cm</p>
    </div>
  );
}
