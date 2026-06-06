"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useState } from "react";
import { adminNavLinks } from "@/constants";
import { cn } from "@/lib/utils";
import { X, LogOut, Menu } from "lucide-react";

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

interface BottomNavbarProps {
  unreadCount: number;
  onLogoutClick: () => void;
  userName?: string;
}

export function BottomNavbar({ unreadCount, onLogoutClick, userName }: BottomNavbarProps) {
  const pathname = usePathname();
  const [isOpen, setIsOpen] = useState(false);

  const mainTabs = [
    { href: "/admin/dashboard", label: "Dasbor", icon: "dashboard" as NavIconName },
    { href: "/admin/sensors", label: "Sensor", icon: "sensors" as NavIconName },
    { href: "/admin/alerts", label: "Peringatan", icon: "alerts" as NavIconName },
    { href: "/admin/notifications", label: "Notifikasi", icon: "notifications" as NavIconName },
  ];

  const isMainTabActive = mainTabs.some((tab) => pathname === tab.href);
  const isMenuButtonActive = !isMainTabActive;

  return (
    <>
      {/* Fixed Bottom Tab Bar */}
      <nav className="fixed bottom-0 left-0 right-0 z-40 bg-[#0B1120] border-t border-slate-800 lg:hidden flex justify-around items-center px-1.5 py-1.5 h-16 shadow-2xl shadow-slate-950/60 backdrop-blur-md">
        {mainTabs.map((tab) => {
          const isActive = pathname === tab.href;
          return (
            <Link
              key={tab.href}
              href={tab.href}
              className={cn(
                "flex flex-col items-center justify-center flex-1 h-full rounded-xl transition-all duration-200 gap-1 text-[10px] font-semibold",
                isActive ? "text-blue-500 font-bold" : "text-slate-400 hover:text-slate-200"
              )}
            >
              <div className="relative flex items-center justify-center">
                {tab.href === "/admin/notifications" && unreadCount > 0 && (
                  <span className="absolute -right-1.5 -top-1.5 inline-flex h-4 min-w-4 items-center justify-center rounded-full bg-rose-500 px-1 text-[8px] font-bold text-white animate-pulse">
                    {unreadCount}
                  </span>
                )}
                <NavIcon
                  name={tab.icon}
                  className={cn("h-5 w-5 transition-transform duration-200", isActive ? "text-blue-500 scale-105" : "text-slate-400")}
                />
              </div>
              <span className="truncate max-w-[64px]">{tab.label}</span>
            </Link>
          );
        })}

        {/* Menu Toggle Button */}
        <button
          onClick={() => setIsOpen((prev) => !prev)}
          className={cn(
            "flex flex-col items-center justify-center flex-1 h-full rounded-xl transition-all duration-200 gap-1 text-[10px] font-semibold focus:outline-none",
            isMenuButtonActive || isOpen ? "text-blue-500 font-bold" : "text-slate-400 hover:text-slate-200"
          )}
        >
          <Menu className={cn("h-5 w-5 transition-transform duration-200", isMenuButtonActive || isOpen ? "text-blue-500 scale-105" : "text-slate-400")} />
          <span>Menu</span>
        </button>
      </nav>

      {/* Backdrop Overlay for Bottom Sheet */}
      {isOpen && (
        <div
          className="fixed inset-0 z-40 bg-slate-950/60 backdrop-blur-xs transition-opacity duration-300"
          onClick={() => setIsOpen(false)}
        />
      )}

      {/* Bottom Sheet Drawer */}
      <div
        className={cn(
          "fixed bottom-0 left-0 right-0 z-50 rounded-t-3xl bg-[#0B1120] border-t border-slate-800/80 px-5 pt-4 pb-8 transition-transform duration-300 ease-out shadow-2xl shadow-slate-950/80 transform lg:hidden",
          isOpen ? "translate-y-0" : "translate-y-full"
        )}
      >
        {/* Slide Indicator Drag Handle */}
        <div className="w-12 h-1 bg-slate-800 rounded-full mx-auto mb-4" />

        <div className="flex items-center justify-between mb-4">
          <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400">Navigasi Admin</h3>
          <button
            onClick={() => setIsOpen(false)}
            className="p-1 rounded-lg bg-slate-850 border border-slate-800 text-slate-400 hover:text-white"
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        {/* Grid navigation options */}
        <div className="grid grid-cols-4 gap-2 mb-5">
          {adminNavLinks.map((item) => {
            const iconName = iconByPath[item.href] ?? "dashboard";
            const isActive = pathname === item.href;

            return (
              <Link
                key={item.href}
                href={item.href}
                onClick={() => setIsOpen(false)}
                className={cn(
                  "flex flex-col items-center justify-center p-2.5 rounded-xl border transition-all duration-200 gap-1",
                  isActive
                    ? "bg-blue-600/10 border-blue-500/30 text-white font-semibold"
                    : "bg-slate-900/35 border-transparent text-slate-400 hover:bg-slate-800/30 hover:text-white"
                )}
              >
                <div className="relative">
                  {item.href === "/admin/notifications" && unreadCount > 0 && (
                    <span className="absolute -right-2 -top-1.5 inline-flex h-3.5 min-w-3.5 items-center justify-center rounded-full bg-rose-500 px-1 text-[7px] font-bold text-white">
                      {unreadCount}
                    </span>
                  )}
                  <NavIcon
                    name={iconName}
                    className={cn("h-4.5 w-4.5", isActive ? "text-blue-500" : "text-slate-400")}
                  />
                </div>
                <span className="text-[9px] text-center truncate w-full">{item.label}</span>
              </Link>
            );
          })}
        </div>

        <div className="h-px bg-slate-800/60 mb-4" />

        {/* Profile Info and Logout */}
        <div className="flex items-center justify-between bg-slate-900/40 border border-slate-800/50 rounded-2xl p-3">
          <div className="flex items-center gap-2.5 min-w-0">
            <div className="inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-linear-to-br from-blue-500 to-cyan-500 text-xs font-bold text-white shadow-sm">
              {(userName ?? "A").slice(0, 1).toUpperCase()}
            </div>
            <div className="min-w-0">
              <p className="text-xs font-semibold text-slate-200 truncate">{userName}</p>
              <p className="text-[9px] text-slate-500 uppercase tracking-wider">Administrator</p>
            </div>
          </div>
          <button
            onClick={() => {
              setIsOpen(false);
              onLogoutClick();
            }}
            className="flex items-center gap-1.5 rounded-xl bg-rose-500/10 border border-rose-500/20 px-3.5 py-2 text-xs font-bold text-rose-400 hover:bg-rose-500/20 active:scale-[0.98] transition-all"
          >
            <LogOut className="h-3.5 w-3.5" />
            <span>Logout</span>
          </button>
        </div>
      </div>
    </>
  );
}
