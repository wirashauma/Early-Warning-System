"use client";

import { useEffect } from "react";
import { getMessaging, isSupported, onMessage, type MessagePayload } from "firebase/messaging";
import app from "@/lib/firebase";

interface ForegroundNotificationPayload {
  title: string;
  body: string;
  icon: string;
  data: {
    url: string;
    alertId: string;
    severity: string;
    targetArea: string;
    sentAt: string;
  };
}

function resolveForegroundNotificationPayload(payload: MessagePayload): ForegroundNotificationPayload {
  return {
    title: payload.notification?.title ?? payload.data?.title ?? "Peringatan EWS Flood Guard",
    body:
      payload.notification?.body ??
      payload.data?.body ??
      payload.data?.message ??
      "Buka dashboard untuk melihat detail terbaru.",
    icon: "/favicon.ico",
    data: {
      url: payload.data?.route ?? "/user/dashboard",
      alertId: payload.data?.alertId ?? "",
      severity: payload.data?.severity ?? "",
      targetArea: payload.data?.targetArea ?? "",
      sentAt: payload.data?.sentAt ?? "",
    },
  };
}

export function usePushNotifications() {
  useEffect(() => {
    let unsubscribe = () => {};
    let active = true;

    const setupListener = async () => {
      if (typeof window === "undefined") {
        return;
      }

      if (!(await isSupported())) {
        return;
      }

      const messaging = getMessaging(app);

      unsubscribe = onMessage(messaging, (payload) => {
        // Foreground FCM messages do not auto-display an OS popup, so we raise one manually here.
        if (!active || typeof Notification === "undefined" || Notification.permission !== "granted") {
          return;
        }

        const notification = resolveForegroundNotificationPayload(payload);

        const browserNotification = new Notification(notification.title, {
          body: notification.body,
          icon: notification.icon,
          badge: notification.icon,
          data: notification.data,
        });

        browserNotification.onclick = () => {
          window.focus();
          window.location.href = notification.data.url;
        };
      });
    };

    void setupListener();

    return () => {
      active = false;
      unsubscribe();
    };
  }, []);
}