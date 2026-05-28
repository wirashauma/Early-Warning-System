"use client";

import { useState, useRef, useEffect } from "react";
import { useRouter } from "next/navigation";
import Image from "next/image";
import { ConfirmDialog } from "@/components/ui/ConfirmDialog";
import { useAuth } from "@/hooks/useAuth";
import api from "@/lib/api";

export default function ProfilePage() {
  const router = useRouter();
  const { user, isAuthenticated, updateProfile } = useAuth();
  
  const [name, setName] = useState("");
  const [avatar, setAvatar] = useState<string | null>(null);
  const [avatarFile, setAvatarFile] = useState<File | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [message, setMessage] = useState({ type: "", text: "" });
  const [removeAvatarConfirmOpen, setRemoveAvatarConfirmOpen] = useState(false);
  
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Isi form dengan data user saat ini ketika halaman dimuat
  useEffect(() => {
    if (user) {
      setName(user.name || "");
      // Jika user punya avatar dari database, tampilkan. Jika tidak, null.
      setAvatar((user as { avatar?: string }).avatar || null); 
    }
  }, [user]);

  // Fungsi untuk menangkap file gambar secara langsung
  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    // Batasi ukuran gambar maks 2MB
    if (file.size > 2 * 1024 * 1024) {
      setMessage({ type: "error", text: "Ukuran gambar terlalu besar (Maks 2MB)." });
      return;
    }

    setAvatarFile(file);
    // Instant preview using browser blob URL
    setAvatar(URL.createObjectURL(file));
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    setMessage({ type: "", text: "" });

    try {
      const formData = new FormData();
      formData.append("name", name);
      
      if (avatarFile) {
        formData.append("avatar", avatarFile);
      } else if (avatar === null) {
        formData.append("removeAvatar", "true");
      }

      // Kirim data ke endpoint PUT /auth/profile yang baru kita buat (multipart/form-data)
      const response = await api.put("/auth/profile", formData);

      const updatedUser = response.data?.data as { name?: string; avatar?: string | null } | undefined;
      updateProfile({
        name: updatedUser?.name ?? name,
        avatar: updatedUser?.avatar ?? avatar,
      });

      // Reset state file raw setelah sukses
      setAvatarFile(null);
      setMessage({ type: "success", text: "Profil berhasil diperbarui!" });

    } catch (err: any) {
      const errorMsg = err.response?.data?.message || "Gagal memperbarui profil.";
      setMessage({ type: "error", text: errorMsg });
    } finally {
      setIsSubmitting(false);
    }
  };

  if (!isAuthenticated) return null;

  // Mengambil inisial jika belum ada foto
  const userInitial = name ? name.charAt(0).toUpperCase() : "U";

  return (
    <div className="min-h-screen bg-slate-50/50 py-10">
      <main className="mx-auto max-w-3xl px-6">
        
        <header className="mb-8">
          <button onClick={() => router.back()} className="mb-4 text-sm font-semibold text-blue-600 hover:text-blue-800">
            &larr; Kembali
          </button>
          <h1 className="text-3xl font-extrabold text-slate-900">Pengaturan Profil</h1>
          <p className="mt-1 text-slate-500">Kelola informasi pribadi dan foto profil Anda.</p>
        </header>

        <div className="rounded-3xl bg-white p-6 shadow-sm ring-1 ring-slate-100 md:p-10">
          <form onSubmit={handleSave} className="flex flex-col gap-8">
            
            {/* Bagian Foto Profil */}
            <div className="flex flex-col items-center gap-6 sm:flex-row">
              <div className="relative h-28 w-28 shrink-0 overflow-hidden rounded-full ring-4 ring-slate-50">
                {avatar ? (
                  <Image src={avatar} alt="Profile" fill unoptimized className="object-cover" />
                ) : (
                  <div className="flex h-full w-full items-center justify-center bg-blue-600 text-4xl font-bold text-white">
                    {userInitial}
                  </div>
                )}
              </div>
              
              <div className="flex flex-col items-center sm:items-start">
                <h3 className="font-bold text-slate-900">Foto Profil</h3>
                <p className="mb-3 text-center text-xs text-slate-500 sm:text-left">
                  Format JPG, PNG atau GIF. Ukuran maksimal 2MB.
                </p>
                <div className="flex gap-3">
                  <button
                    type="button"
                    onClick={() => fileInputRef.current?.click()}
                    className="rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm font-semibold text-slate-700 shadow-sm transition hover:bg-slate-50"
                  >
                    Ubah Foto
                  </button>
                  {avatar && (
                    <button
                      type="button"
                      onClick={() => setRemoveAvatarConfirmOpen(true)}
                      className="rounded-xl px-4 py-2 text-sm font-semibold text-rose-600 transition hover:bg-rose-50"
                    >
                      Hapus
                    </button>
                  )}
                </div>
                {/* Input file yang disembunyikan */}
                <input
                  type="file"
                  accept="image/*"
                  ref={fileInputRef}
                  onChange={handleFileChange}
                  className="hidden"
                />
              </div>
            </div>

            <hr className="border-slate-100" />

            {/* Bagian Form Data */}
            <div className="grid gap-6 md:grid-cols-2">
              <div className="flex flex-col gap-2">
                <label className="text-sm font-semibold text-slate-700">Nama Lengkap</label>
                <input
                  type="text"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  className="rounded-xl border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-blue-500 focus:ring-1 focus:ring-blue-500"
                  required
                />
              </div>

              <div className="flex flex-col gap-2">
                <label className="text-sm font-semibold text-slate-700">Alamat Email</label>
                <input
                  type="email"
                  value={user?.email || ""}
                  disabled
                  className="cursor-not-allowed rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-500"
                />
                <p className="text-xs text-slate-400">Email tidak dapat diubah.</p>
              </div>
            </div>

            {/* Pesan Notifikasi */}
            {message.text && (
              <div className={`rounded-xl p-4 text-sm font-medium ${message.type === 'success' ? 'bg-emerald-50 text-emerald-700' : 'bg-rose-50 text-rose-700'}`}>
                {message.text}
              </div>
            )}

            {/* Tombol Simpan */}
            <div className="flex justify-end pt-4">
              <button
                type="submit"
                disabled={isSubmitting}
                className="rounded-xl bg-blue-600 px-6 py-3 text-sm font-bold text-white shadow-sm transition-all hover:bg-blue-700 focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 disabled:opacity-50"
              >
                {isSubmitting ? "Menyimpan..." : "Simpan Perubahan"}
              </button>
            </div>

          </form>
        </div>

        <ConfirmDialog
          open={removeAvatarConfirmOpen}
          title="Hapus foto profil?"
          description="Foto profil akan dihapus dari draft perubahan. Simpan profil untuk menerapkan perubahan ke akun Anda."
          confirmText="Ya, hapus"
          cancelText="Batal"
          onCancel={() => setRemoveAvatarConfirmOpen(false)}
          onConfirm={() => {
            setAvatar(null);
            setRemoveAvatarConfirmOpen(false);
          }}
        />
      </main>
    </div>
  );
}