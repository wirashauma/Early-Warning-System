import Link from "next/link";

export default function NotFound() {
  return (
    <main className="mx-auto flex min-h-[70vh] w-full max-w-3xl flex-col items-center justify-center gap-4 px-6 text-center">
      <h1 className="text-3xl font-bold text-slate-900">404 - Halaman Tidak Ditemukan</h1>
      <p className="text-slate-600">Rute yang kamu cari belum tersedia atau sudah dipindahkan.</p>
      <Link href="/" className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-700">
        Kembali ke Beranda
      </Link>
    </main>
  );
}
