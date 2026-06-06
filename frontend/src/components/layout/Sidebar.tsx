"use client";

import Image from "next/image";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Activity, ChevronLeft, ChevronRight } from "lucide-react";
import { adminNavLinks } from "@/constants";
import { cn } from "@/lib/utils";

type NavIconName = "dashboard" | "sensors" | "thresholds" | "alerts" | "notifications" | "reports" | "users" | "contacts";

const iconByPath: Record<string, NavIconName> = {
  "/admin/dashboard": "dashboard",
  "/admin/sensors": "sensors",
  "/admin/thresholds": "thresholds",
  "/admin/alerts": "alerts",
  "/admin/notifications": "notifications",
  "/admin/reports": "reports",
  "/admin/users": "users",
  "/admin/emergency-contacts": "contacts",
};

function NavIcon({ name, className }: { name: NavIconName; className?: string }) {
  switch (name) {
    case "dashboard":
      return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" className={className} aria-hidden="true">
          <path strokeLinecap="round" strokeLinejoin="round" d="M3 12l9-8 9 8" />
          <path strokeLinecap="round" strokeLinejoin="round" d="M5 10.5V20h14v-9.5" />
        </svg>
      );
    case "sensors":
      return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" className={className} aria-hidden="true">
          <circle cx="12" cy="12" r="2.2" />
          <path strokeLinecap="round" d="M12 4v2.2M12 17.8V20M4 12h2.2M17.8 12H20M6.7 6.7l1.5 1.5M15.8 15.8l1.5 1.5M17.3 6.7l-1.5 1.5M8.2 15.8l-1.5 1.5" />
        </svg>
      );
    case "thresholds":
      return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" className={className} aria-hidden="true">
          <path strokeLinecap="round" d="M5 6h14M5 12h14M5 18h14" />
          <circle cx="9" cy="6" r="1.7" fill="currentColor" stroke="none" />
          <circle cx="15" cy="12" r="1.7" fill="currentColor" stroke="none" />
          <circle cx="11" cy="18" r="1.7" fill="currentColor" stroke="none" />
        </svg>
      );
    case "alerts":
      return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" className={className} aria-hidden="true">
          <path strokeLinecap="round" strokeLinejoin="round" d="M12 4a5 5 0 00-5 5v2.7c0 .8-.3 1.6-.8 2.2L5 15.5h14l-1.2-1.6a3.6 3.6 0 01-.8-2.2V9a5 5 0 00-5-5z" />
          <path strokeLinecap="round" d="M10 18a2 2 0 004 0" />
        </svg>
      );
    case "notifications":
      return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" className={className} aria-hidden="true">
          <rect x="3" y="5" width="18" height="14" rx="3" />
          <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 7l7.5 5.4L19.5 7" />
          <circle cx="18.2" cy="6.4" r="1.8" fill="currentColor" stroke="none" />
        </svg>
      );
    case "reports":
      return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" className={className} aria-hidden="true">
          <path strokeLinecap="round" d="M4 20h16" />
          <path strokeLinecap="round" strokeLinejoin="round" d="M7 17V9m5 8V6m5 11v-5" />
        </svg>
      );
    case "users":
      return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" className={className} aria-hidden="true">
          <circle cx="9" cy="9" r="3" />
          <path strokeLinecap="round" d="M3.8 18.5a5.2 5.2 0 0110.4 0" />
          <circle cx="17" cy="10" r="2.2" />
          <path strokeLinecap="round" d="M14.8 18.5a4 4 0 014 0" />
        </svg>
      );
    case "contacts":
      return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" className={className} aria-hidden="true">
          <path strokeLinecap="round" strokeLinejoin="round" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
        </svg>
      );
    default:
      return null;
  }
}

interface SidebarProps {
  collapsed: boolean;
  onToggle: () => void;
}

function CollapseIcon({ collapsed, className }: { collapsed: boolean; className?: string }) {
  return (
    collapsed ? <ChevronRight className={className} aria-hidden="true" /> : <ChevronLeft className={className} aria-hidden="true" />
  );
}

export function Sidebar({ collapsed, onToggle }: SidebarProps) {
  const pathname = usePathname();

  return (
    <aside
      className={cn(
        "sticky top-0 hidden h-screen shrink-0 overflow-hidden border-r border-slate-200 bg-white text-slate-600 shadow-xl shadow-slate-100/40 transition-all duration-300 lg:flex",
        collapsed ? "w-20 xl:w-24" : "w-64 xl:w-72",
      )}
    >
      <div className="relative flex h-full w-full flex-col px-3 py-4">
        <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_10%_0%,rgba(59,130,246,0.06),transparent_35%)]" />

        <div className="relative z-10 mb-4 border-b border-slate-100 pb-4 pt-1">
          {!collapsed ? (
            <div className="flex items-center gap-3 rounded-2xl border border-slate-100 bg-slate-50/80 px-3 py-3 shadow-sm shadow-slate-100/50 backdrop-blur-md">
              <div className="inline-flex h-11 w-11 items-center justify-center overflow-hidden rounded-xl bg-white border border-slate-200">
                <Image
                  src="/logo.png"
                  alt="EWS Flood Guard"
                  width={40}
                  height={40}
                  priority
                  className="h-10 w-10 object-contain"
                />
              </div>
              <div className="min-w-0">
                <p className="truncate text-[0.72rem] font-medium uppercase tracking-[0.18em] text-slate-500">Early Warning</p>
                <h2 className="truncate text-[1.2rem] font-bold leading-tight tracking-wide text-slate-900">Flood Guard</h2>
                <p className="truncate text-xs uppercase tracking-[0.18em] text-slate-400">Dashboard Admin</p>
              </div>
            </div>
          ) : (
            <div className="flex flex-col items-center justify-center gap-2.5 py-1">
              <div className="inline-flex h-11 w-11 items-center justify-center overflow-hidden rounded-xl border border-slate-200 bg-white p-1.5 shadow-sm">
                <Image
                  src="/logo.png"
                  alt="EWS Flood Guard"
                  width={36}
                  height={36}
                  className="h-full w-full object-contain"
                />
              </div>
              <div className="rounded-xl border border-slate-200 bg-slate-50 px-2.5 py-2 text-[10px] font-semibold uppercase tracking-[0.2em] leading-none text-slate-600">
                EWS
              </div>
            </div>
          )}
        </div>

        <div className="relative z-10 mb-3 px-2">
          {!collapsed ? (
            <div className="flex items-center gap-2">
              <span className="text-xs font-medium uppercase tracking-[0.18em] text-slate-500">Menu Admin</span>
              <span className="h-px flex-1 bg-linear-to-r from-slate-200 to-transparent" />
            </div>
          ) : (
            <span className="mx-auto block h-7 w-px bg-slate-200" />
          )}
        </div>

        <ul className={cn("relative z-10", collapsed ? "space-y-2" : "space-y-1") }>
          {adminNavLinks.map((item) => (
            <li key={item.href}>
              {(() => {
                const iconName = iconByPath[item.href] ?? "dashboard";
                const isActive = pathname === item.href;

                return (
                  <Link
                    href={item.href}
                    title={item.label}
                    aria-label={item.label}
                    className={cn(
                      "group relative mx-2 flex items-center gap-3 rounded-xl border border-transparent px-4 py-2.5 text-sm font-medium transition-all duration-200",
                      "text-slate-500 hover:bg-slate-50 hover:text-slate-900",
                      collapsed && "mx-auto h-11 w-11 justify-center rounded-xl px-0 py-0",
                      isActive && "bg-blue-600 text-white shadow-sm shadow-blue-500/20 hover:bg-blue-600 hover:text-white",
                    )}
                  >
                    <span
                      className={cn(
                        "absolute inset-y-2 left-1.5 w-1 rounded-full bg-transparent transition-colors",
                        isActive && "bg-white/90",
                        collapsed && "hidden",
                      )}
                    />
                    <NavIcon
                      name={iconName}
                      className={cn(
                        "h-[1.05rem] w-[1.05rem] shrink-0 transition-transform duration-200 group-hover:scale-110",
                        collapsed && "h-[1.15rem] w-[1.15rem]",
                        isActive ? "text-white" : "text-slate-400 group-hover:text-slate-700",
                      )}
                    />
                    {!collapsed && <span className="text-[0.95rem] font-medium">{item.label}</span>}
                    {!collapsed && (
                      <span
                        className={cn(
                          "ml-auto h-1.5 w-1.5 rounded-full bg-slate-200 transition-colors",
                          isActive && "bg-white/95",
                        )}
                      />
                    )}
                  </Link>
                );
              })()}
            </li>
          ))}
        </ul>

        <div className="relative z-10 mt-auto px-2 pb-2 pt-4">
          {!collapsed ? (
            <div className="mx-2 mb-4 rounded-2xl border border-slate-100 bg-slate-50/70 p-4">
              <div className="flex items-center gap-2.5 text-slate-900">
                <Activity className="h-4 w-4 text-blue-600" aria-hidden="true" />
                <p className="text-xs font-semibold tracking-wide text-slate-800">Monitoring banjir real-time</p>
              </div>
              <p className="mt-1.5 text-[11px] leading-5 text-slate-500">Status sistem dipantau 24/7 untuk respons cepat.</p>
            </div>
          ) : (
            <div className="mx-auto mb-4 mt-1 flex flex-col items-center gap-1.5">
              <div className="flex h-8.5 w-8.5 items-center justify-center rounded-xl border border-slate-200 bg-slate-50 text-slate-500">
                <Activity className="h-4 w-4" aria-hidden="true" />
              </div>
            </div>
          )}
        </div>

        <div className="relative z-10 px-2 pb-2">
          {!collapsed ? (
            <button
              type="button"
              onClick={onToggle}
              className="inline-flex w-full items-center justify-center gap-2 rounded-xl border border-slate-200 bg-slate-50 px-3 py-2.5 text-xs font-semibold text-slate-600 transition-all duration-200 hover:bg-slate-100 hover:text-slate-900"
            >
              <CollapseIcon collapsed={false} className="h-3.5 w-3.5" />
              <span>Ciutkan Sidebar</span>
            </button>
          ) : (
            <button
              type="button"
              onClick={onToggle}
              className="inline-flex h-10 w-10 items-center justify-center rounded-xl border border-slate-200 bg-slate-50 text-slate-500 transition-all duration-200 hover:bg-slate-100 hover:text-slate-900"
              aria-label="Buka sidebar"
              title="Buka sidebar"
            >
              <CollapseIcon collapsed className="h-4 w-4" />
            </button>
          )}
        </div>
      </div>
    </aside>
  );
}
