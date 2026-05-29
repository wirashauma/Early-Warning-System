import { cn } from "@/lib/utils";
import type { WaterStatus } from "@/types/water-level";

const statusConfig: Record<
  WaterStatus,
  {
    label: string;
    dotClass: string;
    bgClass: string;
    textClass: string;
    ringClass: string;
    pulse: boolean;
  }
> = {
  safe: {
    label: "Normal",
    dotClass: "bg-emerald-500",
    bgClass: "bg-emerald-50",
    textClass: "text-emerald-700",
    ringClass: "ring-emerald-200",
    pulse: false,
  },
  warning: {
    label: "Waspada",
    dotClass: "bg-amber-500",
    bgClass: "bg-amber-50",
    textClass: "text-amber-700",
    ringClass: "ring-amber-200",
    pulse: false,
  },
  alert: {
    label: "Siaga",
    dotClass: "bg-orange-500",
    bgClass: "bg-orange-50",
    textClass: "text-orange-700",
    ringClass: "ring-orange-200",
    pulse: true,
  },
  danger: {
    label: "Bahaya",
    dotClass: "bg-rose-500",
    bgClass: "bg-rose-50",
    textClass: "text-rose-700",
    ringClass: "ring-rose-200",
    pulse: true,
  },
};

interface StatusIndicatorProps {
  status: WaterStatus;
  size?: "sm" | "md";
}

export function StatusIndicator({ status, size = "sm" }: StatusIndicatorProps) {
  const config = statusConfig[status];
  const isMd = size === "md";

  return (
    <span
      className={cn(
        "inline-flex items-center gap-1.5 rounded-full ring-1 font-semibold",
        config.bgClass,
        config.textClass,
        config.ringClass,
        isMd ? "px-3 py-1.5 text-xs" : "px-2.5 py-1 text-[11px]",
      )}
    >
      {/* Dot with optional pulse */}
      <span className="relative inline-flex">
        {config.pulse && (
          <span
            className={cn(
              "absolute inset-0 inline-flex rounded-full opacity-60 animate-ping",
              config.dotClass,
            )}
          />
        )}
        <span
          className={cn(
            "relative inline-block rounded-full",
            config.dotClass,
            isMd ? "h-2.5 w-2.5" : "h-2 w-2",
          )}
        />
      </span>
      {config.label}
    </span>
  );
}
