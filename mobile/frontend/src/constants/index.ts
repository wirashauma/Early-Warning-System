import type { Sensor } from "@/types/sensor";
import type { AlertMessage } from "@/types/alert";
import type { AppUser } from "@/types/user";

export const API_URL =
  process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:3001/api";
export const WS_URL = process.env.NEXT_PUBLIC_WS_URL ?? "ws://localhost:3001";

export const statusColor: Record<"safe" | "alert" | "danger", string> = {
  safe: "bg-emerald-100 text-emerald-700",
  alert: "bg-amber-100 text-amber-700",
  danger: "bg-rose-100 text-rose-700",
};

export const publicNavLinks = [
  { href: "/", label: "Beranda" },
  { href: "/dashboard", label: "Dashboard" },
  { href: "/map", label: "Peta Sensor" },
  { href: "/emergency", label: "Kontak Darurat" },
  { href: "/education", label: "Edukasi" },
];

export const adminNavLinks = [
  { href: "/admin/dashboard", label: "Dashboard" },
  { href: "/admin/sensors", label: "Sensors" },
  { href: "/admin/thresholds", label: "Thresholds" },
  { href: "/admin/alerts", label: "Alerts" },
  { href: "/admin/reports", label: "Reports" },
  { href: "/admin/users", label: "Users" },
];

export const emergencyContacts = [
  { name: "BPBD Kota", phone: "117" },
  { name: "Basarnas", phone: "115" },
  { name: "Ambulans", phone: "118" },
];

export const mockSensors: Sensor[] = [
  {
    id: "SEN-01",
    name: "Sensor Hulu",
    riverName: "Sungai Ciliwung",
    latitude: -6.1813,
    longitude: 106.8264,
    connectivity: "online",
    batteryPercent: 87,
    lastLevelCm: 120,
    status: "safe",
    updatedAt: new Date().toISOString(),
  },
  {
    id: "SEN-02",
    name: "Sensor Tengah",
    riverName: "Sungai Ciliwung",
    latitude: -6.2088,
    longitude: 106.8456,
    connectivity: "online",
    batteryPercent: 63,
    lastLevelCm: 165,
    status: "alert",
    updatedAt: new Date().toISOString(),
  },
  {
    id: "SEN-03",
    name: "Sensor Hilir",
    riverName: "Sungai Ciliwung",
    latitude: -6.2332,
    longitude: 106.9004,
    connectivity: "offline",
    batteryPercent: 12,
    lastLevelCm: 220,
    status: "danger",
    updatedAt: new Date().toISOString(),
  },
];

export const mockAlertHistory: AlertMessage[] = [
  {
    id: "ALT-001",
    title: "Waspada Kenaikan Air",
    message: "Ketinggian air di titik tengah naik ke status SIAGA.",
    status: "alert",
    channels: ["push", "whatsapp"],
    sentAt: new Date().toISOString(),
  },
  {
    id: "ALT-002",
    title: "Status BAHAYA",
    message: "Segera evakuasi area bantaran sungai sektor hilir.",
    status: "danger",
    channels: ["push", "whatsapp", "email"],
    sentAt: new Date().toISOString(),
  },
];

export interface DummyAuthAccount {
  email: string;
  password: string;
  name: string;
  role: AppUser["role"];
}

export const dummyAuthAccounts: DummyAuthAccount[] = [
  {
    email: "admin@ews.local",
    password: "Admin123!",
    name: "Admin EWS",
    role: "admin",
  },
  {
    email: "operator@ews.local",
    password: "Operator123!",
    name: "Operator Lapangan",
    role: "operator",
  },
  {
    email: "supervisor@ews.local",
    password: "Supervisor123!",
    name: "Supervisor EWS",
    role: "admin",
  },
];

export const mockUsers: AppUser[] = [
  { id: "USR-01", name: "Petugas A", email: "petugas.a@ews.id", role: "operator" },
  { id: "USR-02", name: "Petugas B", email: "petugas.b@ews.id", role: "operator" },
  { id: "USR-03", name: "Supervisor", email: "supervisor@ews.id", role: "admin" },
  { id: "USR-04", name: "Komandan Posko", email: "komandan@ews.id", role: "admin" },
];

export const mockReportLogs = [
  { date: "2026-03-11", type: "Water Level", value: "142 cm", sensor: "Sensor Hulu" },
  { date: "2026-03-12", type: "Water Level", value: "175 cm", sensor: "Sensor Tengah" },
  { date: "2026-03-12", type: "Rainfall", value: "34 mm", sensor: "Sensor Tengah" },
  { date: "2026-03-13", type: "Alert", value: "Status Siaga", sensor: "Sektor Tengah" },
  { date: "2026-03-13", type: "Alert", value: "Status Bahaya", sensor: "Sektor Hilir" },
];
