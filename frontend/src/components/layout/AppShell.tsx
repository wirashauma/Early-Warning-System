"use client";

import type { PropsWithChildren } from "react";
import { usePathname } from "next/navigation";
import { Footer } from "@/components/layout/Footer";
import { Navbar } from "@/components/layout/Navbar";
import { usePushNotifications } from "@/hooks/usePushNotifications";
import { useSupabaseRealtime } from "@/hooks/useSupabaseRealtime";
import { SirenAlertModal } from "@/components/SirenAlertModal";

const noChromeRoutes = new Set(["/login", "/register"]);

export function AppShell({ children }: PropsWithChildren) {
  const pathname = usePathname();
  const isAdminRoute = pathname.startsWith("/admin");
  const isUserRoute = pathname.startsWith("/user");
  const isNoChromeRoute = noChromeRoutes.has(pathname) || isAdminRoute;

  // Foreground FCM messages are handled here so the active tab still triggers a native OS popup.
  usePushNotifications();

  // Supabase Realtime Subscriber for global alerts and sensor connectivity status
  const {
    activeAlert,
    isSirenPlaying,
    autoplayBlocked,
    playSiren,
    stopSiren,
    dismissAlert,
  } = useSupabaseRealtime({
    onSensorChange: (updatedSensor) => {
      if (typeof window !== "undefined") {
        window.dispatchEvent(
          new CustomEvent("sensorConnectivityUpdated", { detail: updatedSensor })
        );
      }
    },
  });

  if (isNoChromeRoute) {
    return (
      <>
        {children}
        <SirenAlertModal
          alert={activeAlert}
          isSirenPlaying={isSirenPlaying}
          autoplayBlocked={autoplayBlocked}
          onPlaySiren={playSiren}
          onStopSiren={stopSiren}
          onDismiss={dismissAlert}
        />
      </>
    );
  }

  return (
    <div className="flex min-h-screen flex-col">
      <Navbar />
      <div className="flex-1">{children}</div>
      {!isUserRoute && <Footer />}
      <SirenAlertModal
        alert={activeAlert}
        isSirenPlaying={isSirenPlaying}
        autoplayBlocked={autoplayBlocked}
        onPlaySiren={playSiren}
        onStopSiren={stopSiren}
        onDismiss={dismissAlert}
      />
    </div>
  );
}
