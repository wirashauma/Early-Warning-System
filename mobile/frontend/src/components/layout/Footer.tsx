export function Footer() {
  return (
    <footer className="border-t border-slate-200 bg-white">
      <div className="mx-auto w-full max-w-6xl px-6 py-5 text-sm text-slate-500">
        © {new Date().getFullYear()} EWS Flood Guard. Sistem Peringatan Dini Banjir.
      </div>
    </footer>
  );
}
