import type { WaterStatus } from "@/types/water-level";

interface WaterLevelGaugeProps {
  levelCm: number;
  status: WaterStatus;
}

const STATUS_COLORS: Record<WaterStatus, { stroke: string; text: string; bg: string; label: string }> = {
  safe: { stroke: "#10b981", text: "text-emerald-600", bg: "bg-emerald-50", label: "Normal" },
  warning: { stroke: "#f59e0b", text: "text-amber-600", bg: "bg-amber-50", label: "Waspada" },
  alert: { stroke: "#f97316", text: "text-orange-600", bg: "bg-orange-50", label: "Siaga" },
  danger: { stroke: "#ef4444", text: "text-rose-600", bg: "bg-rose-50", label: "Bahaya" },
};

export function WaterLevelGauge({ levelCm, status }: WaterLevelGaugeProps) {
  const maxCm = 400;
  const normalized = Math.min(1, Math.max(0, levelCm / maxCm));
  const config = STATUS_COLORS[status];

  // SVG arc calculations for semicircle gauge
  const cx = 100;
  const cy = 100;
  const radius = 80;
  const startAngle = Math.PI; // 180° (left)
  const endAngle = 0; // 0° (right)
  const totalArc = Math.PI; // 180° sweep

  // Background arc path (full semicircle)
  const bgStartX = cx + radius * Math.cos(startAngle);
  const bgStartY = cy - radius * Math.sin(startAngle);
  const bgEndX = cx + radius * Math.cos(endAngle);
  const bgEndY = cy - radius * Math.sin(endAngle);
  const bgPath = `M ${bgStartX} ${bgStartY} A ${radius} ${radius} 0 0 1 ${bgEndX} ${bgEndY}`;

  // Value arc path (partial)
  const valueAngle = startAngle - normalized * totalArc;
  const valueEndX = cx + radius * Math.cos(valueAngle);
  const valueEndY = cy - radius * Math.sin(valueAngle);
  const largeArc = normalized > 0.5 ? 1 : 0;
  const valuePath =
    normalized > 0.005
      ? `M ${bgStartX} ${bgStartY} A ${radius} ${radius} 0 ${largeArc} 1 ${valueEndX} ${valueEndY}`
      : "";

  // Tick marks at 0%, 25%, 50%, 75%, 100%
  const ticks = [0, 0.25, 0.5, 0.75, 1].map((pct) => {
    const angle = startAngle - pct * totalArc;
    const innerR = radius - 8;
    const outerR = radius + 4;
    return {
      x1: cx + innerR * Math.cos(angle),
      y1: cy - innerR * Math.sin(angle),
      x2: cx + outerR * Math.cos(angle),
      y2: cy - outerR * Math.sin(angle),
      label: `${Math.round(pct * maxCm)}`,
      labelX: cx + (outerR + 11) * Math.cos(angle),
      labelY: cy - (outerR + 11) * Math.sin(angle),
    };
  });

  return (
    <div className="flex flex-col items-center">
      <p className="text-sm font-bold text-slate-700 mb-2">Water Level Gauge</p>
      <div className="relative w-full max-w-[220px]">
        <svg viewBox="0 20 200 110" className="w-full h-auto">
          {/* Background track */}
          <path
            d={bgPath}
            fill="none"
            stroke="#e2e8f0"
            strokeWidth="14"
            strokeLinecap="round"
          />
          {/* Value arc */}
          {valuePath && (
            <path
              d={valuePath}
              fill="none"
              stroke={config.stroke}
              strokeWidth="14"
              strokeLinecap="round"
              className="transition-all duration-700 ease-in-out"
              style={{
                filter: status === "danger" ? `drop-shadow(0 0 6px ${config.stroke}80)` : undefined,
              }}
            />
          )}
          {/* Tick marks */}
          {ticks.map((tick, i) => (
            <g key={i}>
              <line
                x1={tick.x1}
                y1={tick.y1}
                x2={tick.x2}
                y2={tick.y2}
                stroke="#94a3b8"
                strokeWidth="1.5"
              />
              <text
                x={tick.labelX}
                y={tick.labelY}
                textAnchor="middle"
                dominantBaseline="middle"
                className="text-[8px] fill-slate-400 font-medium"
              >
                {tick.label}
              </text>
            </g>
          ))}
        </svg>

        {/* Center value */}
        <div className="absolute inset-0 flex flex-col items-center justify-end pb-2">
          <span className={`text-3xl font-black ${config.text} transition-colors duration-500`}>
            {levelCm}
          </span>
          <span className="text-xs font-medium text-slate-400 -mt-0.5">cm</span>
        </div>
      </div>

      {/* Status label */}
      <div className={`mt-2 inline-flex items-center gap-1.5 rounded-full px-3 py-1 ${config.bg}`}>
        <span
          className="inline-block h-2 w-2 rounded-full"
          style={{ backgroundColor: config.stroke }}
        />
        <span className={`text-xs font-bold ${config.text}`}>{config.label}</span>
      </div>
    </div>
  );
}
