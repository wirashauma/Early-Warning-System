"use client";

import { useEffect, useState } from "react";
import api from "@/lib/api";
import { Card } from "@/components/ui/Card";
import { Reveal } from "@/components/ui/Reveal";

interface EmergencyContact {
  id: string;
  name: string;
  phone: string;
  category: string;
  isActive: boolean;
}

export default function EmergencyPage() {
  const [contacts, setContacts] = useState<EmergencyContact[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const fetchContacts = async () => {
      try {
        const response = await api.get("/emergency-contacts");
        if (response.data?.data) {
          setContacts(response.data.data.filter((c: EmergencyContact) => c.isActive));
        }
      } catch (error) {
        console.error("Gagal mengambil kontak darurat:", error);
      } finally {
        setIsLoading(false);
      }
    };

    fetchContacts();
  }, []);

  return (
    <main className="mx-auto w-full max-w-6xl px-6 py-12">
      <Reveal>
        <h1 className="text-4xl font-bold tracking-tight text-slate-900">Kontak Darurat</h1>
        <p className="mt-4 max-w-2xl text-lg text-slate-600">
          Hubungi layanan otoritas terdekat untuk bantuan evakuasi, medis, atau keamanan saat kondisi darurat banjir.
        </p>
      </Reveal>

      {isLoading ? (
        <div className="mt-12 flex h-40 items-center justify-center rounded-2xl border border-dashed border-slate-200">
          <div className="flex flex-col items-center gap-2">
            <div className="h-8 w-8 animate-spin rounded-full border-4 border-blue-600 border-t-transparent" />
            <p className="text-sm font-medium text-slate-500">Memperbarui data dari pusat...</p>
          </div>
        </div>
      ) : contacts.length > 0 ? (
        <div className="mt-12 grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          {contacts.map((contact, index) => (
            <Reveal key={contact.id} delayMs={index * 100}>
              <Card className="group relative overflow-hidden border-slate-200 p-6 transition-all hover:shadow-xl hover:shadow-blue-500/10">
                <div className="flex items-start justify-between">
                  <div>
                    <span className="inline-flex items-center rounded-full bg-blue-50 px-2.5 py-0.5 text-xs font-bold text-blue-700">
                      {contact.category}
                    </span>
                    <h2 className="mt-3 text-xl font-bold text-slate-900 group-hover:text-blue-600">
                      {contact.name}
                    </h2>
                  </div>
                </div>
                
                <p className="mt-4 text-2xl font-mono font-bold text-slate-800">
                  {contact.phone}
                </p>
                
                <a 
                  href={`tel:${contact.phone}`} 
                  className="mt-6 flex w-full items-center justify-center gap-2 rounded-xl bg-rose-600 px-4 py-3 text-sm font-bold text-white transition-all hover:bg-rose-700 active:scale-95"
                >
                  <svg className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                  </svg>
                  Hubungi Sekarang
                </a>
              </Card>
            </Reveal>
          ))}
        </div>
      ) : (
        <div className="mt-12 rounded-2xl bg-slate-50 p-12 text-center border border-slate-200">
          <p className="text-slate-600">Tidak ada kontak darurat aktif yang ditemukan dalam jangkauan Anda.</p>
        </div>
      )}
    </main>
  );
}
