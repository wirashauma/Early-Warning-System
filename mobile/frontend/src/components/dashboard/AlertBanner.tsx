import { StatusIndicator } from "@/components/ui/StatusIndicator";
import type { WaterStatus } from "@/types/water-level";

interface AlertBannerProps {
  status: WaterStatus;
  message: string;
}

export function AlertBanner({ status, message }: AlertBannerProps) {
  return (
    <div className="flex flex-col gap-2 rounded-xl border border-slate-200 bg-slate-50 p-4 md:flex-row md:items-center md:justify-between">
      <p className="text-sm text-slate-700">{message}</p>
      <StatusIndicator status={status} />
    </div>
  );
}
