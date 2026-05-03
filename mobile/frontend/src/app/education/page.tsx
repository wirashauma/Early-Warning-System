import { Card } from "@/components/ui/Card";

const faqs = [
  {
    q: "Apa yang harus dilakukan saat status merah?",
    a: "Segera evakuasi ke titik aman, matikan listrik utama, dan ikuti arahan petugas lapangan.",
  },
  {
    q: "Bagaimana membaca status indikator?",
    a: "Hijau = aman, Kuning = siaga, Merah = bahaya. Pantau dashboard secara berkala.",
  },
  {
    q: "Apakah notifikasi selalu real-time?",
    a: "Ya, notifikasi dikirim melalui kanal yang dipilih petugas saat terjadi perubahan status penting.",
  },
];

export default function EducationPage() {
  return (
    <main className="mx-auto w-full max-w-4xl px-6 py-8">
      <h1 className="mb-2 text-2xl font-bold text-slate-900">Edukasi Banjir & FAQ</h1>
      <p className="mb-6 text-sm text-slate-600">
        Panduan singkat agar warga lebih siap menghadapi potensi banjir.
      </p>

      <div className="space-y-4">
        {faqs.map((item) => (
          <Card key={item.q}>
            <h2 className="text-base font-semibold text-slate-900">{item.q}</h2>
            <p className="mt-2 text-sm text-slate-600">{item.a}</p>
          </Card>
        ))}
      </div>
    </main>
  );
}
