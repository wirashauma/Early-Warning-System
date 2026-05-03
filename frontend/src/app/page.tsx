"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import Image from "next/image";
import { Card } from "@/components/ui/Card";
import { Reveal } from "@/components/ui/Reveal";
import { PublicRealtimeDashboardSection } from "@/components/landing/PublicRealtimeDashboardSection";
import { AuthRedirectWrapper } from "@/components/AuthRedirectWrapper";
import api from "@/lib/api";

// --- Tipe Data Database ---
interface EmergencyContact {
  id: string;
  name: string;
  phone: string;
  category: string;
  isActive: boolean; // Ditambahkan agar TypeScript mengenali properti ini saat di-filter
}

interface ActiveAlert {
  id: string;
  title: string;
  message: string;
  severity: "INFO" | "WARNING" | "ALERT" | "DANGER";
  targetArea: string | null;
}

// --- Konstanta Statis (Untuk Panduan Edukasi) ---
const statusLegend = [
  {
    color: "bg-emerald-500",
    title: "Hijau (Normal)",
    description: "Kondisi aman, ketinggian air di bawah ambang batas waspada.",
    threshold: "< 150 cm",
    action: "Aktivitas normal, tetap pantau dashboard setiap 30 menit.",
    icon: "✅",
  },
  {
    color: "bg-amber-500",
    title: "Kuning (Waspada)",
    description: "Ketinggian air meningkat, masyarakat diminta waspada dan bersiap.",
    threshold: "150 – 174 cm",
    action: "Siapkan tas darurat, dokumen penting, dan rute evakuasi keluarga.",
    icon: "⚠️",
  },
  {
    color: "bg-orange-500",
    title: "Oranye (Siaga)",
    description: "Ketinggian air mendekati level bahaya, evakuasi parsial atau kelompok rentan mungkin diperlukan.",
    threshold: "175 – 199 cm",
    action: "Amankan barang berharga ke tempat tinggi, pantau ketat arahan evakuasi dari petugas.",
    icon: "🔔",
  },
  {
    color: "bg-rose-500",
    title: "Merah (Bahaya / Evakuasi)",
    description: "Kondisi darurat, evakuasi segera diperlukan sesuai arahan petugas.",
    threshold: "≥ 200 cm",
    action: "Segera evakuasi ke titik aman terdekat dan ikuti arahan petugas.",
    icon: "🚨",
  },
];

const evacuationGuide = [
  "Pantau notifikasi resmi dan ikuti instruksi petugas saat status merah aktif.",
  "Matikan listrik utama rumah dan amankan dokumen penting ke tempat kedap air.",
  "Bawa tas siaga, bantu lansia/anak, lalu bergerak ke titik evakuasi terdekat.",
  "Tetap di jalur aman dan hindari menerobos arus banjir atau kabel listrik terbuka.",
];

const emergencyKit = [
  "Dokumen penting (KTP, KK, surat berharga)",
  "Obat pribadi, P3K, dan masker",
  "Air minum, makanan siap saji, perlengkapan bayi",
  "Senter, powerbank, peluit, dan baterai cadangan",
  "Pakaian ganti dan perlengkapan kebersihan dasar",
];

const faqs = [
  {
    q: "Bagaimana data sensor diperbarui?",
    a: "Data sensor dikirim berkala ke sistem dan ditampilkan hampir real-time pada dashboard publik.",
  },
  {
    q: "Apa peran admin dalam sistem EWS?",
    a: "Admin mengelola sensor, memvalidasi data/alert, dan memastikan informasi darurat dikirim tepat waktu.",
  },
  {
    q: "Apa yang harus dilakukan saat status Kuning atau Oranye?",
    a: "Siapkan dokumen penting, tas siaga, dan pantau terus pembaruan status dari dashboard maupun petugas.",
  },
  {
    q: "Apakah tombol darurat bisa langsung menelepon?",
    a: "Ya, tombol menggunakan fitur one-click call, terutama efektif pada perangkat mobile.",
  },
];

const photoItems = [
  {
    title: "Pemantauan Debit Sungai",
    caption: "Sensor lapangan mengirim data perubahan tinggi muka air secara berkala.",
    src: "https://images.unsplash.com/photo-1473448912268-2022ce9509d8?auto=format&fit=crop&w=1400&q=80",
  },
];

// Helper untuk metadata kategori darurat
const getEmergencyMeta = (category: string) => {
  switch (category) {
    case "BPBD":
      return { scope: "Koordinasi kebencanaan wilayah", response: "Target respons 5-10 menit" };
    case "SAR":
      return { scope: "Evakuasi & penyelamatan", response: "Target respons 10-20 menit" };
    case "AMBULANCE":
    case "HOSPITAL":
      return { scope: "Bantuan medis darurat", response: "Target respons 10-15 menit" };
    case "POLICE":
      return { scope: "Keamanan dan evakuasi", response: "Target respons 10-15 menit" };
    default:
      return { scope: "Respon darurat", response: "Secepat mungkin" };
  }
};

export default function Home() {
  const [contacts, setContacts] = useState<EmergencyContact[]>([]);
  const [activeAlerts, setActiveAlerts] = useState<ActiveAlert[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // Mengambil data dari database saat halaman pertama kali dimuat
  useEffect(() => {
    const fetchPublicData = async () => {
      try {
        // Fetch secara paralel agar lebih cepat
        const [contactsRes, alertsRes] = await Promise.all([
          api.get("/emergency-contacts"),
          api.get("/alerts/active").catch(() => ({ data: { data: [] } })) // Fallback jika endpoint alert belum ada
        ]);

        if (contactsRes.data?.data) {
          // Menghapus 'any' dan menggantinya dengan interface EmergencyContact
          setContacts(contactsRes.data.data.filter((c: EmergencyContact) => c.isActive));
        }

        if (alertsRes.data?.data) {
          setActiveAlerts(alertsRes.data.data);
        }
      } catch (error) {
        console.error("Gagal mengambil data publik:", error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchPublicData();
  }, []);

  return (
    <AuthRedirectWrapper>
      <main>
        {/* BANNER PERINGATAN DINI (Dinamic dari Database) */}
        {activeAlerts.length > 0 && (
          <div className="bg-rose-600 px-6 py-3 text-center text-white shadow-md animate-in slide-in-from-top">
            <p className="text-sm font-semibold md:text-base">
              🚨 PERINGATAN: {activeAlerts[0].title} - {activeAlerts[0].message}{" "}
              {activeAlerts[0].targetArea && `(Area Terdampak: ${activeAlerts[0].targetArea})`}
            </p>
          </div>
        )}

        <section id="home" className="relative isolate overflow-hidden text-white">
          <Image
            src={photoItems[0].src}
            alt={photoItems[0].title}
            fill
            priority
            sizes="100vw"
            className="object-cover"
          />
          <div className="absolute inset-0 bg-linear-to-r from-blue-950/90 via-blue-900/75 to-cyan-700/55" />
          <div className="absolute inset-0 bg-[radial-gradient(circle_at_top_right,rgba(255,255,255,0.2),transparent_42%)]" />

          <div className="relative mx-auto flex min-h-[86vh] w-full max-w-6xl items-center justify-center px-6 py-20 md:py-24">
            <div className="max-w-3xl text-center">
              <Reveal className="flex flex-col items-center">
                <p className="mb-4 inline-block w-fit rounded-full border border-white/35 bg-white/10 px-3 py-1 text-xs font-semibold uppercase tracking-wider text-blue-50 backdrop-blur-sm">
                  Platform Early Warning System
                </p>
                <h1 className="text-4xl font-bold leading-tight drop-shadow-sm md:text-6xl">
                  Kelola Respons Banjir Lebih Cepat, Tepat, dan Terkoordinasi
                </h1>
                <p className="mt-4 max-w-2xl text-sm text-blue-100 md:text-lg">
                  Sistem peringatan dini berbasis sensor untuk membantu masyarakat memantau potensi banjir, memahami
                  tingkat risiko, dan mengambil tindakan cepat saat kondisi darurat.
                </p>
              </Reveal>

              <Reveal delayMs={120} className="mt-8 flex flex-wrap justify-center gap-3">
                <Link
                  href="/#realtime-dashboard"
                  className="rounded-lg bg-white px-5 py-2.5 text-sm font-semibold text-blue-700 shadow-lg shadow-blue-950/20 transition-colors hover:bg-blue-50"
                >
                  Lihat Dashboard Real-Time
                </Link>
                <Link
                  href="/#emergency-action"
                  className="rounded-lg border border-white/50 bg-white/5 px-5 py-2.5 text-sm font-semibold text-white backdrop-blur-sm transition-colors hover:bg-white/15"
                >
                  Tindakan Darurat
                </Link>
              </Reveal>
            </div>
          </div>
        </section>

        {/* Dashboard Publik - Pastikan komponen ini melakukan fetch data mandiri di dalamnya */}
        <PublicRealtimeDashboardSection />

        <section id="status-legend" className="bg-blue-50">
          <div className="mx-auto w-full max-w-6xl px-6 py-16">
            <Reveal className="mb-10 max-w-3xl">
              <p className="text-sm font-semibold uppercase tracking-wide text-blue-700">Edukasi Visual</p>
              <h2 className="mt-2 text-3xl font-bold text-blue-900">Status Indicators & Legend</h2>
              <p className="mt-3 text-sm text-blue-800/80">
                Pahami kode warna status agar masyarakat dapat mengambil keputusan lebih cepat dan tepat.
              </p>
            </Reveal>

            <div className="grid gap-4 md:grid-cols-4">
              {statusLegend.map((item, index) => (
                <Reveal key={item.title} delayMs={90 * (index + 1)}>
                  <Card className="h-full border-blue-100 bg-white/95">
                    <div className="flex items-center justify-between gap-2">
                      <span className={`inline-flex h-3 w-16 rounded-full ${item.color}`} />
                      <span className="text-lg" aria-hidden="true">{item.icon}</span>
                    </div>
                    <h3 className="mt-4 text-lg font-semibold text-slate-900">{item.title}</h3>
                    <p className="mt-2 text-sm text-slate-600">{item.description}</p>
                    <div className="mt-3 rounded-lg bg-blue-50 p-3 text-xs text-blue-900">
                      <p className="font-semibold">Tindakan cepat</p>
                      <p className="mt-1 leading-relaxed">{item.action}</p>
                    </div>
                  </Card>
                </Reveal>
              ))}
            </div>
          </div>
        </section>

        {/* --- BAGIAN DINAMIS DARI DATABASE: KONTAK DARURAT --- */}
        <section id="emergency-action" className="bg-white">
          <div className="mx-auto w-full max-w-6xl px-6 py-16">
            <Reveal className="mb-10 max-w-3xl">
              <p className="text-sm font-semibold uppercase tracking-wide text-blue-700">Tindakan Cepat</p>
              <h2 className="mt-2 text-3xl font-bold text-slate-900">Kontak Darurat Resmi</h2>
              <p className="mt-3 text-sm text-slate-600">
                Tombol panggilan darurat terintegrasi langsung dengan database terkini otoritas setempat.
              </p>
            </Reveal>

            {isLoading ? (
              <div className="flex items-center justify-center py-10">
                <span className="text-sm font-medium text-slate-500">Memuat kontak darurat...</span>
              </div>
            ) : contacts.length > 0 ? (
              <div className="grid gap-4 md:grid-cols-3">
                {contacts.map((contact, index) => {
                  const meta = getEmergencyMeta(contact.category);
                  return (
                    <Reveal key={contact.id} delayMs={80 * (index + 1)}>
                      <Card className="border-slate-200">
                        <div className="flex items-start justify-between">
                          <h3 className="text-lg font-semibold text-slate-900">{contact.name}</h3>
                          <span className="rounded bg-slate-100 px-2 py-1 text-[10px] font-bold text-slate-500">
                            {contact.category}
                          </span>
                        </div>
                        <p className="mt-1 text-sm text-slate-600">Nomor prioritas tanggap darurat</p>

                        <div className="mt-3 rounded-lg bg-slate-50 p-3 text-xs text-slate-700">
                          <p className="font-semibold text-slate-900">Fokus layanan</p>
                          <p className="mt-1">{meta.scope}</p>
                          <p className="mt-2 font-semibold text-slate-900">Estimasi respons</p>
                          <p className="mt-1">{meta.response}</p>
                        </div>

                        <a
                          href={`tel:${contact.phone}`}
                          className="mt-4 flex w-full items-center justify-center rounded-lg bg-rose-600 px-4 py-2.5 text-sm font-semibold text-white transition-colors hover:bg-rose-700"
                        >
                          Hubungi {contact.phone}
                        </a>
                      </Card>
                    </Reveal>
                  );
                })}
              </div>
            ) : (
              <div className="rounded-xl border border-slate-200 bg-slate-50 p-6 text-center text-sm text-slate-600">
                Tidak ada data kontak darurat aktif di database saat ini.
              </div>
            )}
          </div>
        </section>

        <section id="education-faq" className="bg-slate-50">
          <div className="mx-auto w-full max-w-6xl px-6 py-16">
            <Reveal className="mb-10 max-w-3xl">
              <p className="text-sm font-semibold uppercase tracking-wide text-blue-700">Flood Education & FAQ</p>
              <h2 className="mt-2 text-3xl font-bold text-slate-900">Panduan Keselamatan dan Persiapan Darurat</h2>
            </Reveal>

            <div className="grid gap-4 lg:grid-cols-2">
              <Reveal>
                <Card className="h-full border-blue-100">
                  <h3 className="text-lg font-semibold text-slate-900">Panduan Evakuasi Saat Status Merah</h3>
                  <ol className="mt-4 space-y-3 text-sm text-slate-700">
                    {evacuationGuide.map((item, index) => (
                      <li key={item} className="flex gap-3">
                        <span className="inline-flex h-6 min-w-6 items-center justify-center rounded-full bg-blue-100 text-xs font-bold text-blue-700">
                          {index + 1}
                        </span>
                        <span>{item}</span>
                      </li>
                    ))}
                  </ol>
                </Card>
              </Reveal>

              <Reveal delayMs={120}>
                <Card className="h-full border-blue-100">
                  <h3 className="text-lg font-semibold text-slate-900">Daftar Barang Darurat Wajib</h3>
                  <ul className="mt-4 space-y-2 text-sm text-slate-700">
                    {emergencyKit.map((item) => (
                      <li key={item} className="flex gap-2">
                        <span className="mt-1 inline-block h-2 w-2 rounded-full bg-blue-600" />
                        <span>{item}</span>
                      </li>
                    ))}
                  </ul>
                </Card>
              </Reveal>
            </div>

            <div className="mt-4 grid gap-4 md:grid-cols-2">
              {faqs.map((item, index) => (
                <Reveal key={item.q} delayMs={70 * (index + 1)}>
                  <Card className="h-full">
                    <h3 className="text-base font-semibold text-slate-900">{item.q}</h3>
                    <p className="mt-2 text-sm text-slate-600">{item.a}</p>
                  </Card>
                </Reveal>
              ))}
            </div>
          </div>
        </section>

      </main>
    </AuthRedirectWrapper>
  );
}