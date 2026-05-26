"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import api from "@/lib/api";
import type { UserNotificationItem } from "@/types/user-notification";

interface ApiAlertItem {
  id: string;
  title: string;
  message: string;
  severity: "INFO" | "WARNING" | "DANGER";
  targetArea?: string | null;
  channels?: string[];
  sourceType?: "ADMIN" | "SYSTEM";
  user?: {
    name?: string | null;
  } | null;
  sentAt: string;
}

function mapSeverityToRiskLevel(severity: ApiAlertItem["severity"]): UserNotificationItem["riskLevel"] {
  if (severity === "DANGER") {
    return "red";
  }

  if (severity === "WARNING") {
    return "orange";
  }

  return "yellow";
}

function mapSeverityToGuideHref(severity: ApiAlertItem["severity"]): string {
  if (severity === "DANGER") {
    return "/user/education#aksi-merah";
  }

  if (severity === "WARNING") {
    return "/user/education#aksi-oren";
  }

  return "/user/education#aksi-kuning";
}

function isNotificationRead(sentAt: string, notificationReadAt: string | null) {
  if (!notificationReadAt) {
    return false;
  }

  const sentAtTime = new Date(sentAt).getTime();
  const readAtTime = new Date(notificationReadAt).getTime();

  return Number.isFinite(sentAtTime) && Number.isFinite(readAtTime) && sentAtTime <= readAtTime;
}

function getErrorMessage(error: unknown) {
  return error instanceof Error ? error.message : "Gagal memuat notifikasi.";
}

export function useUserNotifications() {
  const [items, setItems] = useState<UserNotificationItem[]>([]);
  const [notificationReadAt, setNotificationReadAt] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isUpdating, setIsUpdating] = useState(false);

  const loadNotifications = useCallback(async () => {
    setError(null);
    setLoading(true);

    try {
      const [meResponse, alertsResponse] = await Promise.all([
        api.get("/auth/me"),
        api.get("/alerts/history", {
          params: { page: 1, limit: 100 },
        }),
      ]);

      const backendUser = meResponse.data?.data as { notificationReadAt?: string | null } | undefined;
      const readAt = backendUser?.notificationReadAt ?? null;
      setNotificationReadAt(readAt);

      const rows = (alertsResponse.data?.data?.items ?? []) as ApiAlertItem[];

      const mapped: UserNotificationItem[] = rows.map((row) => {
        const riskLevel = mapSeverityToRiskLevel(row.severity);
        const sourceType = row.sourceType ?? (row.user?.name ? "ADMIN" : "SYSTEM");

        return {
          id: row.id,
          sensorId: row.targetArea || "WILAYAH",
          sensorName: row.targetArea || "Wilayah Umum",
          levelCm: 0,
          riskLevel,
          title: row.title,
          message: row.message,
          createdAt: row.sentAt,
          isRead: isNotificationRead(row.sentAt, readAt),
          guideHref: mapSeverityToGuideHref(row.severity),
          senderName: row.user?.name?.trim() || (sourceType === "ADMIN" ? "Admin EWS" : "Sistem EWS"),
          sourceType,
          channels: row.channels ?? [],
        };
      });

      setItems(mapped);
    } catch (error) {
      setError(getErrorMessage(error));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadNotifications();
  }, [loadNotifications]);

  const unreadCount = useMemo(
    () => items.filter((item) => !item.isRead).length,
    [items],
  );

  const markAllAsRead = useCallback(async () => {
    setIsUpdating(true);
    setError(null);

    try {
      const response = await api.put("/auth/notifications/read-all");
      const readAt = response.data?.data?.notificationReadAt ?? new Date().toISOString();

      setNotificationReadAt(readAt);
      setItems((prev) => prev.map((item) => ({ ...item, isRead: true })));
    } catch (error) {
      setError(getErrorMessage(error));
      throw error;
    } finally {
      setIsUpdating(false);
    }
  }, []);

  const markAsRead = useCallback(async (_id: string) => {
    await markAllAsRead();
  }, [markAllAsRead]);

  return {
    notifications: items,
    unreadCount,
    markAsRead,
    markAllAsRead,
    loading,
    error,
    isUpdating,
    reload: loadNotifications,
    notificationReadAt,
  };
}
