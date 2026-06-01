"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { usePathname, useRouter } from "next/navigation";
import { landingNavLinks } from "@/constants";
import { ConfirmDialog } from "@/components/ui/ConfirmDialog";
import { useAuth } from "@/hooks/useAuth";
import { useUserNotifications } from "@/hooks/useUserNotifications";
import { cn } from "@/lib/utils";

interface NavbarItem {
  href: string;
  label: string;
  id?: string;
}

const userNavLinks: NavbarItem[] = [
  { href: "/user/dashboard", label: "Dashboard" },
  { href: "/user/map", label: "Peta Sensor" },
  { href: "/user/emergency", label: "Kontak Darurat" },
  { href: "/user/education", label: "Panduan" },
];

export function Navbar() {
  const router = useRouter();
  const pathname = usePathname();
  const { isAuthenticated, logout, user } = useAuth();
  const { notifications, unreadCount, markAsRead, markAllAsRead, reload } = useUserNotifications();
  
  const [activeSection, setActiveSection] = useState("home");
  const [isHeroMode, setIsHeroMode] = useState(false);
  const [profileOpen, setProfileOpen] = useState(false);
  const [notificationsOpen, setNotificationsOpen] = useState(false);
  const [logoutConfirmOpen, setLogoutConfirmOpen] = useState(false);
  const profileRef = useRef<HTMLDivElement | null>(null);
  const notificationsRef = useRef<HTMLLIElement | null>(null);
  
  const isHomePage = pathname === "/";
  const isUserRoute = pathname.startsWith("/user");
  
  // Perbaikan: Hanya mengecek isAuthenticated agar muncul untuk semua role yang login
  const isLoggedInUser = isAuthenticated && !!user;
  const useUserNavbar = isUserRoute || isLoggedInUser;

  const links = useMemo<NavbarItem[]>(() => (useUserNavbar ? userNavLinks : landingNavLinks), [useUserNavbar]);

  // Handle klik di luar area dropdown untuk menutupnya
  useEffect(() => {
    if (!profileOpen) return;

    const handleClickOutside = (event: MouseEvent) => {
      const target = event.target as Node;
      if (!profileRef.current?.contains(target)) {
        setProfileOpen(false);
      }
    };

    window.addEventListener("mousedown", handleClickOutside);
    return () => window.removeEventListener("mousedown", handleClickOutside);
  }, [profileOpen]);

  useEffect(() => {
    if (!notificationsOpen) return;

    const handleClickOutside = (event: MouseEvent) => {
      const target = event.target as Node;
      if (!notificationsRef.current?.contains(target)) {
        setNotificationsOpen(false);
      }
    };

    window.addEventListener("mousedown", handleClickOutside);
    return () => window.removeEventListener("mousedown", handleClickOutside);
  }, [notificationsOpen]);

  useEffect(() => {
    const handleUpdate = () => {
      void reload();
    };

    window.addEventListener("notificationsUpdated", handleUpdate);
    return () => window.removeEventListener("notificationsUpdated", handleUpdate);
  }, [reload]);

  // Efek transisi Navbar saat di Landing Page
  useEffect(() => {
    if (!isHomePage) return;

    const heroSection = document.getElementById("home");
    if (!heroSection) return;

    const updateHeroMode = () => {
      const heroBottom = heroSection.getBoundingClientRect().bottom;
      const navbarHeight = 76;
      setIsHeroMode(heroBottom > navbarHeight + 24);
    };

    const frameId = window.requestAnimationFrame(updateHeroMode);
    window.addEventListener("scroll", updateHeroMode, { passive: true });
    window.addEventListener("resize", updateHeroMode);

    return () => {
      window.cancelAnimationFrame(frameId);
      window.removeEventListener("scroll", updateHeroMode);
      window.removeEventListener("resize", updateHeroMode);
    };
  }, [isHomePage]);

  useEffect(() => {
    if (!isHomePage) return;

    const sectionIds = links.map((item) => item.id).filter((id): id is string => Boolean(id));
    const sections = sectionIds
      .map((id) => document.getElementById(id))
      .map((section, index) => ({ id: sectionIds[index], section }))
      .filter((entry): entry is { id: string; section: HTMLElement } => Boolean(entry.section));

    if (!sections.length) return;

    const syncFromHash = () => {
      const hash = window.location.hash.replace("#", "");
      if (hash && sectionIds.includes(hash)) {
        setActiveSection(hash);
      }
    };

    const updateActiveSection = () => {
      const viewportLine = Math.max(120, window.innerHeight * 0.38);
      let currentSection = sections[0]?.id ?? "home";

      for (const { id, section } of sections) {
        const rect = section.getBoundingClientRect();

        if (rect.top <= viewportLine) {
          currentSection = id;
        } else {
          break;
        }
      }

      setActiveSection(currentSection);
    };

    let frameId = 0;
    const scheduleUpdate = () => {
      window.cancelAnimationFrame(frameId);
      frameId = window.requestAnimationFrame(updateActiveSection);
    };

    scheduleUpdate();
    syncFromHash();

    window.addEventListener("scroll", scheduleUpdate, { passive: true });
    window.addEventListener("resize", scheduleUpdate);
    window.addEventListener("hashchange", syncFromHash);

    return () => {
      window.cancelAnimationFrame(frameId);
      window.removeEventListener("scroll", scheduleUpdate);
      window.removeEventListener("resize", scheduleUpdate);
      window.removeEventListener("hashchange", syncFromHash);
    };
  }, [isHomePage, links]);

  const isRouteActive = (href: string) => {
    if (href === "/") return pathname === "/";
    return pathname === href || pathname.startsWith(`${href}/`);
  };

  const handleLogout = async () => {
    setProfileOpen(false);
    setLogoutConfirmOpen(false);
    await logout();
    router.push("/login");
  };

  const navigateTo = (path: string) => {
    setProfileOpen(false);
    router.push(path);
  };

  // Mengambil inisial nama untuk Avatar
  const userInitial = user?.name ? user.name.charAt(0).toUpperCase() : "U";

  return (
    <header
      className={cn(
        "z-40 transition-colors duration-300",
        isHomePage ? "fixed inset-x-0 top-0" : "sticky top-0",
        isHomePage && isHeroMode
          ? "border-b border-transparent bg-white/8 backdrop-blur-sm"
          : "border-b border-blue-100 bg-white/95 shadow-sm backdrop-blur",
      )}
    >
      <nav className="mx-auto flex w-full max-w-6xl items-center justify-between px-6 py-4">
        <Link
          href="/"
          className={cn(
            "flex items-center gap-3 font-bold transition-colors",
            isHomePage && isHeroMode ? "text-white" : "text-blue-700",
          )}
        >
          <Image
            src="/logo.png"
            alt="EWS Flood Guard"
            width={36}
            height={36}
            priority
            className="h-9 w-9 shrink-0 rounded-full object-contain"
          />
          EWS Flood Guard
        </Link>
        <ul className="flex flex-wrap items-center gap-2 sm:gap-3">
          {links.map((item) => (
            <li key={item.href} className="hidden md:block">
              <Link
                href={item.href}
                className={cn(
                  "relative rounded-md px-3 py-2 text-sm font-medium transition-colors",
                  isHomePage && isHeroMode
                    ? "text-blue-50/95 hover:bg-white/15 hover:text-white"
                    : "text-slate-600 hover:bg-blue-50 hover:text-blue-700",
                  (
                    isHomePage
                      ? activeSection === item.id
                      : isRouteActive(item.href)
                  ) && (isHomePage && isHeroMode ? "bg-white/15 text-white" : "bg-blue-50 text-blue-700"),
                )}
              >
                {item.label}
                <span
                  className={cn(
                    "absolute inset-x-2 -bottom-0.5 h-0.5 rounded-full opacity-0 transition-opacity",
                    isHomePage && isHeroMode ? "bg-white" : "bg-blue-600",
                    (
                      isHomePage
                        ? activeSection === item.id
                        : isRouteActive(item.href)
                    ) && "opacity-100",
                  )}
                />
              </Link>
            </li>
          ))}

          {/* Ikon Notifikasi (Muncul jika user sudah login) */}
          {isLoggedInUser && (
            <li className="relative" ref={notificationsRef}>
              <button
                type="button"
                onClick={() => setNotificationsOpen((prev) => !prev)}
                className={cn(
                  "relative inline-flex h-9 w-9 items-center justify-center rounded-full border transition-colors ml-2",
                  notificationsOpen || isRouteActive("/user/notifications")
                    ? "border-blue-200 bg-blue-50 text-blue-700"
                    : "border-slate-200 bg-white text-slate-600 hover:bg-blue-50 hover:text-blue-700",
                )}
                aria-label="Buka notifikasi"
                title="Notifikasi"
              >
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" className="h-4 w-4">
                  <path strokeLinecap="round" strokeLinejoin="round" d="M15 17h5l-1.4-1.4A2 2 0 0118 14.2V11a6 6 0 10-12 0v3.2a2 2 0 01-.6 1.4L4 17h5" />
                  <path strokeLinecap="round" d="M10 19a2 2 0 004 0" />
                </svg>

                {unreadCount > 0 && (
                  <span className="absolute -top-1.5 -right-1.5 flex h-5 min-w-[20px] items-center justify-center rounded-full bg-rose-600 px-1 text-[10px] font-bold text-white shadow-sm ring-2 ring-white">
                    {unreadCount}
                    <span className="absolute inset-0 rounded-full bg-rose-600/35 animate-ping opacity-75 pointer-events-none" />
                  </span>
                )}
              </button>

              {notificationsOpen && (
                <div className="absolute right-0 top-12 z-50 w-80 overflow-hidden rounded-xl border border-slate-200 bg-white shadow-xl animate-in fade-in slide-in-from-top-2">
                  <div className="flex items-center justify-between border-b border-slate-100 bg-slate-50 px-4 py-3">
                    <div>
                      <h3 className="text-sm font-semibold text-slate-800">Notifikasi</h3>
                      <p className="text-[10px] text-slate-500">{unreadCount} belum dibaca</p>
                    </div>
                    {unreadCount > 0 && (
                      <button
                        type="button"
                        onClick={async () => {
                          await markAllAsRead();
                        }}
                        className="text-xs font-semibold text-blue-600 hover:text-blue-700 transition"
                      >
                        Tandai semua dibaca
                      </button>
                    )}
                  </div>

                  <div className="max-h-[300px] overflow-y-auto divide-y divide-slate-100">
                    {notifications.length === 0 ? (
                      <div className="px-4 py-8 text-center text-xs text-slate-500">
                        Belum ada notifikasi baru.
                      </div>
                    ) : (
                      notifications.slice(0, 5).map((item) => (
                        <div
                          key={item.id}
                          onClick={async () => {
                            if (!item.isRead) {
                              await markAsRead(item.id);
                            }
                            setNotificationsOpen(false);
                            router.push(`/user/notifications/${item.id}`);
                          }}
                          className={cn(
                            "group flex flex-col gap-1 p-3 text-left text-xs cursor-pointer transition hover:bg-slate-50",
                            item.isRead ? "bg-white" : "bg-blue-50/20"
                          )}
                        >
                          <div className="flex items-center justify-between gap-1">
                            <span className="truncate font-semibold text-slate-800 group-hover:text-blue-700">
                              {item.title}
                            </span>
                            <span
                              className={cn(
                                "shrink-0 rounded px-1.5 py-0.5 text-[9px] font-bold",
                                item.riskLevel === "red"
                                  ? "bg-rose-100 text-rose-700"
                                  : item.riskLevel === "orange"
                                  ? "bg-orange-100 text-orange-700"
                                  : "bg-amber-100 text-amber-700"
                              )}
                            >
                              {item.riskLevel === "red" ? "Bahaya" : item.riskLevel === "orange" ? "Waspada" : "Aman"}
                            </span>
                          </div>
                          <p className="line-clamp-2 text-slate-600 text-[11px] leading-relaxed">
                            {item.message}
                          </p>
                          <span className="text-[9px] text-slate-400 mt-1">
                            {new Date(item.createdAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })} • {item.sensorName}
                          </span>
                        </div>
                      ))
                    )}
                  </div>

                  <div className="border-t border-slate-100 p-2 bg-slate-50 text-center">
                    <button
                      type="button"
                      onClick={() => {
                        setNotificationsOpen(false);
                        router.push("/user/notifications");
                      }}
                      className="inline-flex w-full items-center justify-center rounded-lg py-2 text-xs font-bold text-blue-600 hover:bg-blue-100/50 hover:text-blue-700 transition"
                    >
                      Lihat Semua
                    </button>
                  </div>
                </div>
              )}
            </li>
          )}

          <li>
            {isLoggedInUser ? (
              <div className="relative" ref={profileRef}>
                {/* Tombol Profil (Avatar Lingkaran) */}
                <button
                  type="button"
                  onClick={() => setProfileOpen((prev) => !prev)}
                  className="inline-flex h-9 w-9 items-center justify-center rounded-full bg-blue-600 font-bold text-white shadow-sm ring-2 ring-white transition-all hover:bg-blue-700 focus:outline-none focus:ring-blue-300"
                  aria-label="Buka menu profil"
                >
                  {user?.avatar ? (
                    <span className="relative block h-full w-full overflow-hidden rounded-full">
                      {/* Avatar image now fills a circular, clipped wrapper so it cannot overflow or appear square. */}
                      <Image src={user.avatar} alt="Avatar pengguna" fill unoptimized className="object-cover" />
                    </span>
                  ) : (
                    userInitial
                  )}
                </button>

                {/* Dropdown Menu */}
                {profileOpen && (
                  <div className="absolute right-0 top-12 z-50 w-56 overflow-hidden rounded-xl border border-slate-200 bg-white shadow-xl animate-in fade-in slide-in-from-top-2">
                    {/* Header Dropdown (Nama & Email) */}
                    <div className="border-b border-slate-100 bg-slate-50 px-4 py-3">
                      <p className="truncate text-sm font-semibold text-slate-800">{user?.name}</p>
                      <p className="truncate text-xs font-medium text-slate-500">{user?.email}</p>
                    </div>

                    {/* Isi Dropdown */}
                    <div className="p-1.5">
                      <button
                        type="button"
                        onClick={() => navigateTo("/user/profile")}
                        className="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-left text-sm font-medium text-slate-700 hover:bg-slate-100"
                      >
                        Profile
                      </button>
                      <button
                        type="button"
                        onClick={() => navigateTo("/user/settings")}
                        className="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-left text-sm font-medium text-slate-700 hover:bg-slate-100"
                      >
                        Pengaturan
                      </button>
                      <button
                        type="button"
                        onClick={() => navigateTo("/user/faq")}
                        className="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-left text-sm font-medium text-slate-700 hover:bg-slate-100"
                      >
                        FAQ Bantuan
                      </button>
                    </div>

                    {/* Tombol Keluar */}
                    <div className="border-t border-slate-100 p-1.5">
                      <button
                        type="button"
                        onClick={() => {
                          setProfileOpen(false);
                          setLogoutConfirmOpen(true);
                        }}
                        className="flex w-full items-center gap-2 rounded-lg px-3 py-2 text-left text-sm font-bold text-rose-600 hover:bg-rose-50"
                      >
                        Keluar
                      </button>
                    </div>
                  </div>
                )}
              </div>
            ) : (
              // Tombol Login (Muncul jika user belum login)
              <Link
                href="/login"
                className={cn(
                  "rounded-full px-4 py-1.5 text-xs font-bold transition-colors ml-2",
                  isHomePage && isHeroMode
                    ? "bg-white text-blue-700 hover:bg-blue-50"
                    : "bg-blue-600 text-white hover:bg-blue-700",
                )}
              >
                Login
              </Link>
            )}
          </li>
        </ul>
      </nav>

      <ConfirmDialog
        open={logoutConfirmOpen}
        title="Keluar dari akun?"
        description="Anda akan keluar dari sesi saat ini dan perlu login kembali untuk mengakses fitur pengguna."
        confirmText="Ya, logout"
        cancelText="Tetap di sini"
        onCancel={() => setLogoutConfirmOpen(false)}
        onConfirm={() => {
          void handleLogout();
        }}
      />
    </header>
  );
}