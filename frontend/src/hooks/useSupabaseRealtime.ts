"use client";

import { useEffect, useState, useRef, useCallback } from "react";
import { supabase } from "@/lib/supabaseClient";

export interface RealtimeAlert {
  id: string;
  title: string;
  message: string;
  severity: "INFO" | "WARNING" | "ALERT" | "DANGER";
  targetArea?: string | null;
  sentAt: string;
}

export interface RealtimeSensor {
  id: string;
  sensor_id: string;
  name: string;
  connectivity: "ONLINE" | "OFFLINE" | "MAINTENANCE";
  is_active: boolean;
  last_active_at?: string | null;
}

interface UseSupabaseRealtimeOptions {
  onSensorChange?: (updatedSensor: RealtimeSensor) => void;
  sirenUrl?: string;
}

export function useSupabaseRealtime(options: UseSupabaseRealtimeOptions = {}) {
  const { onSensorChange, sirenUrl = "/siren.mp3" } = options;
  
  const [activeAlert, setActiveAlert] = useState<RealtimeAlert | null>(null);
  const [isSirenPlaying, setIsSirenPlaying] = useState(false);
  const [autoplayBlocked, setAutoplayBlocked] = useState(false);
  
  const audioRef = useRef<HTMLAudioElement | null>(null);

  // Initialize Audio
  useEffect(() => {
    if (typeof window !== "undefined") {
      const audio = new Audio(sirenUrl);
      audio.loop = true;
      audioRef.current = audio;

      // Sync playing state from audio events
      audio.onplay = () => {
        setIsSirenPlaying(true);
        setAutoplayBlocked(false);
      };
      audio.onpause = () => setIsSirenPlaying(false);

      return () => {
        audio.pause();
        audioRef.current = null;
      };
    }
  }, [sirenUrl]);

  // Play Siren Helper
  const playSiren = useCallback(async () => {
    if (audioRef.current) {
      try {
        await audioRef.current.play();
        setIsSirenPlaying(true);
        setAutoplayBlocked(false);
      } catch (err: any) {
        console.warn("⚠️ Autoplay blocked by browser. User interaction is required to play sound:", err);
        setAutoplayBlocked(true);
        setIsSirenPlaying(false);
      }
    }
  }, []);

  // Stop Siren Helper
  const stopSiren = useCallback(() => {
    if (audioRef.current) {
      audioRef.current.pause();
      audioRef.current.currentTime = 0;
      setIsSirenPlaying(false);
      setAutoplayBlocked(false);
    }
  }, []);

  // Triggered when close button clicked
  const dismissAlert = useCallback(() => {
    setActiveAlert(null);
    stopSiren();
  }, [stopSiren]);

  useEffect(() => {
    // 1. Subscribe to 'alerts' table INSERT events
    const alertsChannel = supabase
      .channel("public-alerts-realtime")
      .on(
        "postgres_changes",
        {
          event: "INSERT",
          schema: "public",
          table: "alerts",
        },
        (payload) => {
          const newAlert = payload.new as RealtimeAlert;
          console.log("🔥 Realtime Alert Received:", newAlert);

          if (newAlert.severity === "DANGER") {
            setActiveAlert(newAlert);
            void playSiren();
          }
        }
      )
      .subscribe((status) => {
        console.log(`Supabase Alerts channel status: ${status}`);
      });

    // 2. Subscribe to 'sensors' table UPDATE events
    const sensorsChannel = supabase
      .channel("public-sensors-realtime")
      .on(
        "postgres_changes",
        {
          event: "UPDATE",
          schema: "public",
          table: "sensors",
        },
        (payload) => {
          const updatedSensor = payload.new as RealtimeSensor;
          console.log("📡 Realtime Sensor Updated:", updatedSensor);

          if (onSensorChange) {
            onSensorChange(updatedSensor);
          }
        }
      )
      .subscribe((status) => {
        console.log(`Supabase Sensors channel status: ${status}`);
      });

    // Cleanup subscriptions on unmount
    return () => {
      void supabase.removeChannel(alertsChannel);
      void supabase.removeChannel(sensorsChannel);
    };
  }, [onSensorChange, playSiren]);

  return {
    activeAlert,
    isSirenPlaying,
    autoplayBlocked,
    playSiren,
    stopSiren,
    dismissAlert,
  };
}
