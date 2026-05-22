"use client";

import { useState } from "react";
import { AlertTriangle, Backpack, ChevronDown, CircleCheckBig, ShieldAlert } from "lucide-react";

const emergencyPreparation = [
  {
    tone: "danger",
    eyebrow: "Prioritas Tinggi",
    title: "Panduan Evakuasi Saat Status Merah",
    description:
      "Saat status merah aktif, fokus utama adalah keselamatan jiwa. Jangan menunggu air naik lebih tinggi untuk bergerak.",
    accentClassName: "border-rose-200 bg-rose-50/90",
    iconClassName: "bg-rose-600 text-white",
    icon: AlertTriangle,
    items: [
      "Matikan listrik utama dan amankan dokumen penting dalam wadah tahan air.",
      "Bawa tas siaga, pastikan semua anggota keluarga berkumpul, lalu evakuasi ke titik aman.",
      "Hindari menerobos arus air, kabel listrik terbuka, dan jalur yang belum diverifikasi aman.",
      "Tetap pantau instruksi petugas atau notifikasi resmi sampai kondisi benar-benar aman.",
    ],
  },
  {
    tone: "safe",
    eyebrow: "Siaga Cepat",
    title: "Daftar Barang Darurat Wajib",
    description:
      "Siapkan perlengkapan berikut agar evakuasi bisa dilakukan cepat tanpa panik dan tanpa bolak-balik mencari barang.",
    accentClassName: "border-blue-200 bg-blue-50/90",
    iconClassName: "bg-blue-600 text-white",
    icon: Backpack,
    items: [
      "Dokumen penting: KTP, KK, surat berharga, dan salinan kontak darurat.",
      "Obat pribadi, kotak P3K, masker, dan perlengkapan bayi atau lansia bila diperlukan.",
      "Air minum, makanan siap saji, senter, powerbank, peluit, dan baterai cadangan.",
      "Pakaian ganti secukupnya, perlengkapan kebersihan dasar, dan uang tunai secukupnya.",
    ],
  },
];

const faqs = [
  {
    q: "Bagaimana cara membaca warna status di dashboard?",
    a: "Hijau berarti normal, Kuning waspada, Oren siaga, dan Merah bahaya. Semakin tinggi level, semakin cepat tindakan evakuasi harus dilakukan.",
  },
  {
    q: "Kapan saya harus menghubungi kontak darurat?",
    a: "Segera hubungi saat status merah, ada arus air berbahaya, atau ada anggota keluarga/warga yang membutuhkan bantuan medis dan evakuasi segera.",
  },
  {
    q: "Apakah notifikasi selalu muncul otomatis?",
    a: "Ya, notifikasi muncul saat ada perubahan level penting pada sensor. Pastikan izin notifikasi browser atau perangkat tidak diblokir.",
  },
  {
    q: "Apa informasi minimum saat menelepon layanan darurat?",
    a: "Sebutkan lokasi spesifik, jumlah warga terdampak, kondisi air atau akses jalan, serta kebutuhan bantuan yang paling mendesak.",
  },
];

export function EducationFAQ() {
  const [openFaq, setOpenFaq] = useState(0);

  return (
    <section id="edukasi" className="scroll-mt-24 bg-slate-50">
      <div className="mx-auto w-full max-w-6xl px-4 py-20 md:px-8 lg:px-16">
        <div className="max-w-3xl">
          <p className="text-sm font-semibold uppercase tracking-wide text-blue-700">Edukasi & FAQ</p>
          <h2 className="mt-2 text-3xl font-bold text-slate-900 md:text-4xl">Panduan Kesiapsiagaan dan Pertanyaan Umum</h2>
          <p className="mt-3 text-sm leading-relaxed text-slate-600 md:text-base">
            Ringkasan yang lebih mudah dipindai untuk membantu pengguna bertindak cepat saat status berubah dan ketika
            butuh informasi penting dalam hitungan detik.
          </p>
        </div>

        <div className="mt-10">
          <div className="mb-5 flex items-center gap-3">
            <span className="inline-flex h-10 w-10 items-center justify-center rounded-2xl bg-linear-to-br from-blue-600 to-cyan-500 text-white shadow-sm shadow-blue-200">
              <ShieldAlert className="size-5" aria-hidden="true" />
            </span>
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500">Part A</p>
              <h3 className="text-xl font-bold text-slate-900">Emergency Preparation</h3>
            </div>
          </div>

          <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
            {emergencyPreparation.map((item) => {
              const Icon = item.icon;

              return (
                <article
                  key={item.title}
                  className={`rounded-xl border ${item.accentClassName} p-6 shadow-md shadow-slate-200/60 transition-transform duration-200 hover:-translate-y-0.5`}
                >
                  <div className="flex items-start gap-4">
                    <div className={`inline-flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl ${item.iconClassName} shadow-sm`}>
                      <Icon className="size-5" aria-hidden="true" />
                    </div>

                    <div className="min-w-0 flex-1">
                      <p className={`text-xs font-semibold uppercase tracking-[0.18em] ${item.tone === "danger" ? "text-rose-700" : "text-blue-700"}`}>
                        {item.eyebrow}
                      </p>
                      <h4 className="mt-1 text-lg font-semibold text-slate-900">{item.title}</h4>
                      <p className="mt-2 text-sm leading-relaxed text-slate-600">{item.description}</p>
                    </div>
                  </div>

                  <ul className="mt-5 space-y-3">
                    {item.items.map((point) => (
                      <li key={point} className="flex gap-3 text-sm leading-relaxed text-slate-700">
                        <span
                          className={`mt-1 inline-flex h-5 w-5 shrink-0 items-center justify-center rounded-full ${
                            item.tone === "danger" ? "bg-rose-100 text-rose-700" : "bg-blue-100 text-blue-700"
                          }`}
                        >
                          <CircleCheckBig className="size-3.5" aria-hidden="true" />
                        </span>
                        <span>{point}</span>
                      </li>
                    ))}
                  </ul>
                </article>
              );
            })}
          </div>
        </div>

        <div className="mt-14">
          <div className="mb-5 flex items-center gap-3">
            <span className="inline-flex h-10 w-10 items-center justify-center rounded-2xl bg-white text-blue-700 shadow-sm ring-1 ring-slate-200">
              <ChevronDown className="size-5" aria-hidden="true" />
            </span>
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500">Part B</p>
              <h3 className="text-xl font-bold text-slate-900">Pertanyaan yang Sering Diajukan (FAQ)</h3>
            </div>
          </div>

          <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-md shadow-slate-200/60">
            {faqs.map((item, index) => {
              const isOpen = openFaq === index;

              return (
                <div key={item.q} className={index === faqs.length - 1 ? "" : "border-b border-slate-200"}>
                  <button
                    type="button"
                    onClick={() => setOpenFaq((current) => (current === index ? current : index))}
                    className="flex w-full items-center justify-between gap-4 px-5 py-4 text-left transition-colors hover:bg-slate-50"
                    aria-expanded={isOpen}
                    aria-controls={`faq-panel-${index}`}
                    id={`faq-trigger-${index}`}
                  >
                    <span className="text-sm font-semibold text-slate-900 md:text-base">{item.q}</span>
                    <span
                      className={`inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-full border border-slate-200 bg-white text-slate-500 transition-transform duration-200 ${
                        isOpen ? "rotate-180 text-blue-600" : "rotate-0"
                      }`}
                    >
                      <ChevronDown className="size-4" aria-hidden="true" />
                    </span>
                  </button>

                  <div
                    id={`faq-panel-${index}`}
                    role="region"
                    aria-labelledby={`faq-trigger-${index}`}
                    className={`grid overflow-hidden transition-all duration-300 ease-in-out ${
                      isOpen ? "grid-rows-[1fr]" : "grid-rows-[0fr]"
                    }`}
                  >
                    <div className="min-h-0">
                      <div className="px-5 pb-5 text-sm leading-relaxed text-slate-600">{item.a}</div>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </section>
  );
}