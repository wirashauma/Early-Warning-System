"use client";

import { useEffect, useState } from "react";
import { Card } from "@/components/ui/Card";
import api from "@/lib/api";

interface EmergencyContactItem {
  id: string;
  name: string;
  phone: string;
  category: "BPBD" | "SAR" | "AMBULANCE" | "POLICE" | "HOSPITAL" | "OTHER";
}

const emergencyMeta: Record<
  EmergencyContactItem["category"],
  {
    scope: string;
    response: string;
    note: string;
    badgeClass: string;
    buttonClass: string;
  }
> = {
  BPBD: {
    scope: "Koordinasi tanggap bencana, evakuasi wilayah terdampak, dan aktivasi posko.",
    response: "± 5-15 menit (tergantung akses lapangan)",
    note: "Cocok dihubungi saat tinggi air naik cepat dan butuh koordinasi wilayah.",
    badgeClass: "bg-blue-100 text-blue-700",
    buttonClass: "bg-blue-600 hover:bg-blue-700",
  },
  SAR: {
    scope: "Pencarian dan penyelamatan korban pada kondisi arus/akses berbahaya.",
    response: "Prioritas tinggi untuk kondisi kritis",
    note: "Hubungi jika ada korban terjebak, hanyut, atau butuh rescue segera.",
    badgeClass: "bg-amber-100 text-amber-700",
    buttonClass: "bg-amber-600 hover:bg-amber-700",
  },
  AMBULANCE: {
    scope: "Pertolongan medis darurat untuk korban luka, sesak, atau kondisi gawat.",
    response: "Secepat mungkin sesuai antrean darurat",
    note: "Sampaikan kondisi pasien, usia, gejala utama, dan akses kendaraan.",
    badgeClass: "bg-rose-100 text-rose-700",
    buttonClass: "bg-rose-600 hover:bg-rose-700",
  },
  POLICE: {
    scope: "Pengamanan lokasi, pengaturan lalu lintas, dan dukungan evakuasi.",
    response: "Sesuai prioritas kejadian lapangan",
    note: "Hubungi jika perlu pengamanan area, rekayasa lalu lintas, atau dukungan keamanan.",
    badgeClass: "bg-indigo-100 text-indigo-700",
    buttonClass: "bg-indigo-600 hover:bg-indigo-700",
  },
  HOSPITAL: {
    scope: "Rujukan medis lanjutan dan penanganan kegawatdaruratan fasilitas kesehatan.",
    response: "Bergantung kapasitas rumah sakit",
    note: "Hubungi untuk koordinasi rujukan pasien banjir dan ketersediaan layanan.",
    badgeClass: "bg-teal-100 text-teal-700",
    buttonClass: "bg-teal-600 hover:bg-teal-700",
  },
  OTHER: {
    scope: "Bantuan darurat umum sesuai kebutuhan lokal.",
    response: "Bervariasi",
    note: "Pastikan jelaskan kebutuhan dan lokasi secara ringkas.",
    badgeClass: "bg-slate-100 text-slate-700",
    buttonClass: "bg-slate-700 hover:bg-slate-800",
  },
};

const callChecklist = [
  "Sebutkan lokasi detail (alamat, patokan terdekat, atau titik Google Maps).",
  "Jelaskan kondisi saat ini: tinggi air, arus, akses jalan, dan cuaca.",
  "Informasikan jumlah warga terdampak dan kelompok rentan (anak/lansia/disabilitas).",
  "Sampaikan kebutuhan paling mendesak: evakuasi, medis, logistik, atau penyelamatan.",
];

const quickActions = [
  { label: "Pantau Dashboard", href: "/user/dashboard" },
  { label: "Lihat Peta Sensor", href: "/user/map" },
  { label: "Buka Panduan", href: "/user/education" },
  { label: "Cek Notifikasi", href: "/user/notifications" },
];

export default function UserEmergencyPage() {
  const [emergencyContacts, setEmergencyContacts] = useState<EmergencyContactItem[]>([]);

  function sanitizePhoneForTel(phone: string) {
    // remove spaces, parentheses, dashes, and dots; keep leading + if present
    return phone.replace(/[^+\d]/g, "");
  }

  useEffect(() => {
    let cancelled = false;

    const loadContacts = async () => {
      try {
        const response = await api.get("/emergency-contacts");
        const rows = (response.data?.data ?? []) as EmergencyContactItem[];

        if (!cancelled) {
          setEmergencyContacts(rows);
        }
      } catch {
        if (!cancelled) {
          setEmergencyContacts([]);
        }
      }
    };

    void loadContacts();

    return () => {
      cancelled = true;
    };
  }, []);

  return (
    <main className="mx-auto w-full max-w-6xl px-6 py-8">
      <section className="rounded-2xl border border-rose-100 bg-linear-to-br from-rose-50 via-white to-blue-50 p-6 shadow-sm">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-wide text-rose-700">Emergency User Center</p>
            <h1 className="mt-1 text-3xl font-bold text-slate-900">Kontak Darurat (Mode User)</h1>
            <p className="mt-2 max-w-3xl text-sm text-slate-600">
              Gunakan halaman ini saat situasi kritis. Pilih layanan yang tepat, lakukan panggilan cepat,
              dan sampaikan informasi yang jelas agar bantuan datang lebih cepat.
            </p>
          </div>

          <div className="rounded-xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm text-rose-900">
            <p className="font-semibold">Prioritas saat status Bahaya</p>
            <p className="mt-1 text-xs text-rose-800/90">Keselamatan jiwa dahulu, dokumentasi menyusul.</p>
          </div>
        </div>

        <div className="mt-4 flex flex-wrap gap-2">
          {quickActions.map((item) => (
            <a
              key={item.href}
              href={item.href}
              className="rounded-full border border-slate-200 bg-white px-3 py-1.5 text-xs font-semibold text-slate-700 transition-colors hover:bg-slate-50"
            >
              {item.label}
            </a>
          ))}
        </div>
      </section>

      <section className="mt-5 rounded-2xl border border-slate-200 bg-white p-4 shadow-sm md:p-5">
        <div className="mb-4">
          <h2 className="text-lg font-semibold text-slate-900">Layanan Darurat Prioritas</h2>
          <p className="mt-1 text-sm text-slate-600">Tekan tombol panggil sesuai kebutuhan utama yang sedang terjadi.</p>
        </div>

        <div className="grid gap-4 md:grid-cols-3">
          {emergencyContacts.map((contact) => {
            const meta = emergencyMeta[contact.category] ?? emergencyMeta.OTHER;

            return (
              <Card key={contact.id} className="h-full border-slate-200 bg-white">
                <div className="flex items-start justify-between gap-2">
                  <h3 className="text-lg font-semibold text-slate-900">{contact.name}</h3>
                  <span className={`rounded-full px-2.5 py-1 text-xs font-semibold ${meta.badgeClass}`}>
                    Prioritas
                  </span>
                </div>

                <p className="mt-1 text-sm text-slate-600">Nomor Darurat</p>
                <p className="mt-0.5 text-2xl font-bold tracking-wide text-slate-900">{contact.phone}</p>

                <div className="mt-3 rounded-lg border border-slate-200 bg-slate-50 p-3 text-xs text-slate-700">
                  <p className="font-semibold text-slate-900">Fokus layanan</p>
                  <p className="mt-1 leading-relaxed">{meta.scope}</p>

                  <p className="mt-2 font-semibold text-slate-900">Estimasi respons</p>
                  <p className="mt-1">{meta.response}</p>
                </div>

                <a
                  href={`tel:${sanitizePhoneForTel(contact.phone)}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className={`mt-4 inline-flex w-full items-center justify-center rounded-lg px-4 py-2.5 text-sm font-semibold text-white transition-colors ${meta.buttonClass}`}
                >
                  Hubungi {contact.phone}
                </a>

                <p className="mt-3 text-xs leading-relaxed text-slate-500">{meta.note}</p>
              </Card>
            );
          })}
        </div>

        {emergencyContacts.length === 0 && (
          <div className="mt-4 rounded-xl border border-amber-200 bg-amber-50 p-3 text-sm text-amber-800">
            Data kontak darurat belum tersedia dari backend.
          </div>
        )}
      </section>

      <section className="mt-5 grid gap-4 lg:grid-cols-3">
        <Card className="border-rose-100 bg-rose-50 lg:col-span-2">
          <h2 className="text-base font-semibold text-rose-900">Informasi yang Harus Disiapkan Saat Menelepon</h2>
          <p className="mt-1 text-sm text-rose-900/90">
            Semakin jelas informasi yang kamu sampaikan, semakin cepat tim dapat menentukan tindakan.
          </p>

          <ul className="mt-3 space-y-2 text-sm text-rose-900/95">
            {callChecklist.map((item) => (
              <li key={item} className="flex gap-2 rounded-lg bg-white/75 px-3 py-2">
                <span className="mt-0.5" aria-hidden="true">•</span>
                <span>{item}</span>
              </li>
            ))}
          </ul>
        </Card>

        <Card className="border-slate-200 bg-slate-50">
          <h2 className="text-base font-semibold text-slate-900">Alur Tindakan Cepat</h2>
          <ol className="mt-3 space-y-2 text-sm text-slate-700">
            <li className="rounded-lg border border-slate-200 bg-white px-3 py-2">1. Cek sensor paling berisiko di Dashboard/Peta.</li>
            <li className="rounded-lg border border-slate-200 bg-white px-3 py-2">2. Hubungi layanan darurat yang paling relevan.</li>
            <li className="rounded-lg border border-slate-200 bg-white px-3 py-2">3. Ikuti arahan petugas dan prioritaskan evakuasi aman.</li>
          </ol>
        </Card>
      </section>
    </main>
  );
}
