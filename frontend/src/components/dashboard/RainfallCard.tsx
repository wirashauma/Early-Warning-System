import { getRainfallCategory } from "@/lib/utils";

interface RainfallCardProps {
  rainfallMm: number;
}

const intensityConfig: Record<string, { barColor: string; iconColor: string; bgGlow: string }> = {
  ringan: { barColor: "bg-cyan-400", iconColor: "text-cyan-500", bgGlow: "bg-cyan-50" },
  sedang: { barColor: "bg-blue-500", iconColor: "text-blue-500", bgGlow: "bg-blue-50" },
  lebat: { barColor: "bg-indigo-500", iconColor: "text-indigo-500", bgGlow: "bg-indigo-50" },
  "sangat lebat": { barColor: "bg-violet-600", iconColor: "text-violet-600", bgGlow: "bg-violet-50" },
};

export function RainfallCard({ rainfallMm }: RainfallCardProps) {
  const category = getRainfallCategory(rainfallMm);
  const intensityKey = category.label.toLowerCase();
  const config = intensityConfig[intensityKey] ?? intensityConfig["ringan"];

  // Intensity percentage (max ~100mm/h for scale)
  const intensityPct = Math.min(100, Math.round((rainfallMm / 100) * 100));

  return (
    <div className="flex flex-col h-full justify-between">
      {/* Header */}
      <div className="flex items-start justify-between mb-4">
        <div>
          <h3 className="text-base font-bold text-slate-800">Curah Hujan Terkini</h3>
          <p className="text-xs text-slate-400 mt-0.5">Intensitas real-time</p>
        </div>
        <div className={`flex h-10 w-10 items-center justify-center rounded-xl ${config.bgGlow}`}>
          {/* Rain drop icon */}
          <svg
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            className={`h-5 w-5 ${config.iconColor}`}
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              d="M12 21.5c-3.04 0-5.5-2.24-5.5-5 0-3.08 3.63-7.78 4.82-9.26a.88.88 0 011.36 0C13.87 8.72 17.5 13.42 17.5 16.5c0 2.76-2.46 5-5.5 5z"
            />
          </svg>
        </div>
      </div>

      {/* Value */}
      <div className="mb-4">
        <div className="flex items-baseline gap-1.5">
          <span className="text-3xl font-black text-slate-900 transition-all duration-500">
            {rainfallMm}
          </span>
          <span className="text-sm font-medium text-slate-400">mm/jam</span>
        </div>
        <p className="text-sm font-semibold text-slate-500 mt-1">
          {category.label}
          <span className="font-normal text-slate-400 ml-1">— {category.detail}</span>
        </p>
      </div>

      {/* Intensity bar */}
      <div className="space-y-1.5">
        <div className="flex items-center justify-between text-[11px] font-medium text-slate-400">
          <span>Intensitas</span>
          <span>{intensityPct}%</span>
        </div>
        <div className="h-2 w-full rounded-full bg-slate-100 overflow-hidden">
          <div
            className={`h-full rounded-full transition-all duration-700 ease-out ${config.barColor}`}
            style={{ width: `${Math.max(2, intensityPct)}%` }}
          />
        </div>
        <div className="flex justify-between text-[10px] text-slate-300 font-medium">
          <span>Ringan</span>
          <span>Sedang</span>
          <span>Lebat</span>
          <span>Sgt. Lebat</span>
        </div>
      </div>
    </div>
  );
}
