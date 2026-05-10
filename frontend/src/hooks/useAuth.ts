"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { signInWithPopup } from "firebase/auth";
import { auth, googleProvider, requestForToken } from "@/lib/firebase"; // Pastikan requestForToken di-import
import type { AppUser, BackendAuthUser } from "@/types/user";
import api from "@/lib/api";

const AUTH_USER_KEY = "ews_user_data";
const ACCESS_TOKEN_KEY = "ews_access_token";
const REFRESH_TOKEN_KEY = "ews_refresh_token";

function mapBackendRole(role: string): AppUser["role"] {
  const normalized = role.toUpperCase();
  if (normalized === "ADMIN") {
    return "admin";
  }
  return "user";
}

function toAppUser(user: BackendAuthUser): AppUser {
  return {
    id: user.id,
    name: user.name,
    email: user.email,
    avatar: user.avatar ?? null,
    institution: user.institution ?? null,
    role: mapBackendRole(String(user.role ?? "")),
  };
}

function setCookie(name: string, value: string, maxAgeSeconds: number) {
  document.cookie = `${name}=${encodeURIComponent(value)}; path=/; max-age=${maxAgeSeconds}; samesite=lax`;
}

function clearCookie(name: string) {
  document.cookie = `${name}=; path=/; max-age=0; samesite=lax`;
}

function syncAuthCookies(accessToken: string, refreshToken: string) {
  setCookie(ACCESS_TOKEN_KEY, accessToken, 60 * 60 * 24 * 7);
  setCookie(REFRESH_TOKEN_KEY, refreshToken, 60 * 60 * 24 * 30);
}

function clearAuthCookies() {
  clearCookie(ACCESS_TOKEN_KEY);
  clearCookie(REFRESH_TOKEN_KEY);
}

function persistAuth(accessToken: string, refreshToken: string, user: AppUser) {
  localStorage.setItem(ACCESS_TOKEN_KEY, String(accessToken));
  localStorage.setItem(REFRESH_TOKEN_KEY, String(refreshToken));
  localStorage.setItem(AUTH_USER_KEY, JSON.stringify(user));
  syncAuthCookies(accessToken, refreshToken);
}

function clearPersistedAuth() {
  localStorage.removeItem(AUTH_USER_KEY);
  localStorage.removeItem(ACCESS_TOKEN_KEY);
  localStorage.removeItem(REFRESH_TOKEN_KEY);
  clearAuthCookies();
}

export function useAuth() {
  const [user, setUser] = useState<AppUser | null>(null);
  const [loading, setLoading] = useState(true);

  // --- HELPER UNTUK MENGIRIM TOKEN FCM KE BACKEND ---
  const handlePushSubscription = async () => {
    try {
      // Meminta izin dan mengambil token FCM dari browser pengguna
      const fcmToken = await requestForToken();
      
      if (fcmToken) {
        console.info('[Push] FCM token:', fcmToken);
        // Mengirim token ke endpoint yang sudah disiapkan di alerts.controller.ts
        await api.post("/alerts/subscribe", { token: fcmToken });
        console.log("Berhasil mendaftarkan perangkat ke layanan Push Notification EWS.");
      }
    } catch (error) {
      console.error("Gagal melakukan push subscription:", error);
    }
  };

  // Hydrate local state lalu validasi sesi ke backend agar data user selalu real.
  useEffect(() => {
    let cancelled = false;

    const loadSession = async () => {
      try {
        const rawUser = localStorage.getItem(AUTH_USER_KEY);
        const token = localStorage.getItem(ACCESS_TOKEN_KEY);

        if (rawUser) {
          try {
            const parsed = JSON.parse(rawUser) as AppUser;
            if (!cancelled) {
              setUser(parsed);
            }
          } catch {
            localStorage.removeItem(AUTH_USER_KEY);
          }
        }

        if (!token) {
          if (!cancelled) {
            setUser(null);
            setLoading(false);
          }
          return;
        }

        setCookie(ACCESS_TOKEN_KEY, token, 60 * 60 * 24 * 7);

        const response = await api.get("/auth/me");
        const backendUser = response.data?.data as BackendAuthUser;
        const normalizedUser = toAppUser(backendUser);

        if (!cancelled) {
          setUser(normalizedUser);
          localStorage.setItem(AUTH_USER_KEY, JSON.stringify(normalizedUser));
          
          // Minta izin notifikasi jika sesi valid saat halaman dimuat
          handlePushSubscription();
        }
      } catch {
        clearPersistedAuth();
        if (!cancelled) {
          setUser(null);
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    };

    void loadSession();

    return () => {
      cancelled = true;
    };
  }, []);

  const login = useCallback(async (email: string, password: string) => {
    try {
      const response = await api.post("/auth/login", { email, password });
      const {
        accessToken,
        refreshToken,
        user: backendUser,
      } = response.data.data as {
        accessToken: string;
        refreshToken: string;
        user: BackendAuthUser;
      };

      const normalizedUser = toAppUser(backendUser);
      persistAuth(accessToken, refreshToken, normalizedUser);

      setUser(normalizedUser);
      
      // Setelah berhasil login manual, minta izin notifikasi
      handlePushSubscription();

      return { ok: true as const, user: normalizedUser };

    } catch (error: unknown) {
      const errorMessage =
        error instanceof Error ? error.message : "Login gagal, periksa koneksi.";

      return { ok: false as const, message: errorMessage };
    }
  }, []);

  const loginWithGoogle = useCallback(async () => {
    try {
      const result = await signInWithPopup(auth, googleProvider);
      const firebaseUser = result.user;

      const idToken = await firebaseUser.getIdToken();

      const response = await api.post("/auth/google-login", { idToken });
      const {
        accessToken,
        refreshToken,
        user: backendUser,
      } = response.data.data as {
        accessToken: string;
        refreshToken: string;
        user: BackendAuthUser;
      };

      const normalizedUser = toAppUser(backendUser);
      persistAuth(accessToken, refreshToken, normalizedUser);

      setUser(normalizedUser);
      
      // Setelah berhasil login Google, minta izin notifikasi
      handlePushSubscription();

      return { ok: true as const, user: normalizedUser };

    } catch (error: unknown) {
      const errorMessage =
        error instanceof Error ? error.message : "Google login gagal.";
      return { ok: false as const, message: errorMessage };
    }
  }, []);

  const logout = useCallback(async () => {
    try {
      // Panggil API logout untuk membersihkan session di server
      await api.post("/auth/logout");
    } catch {
      console.warn("Logout API failed, forcing local logout");
    } finally {
      // Bersihkan semua data persistensi lokal
      clearPersistedAuth();
      setUser(null);
      
      // SOLUSI KRITIS: Gunakan window.location.href untuk hard reload.
      // Ini memastikan state Next.js bersih total dan kembali ke Landing Page sebagai guest.
      window.location.href = "/";
    }
  }, []);

  // Sinkronkan perubahan profil ke state lokal agar komponen lain langsung ikut ter-update.
  const updateProfile = useCallback(
    (payload: Partial<Pick<AppUser, "name" | "email" | "avatar">>) => {
      setUser((prev) => {
        if (!prev) return prev;
        const nextUser: AppUser = { ...prev, ...payload };
        localStorage.setItem(AUTH_USER_KEY, JSON.stringify(nextUser));
        return nextUser;
      });
    },
    []
  );

  return useMemo(
    () => ({
      user,
      loading,
      isAuthenticated: Boolean(user),
      login,
      loginWithGoogle,
      logout,
      updateProfile,
    }),
    [user, loading, login, loginWithGoogle, logout, updateProfile],
  );
}