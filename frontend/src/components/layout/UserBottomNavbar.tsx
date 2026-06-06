"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";
import { LayoutDashboard, Map, PhoneCall, BookOpen } from "lucide-react";

export function UserBottomNavbar() {
  const pathname = usePathname();

  const userNavLinks = [
    { href: "/user/dashboard", label: "Dashboard", icon: LayoutDashboard },
    { href: "/user/map", label: "Peta Sensor", icon: Map },
    { href: "/user/emergency", label: "Kontak Darurat", icon: PhoneCall },
    { href: "/user/education", label: "Panduan", icon: BookOpen },
  ];

  const isRouteActive = (href: string) => {
    return pathname === href || pathname.startsWith(`${href}/`);
  };

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-40 bg-white border-t border-slate-200/90 lg:hidden flex justify-around items-center px-2 py-2 h-16 shadow-[0_-4px_16px_rgba(15,23,42,0.06)] backdrop-blur-md">
      {userNavLinks.map((tab) => {
        const Icon = tab.icon;
        const isActive = isRouteActive(tab.href);

        return (
          <Link
            key={tab.href}
            href={tab.href}
            className={cn(
              "flex flex-col items-center justify-center flex-1 h-full rounded-xl transition-all duration-200 gap-1 text-[10px] font-semibold focus:outline-none",
              isActive ? "text-blue-600 font-bold" : "text-slate-500 hover:text-slate-800"
            )}
          >
            <Icon
              className={cn(
                "h-5 w-5 transition-transform duration-200",
                isActive ? "text-blue-600 scale-105" : "text-slate-500"
              )}
            />
            <span className="truncate max-w-[76px]">{tab.label}</span>
          </Link>
        );
      })}
    </nav>
  );
}
