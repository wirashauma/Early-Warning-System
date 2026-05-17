"use client";

import { FormEvent, useEffect, useMemo, useState } from "react";
import type { AppUser, UserRole } from "@/types/user";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { ConfirmDialog } from "@/components/ui/ConfirmDialog";
import { Modal } from "@/components/ui/Modal";
import api from "@/lib/api";

interface UserFormState {
  name: string;
  email: string;
  whatsappNumber: string;
  password: string;
  role: UserRole;
  institution: string;
}

const emptyUserForm: UserFormState = {
  name: "",
  email: "",
  whatsappNumber: "",
  password: "",
  role: "user",
  institution: "",
};

interface ApiUser {
  id: string;
  name: string;
  email: string;
  phone?: string | null;
  institution?: string | null;
  role: "ADMIN" | "USER" | string;
}

function mapRole(role: ApiUser["role"]): UserRole {
  const normalized = role.toUpperCase();
  if (normalized === "ADMIN") {
    return "admin";
  }
  return "user";
}

function toApiRole(role: UserRole): "ADMIN" | "USER" {
  return role === "admin" ? "ADMIN" : "USER";
}

export default function AdminUsersPage() {
  const [users, setUsers] = useState<AppUser[]>([]);
  const [loading, setLoading] = useState(true);
  const [open, setOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [savedMessage, setSavedMessage] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [form, setForm] = useState<UserFormState>(emptyUserForm);
  const [deleteConfirm, setDeleteConfirm] = useState<{ id: string; name: string } | null>(null);
  const [toastVisible, setToastVisible] = useState(false);

  const loadUsers = async () => {
    setErrorMessage(null);
    try {
      const response = await api.get("/users");
      const rows = (response.data?.data ?? []) as ApiUser[];
      setUsers(
        rows.map((row) => ({
          id: row.id,
          name: row.name,
          email: row.email,
          whatsappNumber: row.phone ?? "",
          institution: row.institution ?? null,
          role: mapRole(row.role),
        })),
      );
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : "Gagal memuat data pengguna.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void loadUsers();
  }, []);

  useEffect(() => {
    if (!savedMessage) {
      setToastVisible(false);
      return;
    }

    setToastVisible(true);
    const timer = window.setTimeout(() => {
      setToastVisible(false);
      window.setTimeout(() => setSavedMessage(null), 180);
    }, 3200);

    return () => window.clearTimeout(timer);
  }, [savedMessage]);

  const adminCount = useMemo(() => users.filter((user) => user.role === "admin").length, [users]);
  const userCount = useMemo(() => users.filter((user) => user.role === "user").length, [users]);
  const totalCount = users.length;

  const openCreate = () => {
    setEditingId(null);
    setForm(emptyUserForm);
    setErrorMessage(null);
    setOpen(true);
  };

  const openEdit = (user: AppUser) => {
    setEditingId(user.id);
    setForm({
      name: user.name,
      email: user.email,
      whatsappNumber: user.whatsappNumber ?? "",
      password: "",
      role: user.role,
      institution: user.institution ?? "",
    });
    setErrorMessage(null);
    setOpen(true);
  };

  const deleteUser = async (id: string) => {
    setSavedMessage(null);
    setErrorMessage(null);
    try {
      await api.delete(`/users/${id}`);
      setSavedMessage("Pengguna berhasil dihapus.");
      await loadUsers();
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : "Gagal menghapus pengguna.");
    }
  };

  const submitUser = async (event: FormEvent) => {
    event.preventDefault();
    setSavedMessage(null);
    setErrorMessage(null);

    try {
      if (editingId) {
        await api.put(`/users/${editingId}`, {
          name: form.name,
          email: form.email,
          phone: form.whatsappNumber,
          institution: form.institution,
          role: toApiRole(form.role),
          ...(form.password ? { password: form.password } : {}),
        });
        setSavedMessage("Pengguna berhasil diperbarui.");
      } else {
        await api.post("/users", {
          name: form.name,
          email: form.email,
          password: form.password,
          phone: form.whatsappNumber,
          institution: form.institution,
          role: toApiRole(form.role),
        });
        setSavedMessage("Pengguna baru berhasil ditambahkan.");
      }

      setOpen(false);
      await loadUsers();
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : "Gagal menyimpan data pengguna.");
    }
  };

  const totalLabel = totalCount.toLocaleString("id-ID");

  return (
    <main className="space-y-6">
      <div className="relative overflow-hidden rounded-3xl border border-blue-100/80 bg-linear-to-br from-white via-sky-50/65 to-blue-50/85 p-6 shadow-[0_18px_50px_-28px_rgba(15,23,42,0.35)] md:p-8">
        <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_top_right,rgba(59,130,246,0.16),transparent_38%)]" />
        <div className="pointer-events-none absolute inset-y-0 right-0 w-56 bg-[linear-gradient(180deg,rgba(59,130,246,0.06),transparent_50%,rgba(14,165,233,0.06))]" />

        <div className="relative flex flex-col gap-5 lg:flex-row lg:items-end lg:justify-between">
          <div className="max-w-3xl space-y-3">
            <div className="inline-flex items-center gap-2 rounded-full border border-blue-100 bg-white/75 px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.18em] text-blue-700 shadow-sm backdrop-blur">
              <span className="size-2 rounded-full bg-blue-500" />
              Flood Guard · User Administration
            </div>
            <div className="space-y-2">
              <h1 className="text-3xl font-semibold tracking-tight text-slate-900 md:text-4xl">Manajemen Pengguna</h1>
              <p className="max-w-2xl text-sm leading-6 text-slate-600 md:text-[15px]">
                Kelola akses akun admin dan user dengan role-based access control (RBAC) secara rapi, aman, dan intuitif.
              </p>
            </div>
          </div>

          <Button
            onClick={openCreate}
            className="inline-flex items-center gap-2 rounded-xl bg-blue-600 px-5 py-3 text-sm font-semibold text-white shadow-lg shadow-blue-600/20 transition hover:bg-blue-700"
          >
            <span className="text-base leading-none">＋</span>
            Tambah User
          </Button>
        </div>
      </div>

      <div className="grid gap-4 md:grid-cols-3">
        <Card className="border border-slate-100 bg-white/95 p-5 shadow-sm shadow-slate-200/60 backdrop-blur-sm">
          <div className="flex items-start justify-between gap-4">
            <div>
              <p className="text-sm font-medium text-slate-500">Total Users</p>
              <p className="mt-2 text-3xl font-semibold tracking-tight text-slate-900">{totalCount}</p>
              <p className="mt-1 text-xs text-slate-500">Akun terdaftar dalam sistem</p>
            </div>
            <div className="flex size-11 items-center justify-center rounded-2xl bg-slate-100 text-slate-600">
              <svg viewBox="0 0 24 24" className="size-5" fill="none" aria-hidden="true">
                <path d="M17 20a4 4 0 0 0-8 0" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
                <path d="M12 12a4 4 0 1 0-4-4 4 4 0 0 0 4 4Z" stroke="currentColor" strokeWidth="1.8" />
              </svg>
            </div>
          </div>
        </Card>

        <Card className="border border-slate-100 bg-white/95 p-5 shadow-sm shadow-slate-200/60 backdrop-blur-sm">
          <div className="flex items-start justify-between gap-4">
            <div>
              <p className="text-sm font-medium text-slate-500">Role Admin</p>
              <p className="mt-2 text-3xl font-semibold tracking-tight text-blue-700">{adminCount}</p>
              <p className="mt-1 text-xs text-slate-500">Akses penuh sistem</p>
            </div>
            <div className="flex size-11 items-center justify-center rounded-2xl bg-blue-50 text-blue-700">
              <svg viewBox="0 0 24 24" className="size-5" fill="none" aria-hidden="true">
                <path
                  d="M12 3 5 6v5c0 4.4 3 8.5 7 10 4-1.5 7-5.6 7-10V6l-7-3Z"
                  stroke="currentColor"
                  strokeWidth="1.8"
                  strokeLinejoin="round"
                />
                <path d="M9.5 12.2 11.2 14l3.4-3.4" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </div>
          </div>
        </Card>

        <Card className="border border-slate-100 bg-white/95 p-5 shadow-sm shadow-slate-200/60 backdrop-blur-sm">
          <div className="flex items-start justify-between gap-4">
            <div>
              <p className="text-sm font-medium text-slate-500">Role User</p>
              <p className="mt-2 text-3xl font-semibold tracking-tight text-emerald-700">{userCount}</p>
              <p className="mt-1 text-xs text-slate-500">Akses dashboard pengguna</p>
            </div>
            <div className="flex size-11 items-center justify-center rounded-2xl bg-emerald-50 text-emerald-700">
              <svg viewBox="0 0 24 24" className="size-5" fill="none" aria-hidden="true">
                <path
                  d="M20 18a6 6 0 0 0-12 0"
                  stroke="currentColor"
                  strokeWidth="1.8"
                  strokeLinecap="round"
                />
                <path d="M14 11a3 3 0 1 0-3-3 3 3 0 0 0 3 3Z" stroke="currentColor" strokeWidth="1.8" />
              </svg>
            </div>
          </div>
        </Card>
      </div>

      {errorMessage && (
        <div className="rounded-2xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm font-medium text-rose-700 shadow-sm">
          {errorMessage}
        </div>
      )}

      <Card className="overflow-hidden border border-slate-100 bg-white/96 p-0 shadow-[0_18px_50px_-32px_rgba(15,23,42,0.28)] backdrop-blur-sm">
        <div className="flex flex-col gap-3 border-b border-slate-100 px-6 py-5 md:flex-row md:items-center md:justify-between">
          <div>
            <h2 className="text-lg font-semibold tracking-tight text-slate-900">Daftar Pengguna</h2>
            <p className="mt-1 text-sm text-slate-500">Kelola role dan informasi akun petugas.</p>
          </div>
          <div className="inline-flex items-center gap-2 self-start rounded-full border border-slate-200 bg-slate-50 px-3 py-1.5 text-xs font-semibold text-slate-600 md:self-auto">
            <span className="size-2 rounded-full bg-slate-400" />
            Total {totalLabel} User
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="min-w-245 w-full text-left text-sm">
            <thead className="bg-slate-50/80 text-[11px] uppercase tracking-[0.16em] text-slate-500">
              <tr>
                <th className="px-6 py-4 font-semibold">Nama</th>
                <th className="px-6 py-4 font-semibold">Email</th>
                <th className="px-6 py-4 font-semibold">Nomor WhatsApp</th>
                <th className="px-6 py-4 font-semibold">Role</th>
                <th className="px-6 py-4 font-semibold">Aksi</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 bg-white">
              {users.map((user) => (
                <tr key={user.id} className="transition-colors hover:bg-slate-50/80">
                  <td className="px-6 py-4">
                    <div className="font-medium text-slate-900">{user.name}</div>
                    <div className="mt-0.5 text-xs text-slate-500">ID {user.id.slice(0, 8)}…</div>
                  </td>
                  <td className="px-6 py-4 text-slate-600">{user.email}</td>
                  <td className="px-6 py-4 text-slate-600">{user.whatsappNumber ?? "-"}</td>
                  <td className="px-6 py-4">
                    <span
                      className={`inline-flex items-center rounded-full px-3 py-1 text-xs font-semibold ring-1 ring-inset ${
                        user.role === "admin"
                          ? "bg-blue-50 text-blue-700 ring-blue-100"
                          : "bg-emerald-50 text-emerald-700 ring-emerald-100"
                      }`}
                    >
                      {user.role === "admin" ? "Admin" : "User"}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex flex-wrap gap-2">
                      <button
                        type="button"
                        onClick={() => openEdit(user)}
                        className="inline-flex items-center gap-2 rounded-xl border border-slate-200 bg-white px-3.5 py-2 text-xs font-semibold text-slate-700 shadow-sm transition hover:border-slate-300 hover:bg-slate-50 hover:text-slate-900"
                      >
                        <svg viewBox="0 0 24 24" className="size-4" fill="none" aria-hidden="true">
                          <path d="M4 20h4l10-10-4-4L4 16v4Z" stroke="currentColor" strokeWidth="1.8" strokeLinejoin="round" />
                          <path d="m13 7 4 4" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
                        </svg>
                        Edit
                      </button>

                      <button
                        type="button"
                        onClick={() => setDeleteConfirm({ id: user.id, name: user.name })}
                        className="inline-flex items-center gap-2 rounded-xl border border-rose-200 bg-white px-3.5 py-2 text-xs font-semibold text-rose-600 shadow-sm transition hover:border-rose-300 hover:bg-rose-50 hover:text-rose-700"
                      >
                        <svg viewBox="0 0 24 24" className="size-4" fill="none" aria-hidden="true">
                          <path d="M4 7h16" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
                          <path d="M8 7V5.5A1.5 1.5 0 0 1 9.5 4h5A1.5 1.5 0 0 1 16 5.5V7m-7 0v11a1 1 0 0 0 1 1h4a1 1 0 0 0 1-1V7" stroke="currentColor" strokeWidth="1.8" strokeLinejoin="round" />
                          <path d="M10 11v4M14 11v4" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" />
                        </svg>
                        Hapus
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </Card>

      {loading && (
        <div className="rounded-2xl border border-slate-100 bg-white/90 px-4 py-3 text-sm text-slate-500 shadow-sm">
          Memuat data pengguna...
        </div>
      )}

      {savedMessage && (
        <div
          aria-live="polite"
          role="status"
          className={`fixed bottom-5 right-5 z-60 w-[min(92vw,22rem)] rounded-2xl border border-emerald-200 bg-white/95 p-4 shadow-[0_20px_60px_-24px_rgba(15,23,42,0.35)] backdrop-blur transition-all duration-200 ${
            toastVisible ? "translate-y-0 opacity-100" : "translate-y-2 opacity-0"
          }`}
        >
          <div className="flex items-start gap-3">
            <div className="mt-0.5 flex size-9 items-center justify-center rounded-full bg-emerald-100 text-emerald-700">
              <svg viewBox="0 0 24 24" className="size-5" fill="none" aria-hidden="true">
                <path d="m20 6-11 11-5-5" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round" />
              </svg>
            </div>
            <div className="min-w-0 flex-1">
              <p className="text-sm font-semibold text-slate-900">Berhasil</p>
              <p className="mt-1 text-sm leading-5 text-slate-600">{savedMessage}</p>
            </div>
          </div>
        </div>
      )}

      <Modal open={open} title={editingId ? "Edit User" : "Tambah User"} onClose={() => setOpen(false)}>
        <form onSubmit={submitUser} className="space-y-3">
          <label className="block text-sm text-slate-700">
            Nama Lengkap
            <input
              required
              value={form.name}
              onChange={(event) => setForm((prev) => ({ ...prev, name: event.target.value }))}
              className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
            />
          </label>

          <label className="block text-sm text-slate-700">
            Email
            <input
              type="email"
              required
              value={form.email}
              onChange={(event) => setForm((prev) => ({ ...prev, email: event.target.value }))}
              className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
            />
          </label>

          <label className="block text-sm text-slate-700">
            Nomor WhatsApp
            <input
              required
              value={form.whatsappNumber}
              onChange={(event) => setForm((prev) => ({ ...prev, whatsappNumber: event.target.value }))}
              className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
              placeholder="62812xxxxxxx"
            />
          </label>

          <label className="block text-sm text-slate-700">
            Password
            <input
              type="password"
              required={!editingId}
              value={form.password}
              onChange={(event) => setForm((prev) => ({ ...prev, password: event.target.value }))}
              className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
              placeholder={editingId ? "Kosongkan jika tidak diubah" : "Masukkan password"}
            />
            <p className="mt-1 text-xs text-slate-500">Password akan di-enkripsi menggunakan bcrypt di backend Nest.js.</p>
          </label>

          <label className="block text-sm text-slate-700">
            Instansi
            <input
              value={form.institution}
              onChange={(event) => setForm((prev) => ({ ...prev, institution: event.target.value }))}
              className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
              placeholder="Contoh: BPBD Kota"
            />
          </label>

          <label className="block text-sm text-slate-700">
            Pilih Role
            <select
              value={form.role}
              onChange={(event) => setForm((prev) => ({ ...prev, role: event.target.value as UserRole }))}
              className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
            >
              <option value="admin">Admin</option>
              <option value="user">User</option>
            </select>
          </label>

          <div className="rounded-lg border border-slate-200 bg-slate-50 p-3 text-xs text-slate-600">
            <p className="font-semibold text-slate-700">Hak Akses:</p>
            <p>Admin: akses penuh, termasuk threshold, hapus data, dan kelola pengguna.</p>
            <p>User: memantau dashboard pengguna, notifikasi, dan informasi darurat.</p>
          </div>

          <div className="flex justify-end gap-2 pt-1">
            <Button type="button" variant="secondary" onClick={() => setOpen(false)}>
              Batal
            </Button>
            <Button type="submit">Simpan User</Button>
          </div>
        </form>
      </Modal>

      <ConfirmDialog
        open={Boolean(deleteConfirm)}
        title="Hapus pengguna ini?"
        description={`Data akun ${deleteConfirm?.name ?? "pengguna"} akan dihapus dari sistem.`}
        confirmText="Ya, hapus"
        cancelText="Batal"
        onCancel={() => setDeleteConfirm(null)}
        onConfirm={() => {
          const selected = deleteConfirm;
          setDeleteConfirm(null);
          if (selected) {
            void deleteUser(selected.id);
          }
        }}
      />
    </main>
  );
}
