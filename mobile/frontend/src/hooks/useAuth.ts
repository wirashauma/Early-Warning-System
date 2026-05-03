"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { dummyAuthAccounts } from "@/constants";
import type { AppUser } from "@/types/user";

const AUTH_KEY = "ews_admin_user";

export function useAuth() {
  const [user, setUser] = useState<AppUser | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    try {
      const raw = localStorage.getItem(AUTH_KEY);
      if (raw) {
        setUser(JSON.parse(raw) as AppUser);
      }
    } finally {
      setLoading(false);
    }
  }, []);

  const login = useCallback((email: string, password: string) => {
    const account = dummyAuthAccounts.find(
      (item) => item.email.toLowerCase() === email.trim().toLowerCase() && item.password === password,
    );

    if (!account) {
      return { ok: false as const, message: "Email atau password dummy tidak cocok." };
    }

    const nextUser: AppUser = {
      id: `ADM-${account.email.split("@")[0].toUpperCase()}`,
      name: account.name,
      email: account.email,
      role: account.role,
    };

    localStorage.setItem(AUTH_KEY, JSON.stringify(nextUser));
    setUser(nextUser);

    return { ok: true as const, user: nextUser };
  }, []);

  const logout = useCallback(() => {
    localStorage.removeItem(AUTH_KEY);
    setUser(null);
  }, []);

  return useMemo(
    () => ({
      user,
      loading,
      isAuthenticated: Boolean(user),
      login,
      logout,
      dummyAccounts: dummyAuthAccounts,
    }),
    [user, loading, login, logout],
  );
}
