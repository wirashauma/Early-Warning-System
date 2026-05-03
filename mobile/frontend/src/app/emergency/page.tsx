import { emergencyContacts } from "@/constants";
import { Card } from "@/components/ui/Card";

export default function EmergencyPage() {
  return (
    <main className="mx-auto w-full max-w-4xl px-6 py-8">
      <h1 className="mb-2 text-2xl font-bold text-slate-900">Kontak Darurat</h1>
      <p className="mb-6 text-sm text-slate-600">
        Hubungi layanan terdekat saat status bahaya banjir aktif.
      </p>

      <div className="grid gap-4 md:grid-cols-3">
        {emergencyContacts.map((contact) => (
          <Card key={contact.name}>
            <h2 className="text-lg font-semibold text-slate-900">{contact.name}</h2>
            <p className="mb-3 mt-1 text-slate-600">{contact.phone}</p>
            <a href={`tel:${contact.phone}`} className="text-sm font-semibold text-blue-600 hover:text-blue-700">
              Click to Call
            </a>
          </Card>
        ))}
      </div>
    </main>
  );
}
