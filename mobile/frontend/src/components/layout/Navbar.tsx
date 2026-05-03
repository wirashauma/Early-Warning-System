"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { publicNavLinks } from "@/constants";
import { cn } from "@/lib/utils";

export function Navbar() {
  const pathname = usePathname();

  return (
    <header className="sticky top-0 z-40 border-b border-blue-100 bg-white/95 backdrop-blur">
      <nav className="mx-auto flex w-full max-w-6xl items-center justify-between px-6 py-4">
        <Link href="/" className="text-lg font-bold text-blue-700">
          EWS Flood Guard
        </Link>
        <ul className="flex flex-wrap items-center gap-1.5">
          {publicNavLinks.map((item) => (
            <li key={item.href}>
              <Link
                href={item.href}
                className={cn(
                  "rounded-md px-3 py-2 text-sm font-medium text-slate-600 transition-colors hover:bg-blue-50 hover:text-blue-700",
                  pathname === item.href && "bg-blue-50 text-blue-700",
                )}
              >
                {item.label}
              </Link>
            </li>
          ))}
          <li>
            <Link
              href="/login"
              className="rounded-full border border-blue-200 px-2.5 py-1 text-xs font-semibold text-blue-700 transition-colors hover:bg-blue-50"
            >
              Login
            </Link>
          </li>
        </ul>
      </nav>
    </header>
  );
}
