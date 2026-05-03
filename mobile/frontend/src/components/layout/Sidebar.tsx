"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { adminNavLinks } from "@/constants";
import { cn } from "@/lib/utils";

export function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="w-full rounded-xl border border-slate-200 bg-white p-4 md:w-64">
      <h2 className="mb-3 text-sm font-semibold uppercase tracking-wide text-slate-500">Admin Menu</h2>
      <ul className="space-y-1">
        {adminNavLinks.map((item) => (
          <li key={item.href}>
            <Link
              href={item.href}
              className={cn(
                "block rounded-lg px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-100",
                pathname === item.href && "bg-blue-50 text-blue-700",
              )}
            >
              {item.label}
            </Link>
          </li>
        ))}
      </ul>
    </aside>
  );
}
