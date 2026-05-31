import { Card } from "@/components/ui/Card";

export const dynamic = "force-dynamic";

interface EmergencyContact {
  id: string;
  name: string;
  phone: string;
  category: string;
  isActive: boolean;
}

const supportChannels = [
  {
    title: "Email Dukungan",
    value: "support@ewsfloodguard.id",
    actionLabel: "Kirim Email",
    href: "mailto:support@ewsfloodguard.id",
  },
  {
    title: "Telepon Posko",
    value: "+62 21 555 0199",
    actionLabel: "Hubungi Sekarang",
    href: "tel:+62215550199",
  },
  {
    title: "Alamat Operasional",
    value: "Padang, Sumatera Barat",
    actionLabel: "Lihat di Peta",
    href: "https://www.google.com/maps?q=Padang,Sumatera+Barat",
  },
];

async function getEmergencyContacts(): Promise<EmergencyContact[]> {
  try {
    const apiBaseUrl = process.env.NEXT_PUBLIC_API_URL || "http://localhost:4101/api";
    const cleanUrl = apiBaseUrl.endsWith("/") ? apiBaseUrl.slice(0, -1) : apiBaseUrl;
    const res = await fetch(`${cleanUrl}/emergency-contacts`, {
      next: { revalidate: 60 },
    });
    if (!res.ok) return [];
    const payload = await res.json();
    return (payload.data || []).filter((c: EmergencyContact) => c.isActive);
  } catch {
    return [];
  }
}

export default async function ContactPage() {
  const emergencyContacts = await getEmergencyContacts();

  return (
    <main className="mx-auto w-full max-w-6xl px-6 py-10">
      <section className="rounded-2xl bg-linear-to-br from-blue-900 via-blue-700 to-cyan-600 p-7 text-white md:p-10">
        <p className="text-sm font-semibold uppercase tracking-wide text-blue-100">Halaman Kontak</p>
        <h1 className="mt-2 text-3xl font-bold md:text-4xl">Hubungi Tim EWS Flood Guard</h1>
        <p className="mt-3 max-w-3xl text-sm text-blue-100 md:text-base">
          Gunakan halaman ini untuk kebutuhan dukungan teknis, koordinasi insiden, atau pertanyaan terkait sistem
          peringatan dini banjir.
        </p>
      </section>

      <section className="mt-6 grid gap-4 md:grid-cols-3">
        {supportChannels.map((channel) => (
          <Card key={channel.title} className="border-blue-100">
            <h2 className="text-lg font-semibold text-slate-900">{channel.title}</h2>
            <p className="mt-2 text-sm text-slate-700">{channel.value}</p>
            <a
              href={channel.href}
              target={channel.href.startsWith("http") ? "_blank" : undefined}
              rel={channel.href.startsWith("http") ? "noreferrer" : undefined}
              className="mt-4 inline-flex rounded-lg bg-blue-600 px-4 py-2 text-sm font-semibold text-white transition-colors hover:bg-blue-700"
            >
              {channel.actionLabel}
            </a>
          </Card>
        ))}
      </section>

      <section className="mt-6 rounded-2xl border border-slate-200 bg-white p-5 md:p-6">
        <h2 className="text-xl font-bold text-slate-900">Kontak Darurat Cepat</h2>
        <p className="mt-2 text-sm text-slate-600">
          Jika terjadi kondisi kritis, gunakan tombol telepon berikut untuk menghubungi layanan darurat resmi.
        </p>

        {emergencyContacts.length > 0 ? (
          <div className="mt-4 grid gap-3 md:grid-cols-3">
            {emergencyContacts.map((contact) => (
              <a
                key={contact.id}
                href={`tel:${contact.phone}`}
                className="rounded-lg border border-rose-200 bg-rose-50 p-4 transition-colors hover:bg-rose-100"
              >
                <p className="font-semibold text-rose-900">{contact.name}</p>
                <span className="mt-0.5 inline-block rounded-full bg-rose-100 px-2 py-0.5 text-[11px] font-bold text-rose-600">
                  {contact.category}
                </span>
                <p className="mt-1 text-sm font-mono font-semibold text-rose-700">{contact.phone}</p>
              </a>
            ))}
          </div>
        ) : (
          <div className="mt-4 rounded-xl bg-slate-50 border border-slate-200 p-6 text-center text-sm text-slate-500">
            Tidak ada data kontak darurat aktif saat ini.
          </div>
        )}
      </section>
    </main>
  );
}
