function requireEnv(name: "NEXT_PUBLIC_API_URL" | "NEXT_PUBLIC_WS_URL") {
  const value = process.env[name]?.trim();

  if (!value) {
    // Graceful fallbacks for development / hot-reloads to prevent runtime crashes
    if (name === "NEXT_PUBLIC_API_URL") return "/api";
    if (name === "NEXT_PUBLIC_WS_URL") return "ws://127.0.0.1:4101";
    
    throw new Error(
      `[EWS] Missing required environment variable: ${name}. Configure it in frontend/.env.local before running the app.`,
    );
  }

  return value;
}

export const API_URL = requireEnv("NEXT_PUBLIC_API_URL");
export const WS_URL = requireEnv("NEXT_PUBLIC_WS_URL");
export const PRIMARY_SENSOR_ID = process.env.NEXT_PUBLIC_PRIMARY_SENSOR_ID ?? "";
export const FLOW_SENSOR_ID = process.env.NEXT_PUBLIC_FLOW_SENSOR_ID ?? "";

export const statusColor: Record<"safe" | "warning" | "alert" | "danger", string> = {
  safe: "bg-emerald-100 text-emerald-700",
  warning: "bg-amber-100 text-amber-700",
  alert: "bg-orange-100 text-orange-700",
  danger: "bg-rose-100 text-rose-700",
};

export const publicNavLinks = [
  { href: "/", label: "Beranda" },
  { href: "/dashboard", label: "Dashboard" },
  { href: "/map", label: "Peta Sensor" },
  { href: "/emergency", label: "Kontak Darurat" },
  { href: "/education", label: "Edukasi" },
];

export const landingNavLinks = [
  { id: "home", href: "/#home", label: "Beranda" },
  { id: "realtime-dashboard", href: "/#realtime-dashboard", label: "Dashboard" },
  { id: "status-legend", href: "/#status-legend", label: "Status" },
  { id: "emergency-action", href: "/#emergency-action", label: "Darurat" },
  { id: "edukasi", href: "/#edukasi", label: "Edukasi & FAQ" },
  { id: "contact", href: "/#contact", label: "Kontak" },
];

export const adminNavLinks = [
  { href: "/admin/dashboard", label: "Dasbor" },
  { href: "/admin/sensors", label: "Sensor" },
  { href: "/admin/thresholds", label: "Ambang Batas" },
  { href: "/admin/alerts", label: "Peringatan" },
  { href: "/admin/notifications", label: "Notifikasi" },
  { href: "/admin/reports", label: "Laporan" },
  { href: "/admin/users", label: "Pengguna" },
  { href: "/admin/emergency-contacts", label: "Kontak Darurat" },
];
