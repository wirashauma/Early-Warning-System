import Link from "next/link";

const productLinks = [
  { label: "Dashboard Real-Time", href: "/#realtime-dashboard" },
  { label: "Dashboard", href: "/dashboard" },
  { label: "Peta Sensor", href: "/map" },
  { label: "Edukasi & FAQ", href: "/#education-faq" },
];

const companyLinks = [
  { label: "Tentang Kami", href: "/#home" },
  { label: "Kontak Darurat", href: "/emergency" },
  { label: "Status & Legend", href: "/#status-legend" },
  { label: "Halaman Kontak", href: "/contact" },
];

export function Footer() {
  return (
    <footer id="contact" className="bg-linear-to-br from-blue-950 via-blue-900 to-blue-800 text-blue-100">
      <div className="mx-auto w-full max-w-6xl px-6 py-10 md:py-12">
        <div className="grid gap-7 lg:grid-cols-[1.25fr_1fr_1fr_1fr]">
          <div>
            <div className="flex items-center gap-3">
              <div className="flex size-11 items-center justify-center rounded-lg bg-cyan-500/25 text-cyan-200 ring-1 ring-cyan-300/40">
                <svg viewBox="0 0 24 24" className="size-6" fill="none" stroke="currentColor" strokeWidth="1.8">
                  <path d="M4 6.5A2.5 2.5 0 0 1 6.5 4H20v14.5A1.5 1.5 0 0 1 18.5 20H6.5A2.5 2.5 0 0 0 4 22V6.5Z" />
                  <path d="M8 8h8" />
                  <path d="M8 12h8" />
                </svg>
              </div>
              <div>
                <p className="text-xl font-bold leading-none text-white md:text-2xl">EWS Flood Guard</p>
                <p className="mt-1 text-xs font-medium text-blue-200 md:text-sm">Sistem Peringatan Dini Banjir</p>
              </div>
            </div>

            <p className="mt-4 max-w-sm text-sm leading-relaxed text-blue-100/90 md:text-base">
              Platform monitoring real-time untuk membantu admin memantau sensor, memvalidasi alert, dan mempercepat
              koordinasi respons banjir.
            </p>

            <div className="mt-4 flex items-center gap-2.5">
              {[
                { label: "Facebook", icon: "f" },
                { label: "X", icon: "x" },
                { label: "Instagram", icon: "ig" },
                { label: "LinkedIn", icon: "in" },
              ].map((item) => (
                <span
                  key={item.label}
                  className="inline-flex h-9 min-w-9 items-center justify-center rounded-lg bg-white/10 px-2 text-xs font-bold uppercase text-blue-50 ring-1 ring-white/10"
                  aria-label={item.label}
                  title={item.label}
                >
                  {item.icon}
                </span>
              ))}
            </div>
          </div>

          <div>
            <h3 className="text-lg font-semibold text-white md:text-xl">Produk</h3>
            <ul className="mt-3.5 space-y-2.5 text-sm md:text-base">
              {productLinks.map((item) => (
                <li key={item.href}>
                  <Link href={item.href} className="text-blue-200/95 transition-colors hover:text-white">
                    {item.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          <div>
            <h3 className="text-lg font-semibold text-white md:text-xl">Perusahaan</h3>
            <ul className="mt-3.5 space-y-2.5 text-sm md:text-base">
              {companyLinks.map((item) => (
                <li key={item.href}>
                  <Link href={item.href} className="text-blue-200/95 transition-colors hover:text-white">
                    {item.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          <div>
            <h3 className="text-lg font-semibold text-white md:text-xl">Kontak</h3>
            <ul className="mt-3.5 space-y-3 text-sm text-blue-100/95 md:text-base">
              <li className="flex items-center gap-2.5">
                <span aria-hidden="true">✉️</span>
                <span>support@ewsfloodguard.id</span>
              </li>
              <li className="flex items-center gap-2.5">
                <span aria-hidden="true">📞</span>
                <span>+62 21 555 0199</span>
              </li>
              <li className="flex items-center gap-2.5">
                <span aria-hidden="true">📍</span>
                <span>Padang, Sumatera Barat</span>
              </li>
            </ul>
          </div>
        </div>

        <div className="mt-8 border-t border-white/15 pt-4">
          <div className="flex flex-col gap-4 text-sm text-blue-200 sm:flex-row sm:items-center sm:justify-between">
            <p>© {new Date().getFullYear()} EWS Flood Guard. All rights reserved.</p>
            <div className="flex items-center gap-6 font-medium">
              <Link href="/login" className="transition-colors hover:text-white">
                Login
              </Link>
              <Link href="/education" className="transition-colors hover:text-white">
                Bantuan
              </Link>
            </div>
          </div>
        </div>
      </div>
    </footer>
  );
}
