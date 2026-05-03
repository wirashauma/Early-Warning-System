import type { PropsWithChildren } from "react";
import { cn } from "@/lib/utils";

interface BadgeProps {
  className?: string;
}

export function Badge({ children, className }: PropsWithChildren<BadgeProps>) {
  return (
    <span className={cn("inline-flex rounded-full px-2.5 py-1 text-xs font-semibold", className)}>
      {children}
    </span>
  );
}
