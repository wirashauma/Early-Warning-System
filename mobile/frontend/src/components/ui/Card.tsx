import type { PropsWithChildren } from "react";
import { cn } from "@/lib/utils";

interface CardProps {
  className?: string;
}

export function Card({ children, className }: PropsWithChildren<CardProps>) {
  return (
    <div className={cn("rounded-xl border border-slate-200 bg-white p-5 shadow-sm", className)}>
      {children}
    </div>
  );
}
