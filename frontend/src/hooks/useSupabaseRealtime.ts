"use client";

import { useEffect, useState, useRef, useCallback } from "react";
import { supabase } from "@/lib/supabaseClient";
import api from "@/lib/api";

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
  const sensorMapRef = useRef<Record<string, string>>({});

  // Fetch all sensors on mount to build a stable database ID (UUID) -> human-readable sensorId mapping
  useEffect(() => {
    let active = true;
    const fetchSensors = async () => {
      try {
        const response = await api.get("/sensors");
        const payload = response.data?.data;
        const items = (Array.isArray(payload)
          ? payload
          : payload?.items ?? []) as Array<{ id: string; sensorId: string }>;
        
        if (active) {
          const mapping: Record<string, string> = {};
          items.forEach((sensor) => {
            if (sensor.id && sensor.sensorId) {
              mapping[sensor.id] = sensor.sensorId;
            }
          });
          sensorMapRef.current = mapping;
        }
      } catch (err) {
        console.error("Failed to load sensors map in useSupabaseRealtime:", err);
      }
    };
    
    void fetchSensors();
    return () => {
      active = false;
    };
  }, []);

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

          if (newAlert.severity === "DANGER") {
            setActiveAlert(newAlert);
            void playSiren();
          }
        }
      )
      .subscribe();

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

          if (onSensorChange) {
            onSensorChange(updatedSensor);
          }
        }
      )
      .subscribe();

    // 3. Subscribe to 'water_level_logs' table INSERT events
    const waterLevelLogsChannel = supabase
      .channel("public-water-level-logs-realtime")
      .on(
        "postgres_changes",
        {
          event: "INSERT",
          schema: "public",
          table: "water_level_logs",
        },
        (payload) => {
          const newLog = payload.new;
          if (typeof window !== "undefined") {
            const sensorId = sensorMapRef.current[newLog.sensor_id] || "";
            window.dispatchEvent(
              new CustomEvent("sensorTelemetryUpdated", {
                detail: {
                  sensorUuid: newLog.sensor_id,
                  sensorId,
                  waterLevel: Number(newLog.water_level),
                  status: newLog.status,
                  recordedAt: newLog.recorded_at,
                },
              })
            );
          }
        }
      )
      .subscribe();

    // 4. Subscribe to 'rainfall_logs' table INSERT events
    const rainfallLogsChannel = supabase
      .channel("public-rainfall-logs-realtime")
      .on(
        "postgres_changes",
        {
          event: "INSERT",
          schema: "public",
          table: "rainfall_logs",
        },
        (payload) => {
          const newLog = payload.new;
          if (typeof window !== "undefined") {
            const sensorId = sensorMapRef.current[newLog.sensor_id] || "";
            window.dispatchEvent(
              new CustomEvent("sensorTelemetryUpdated", {
                detail: {
                  sensorUuid: newLog.sensor_id,
                  sensorId,
                  rainfall: Number(newLog.rainfall),
                  status: newLog.intensity,
                  recordedAt: newLog.recorded_at,
                },
              })
            );
          }
        }
      )
      .subscribe();

    // 5. Subscribe to 'flow_rate_logs' table INSERT events
    const flowRateLogsChannel = supabase
      .channel("public-flow-rate-logs-realtime")
      .on(
        "postgres_changes",
        {
          event: "INSERT",
          schema: "public",
          table: "flow_rate_logs",
        },
        (payload) => {
          const newLog = payload.new;
          if (typeof window !== "undefined") {
            const sensorId = sensorMapRef.current[newLog.sensor_id] || "";
            window.dispatchEvent(
              new CustomEvent("sensorTelemetryUpdated", {
                detail: {
                  sensorUuid: newLog.sensor_id,
                  sensorId,
                  flowRate: Number(newLog.flow_rate),
                  recordedAt: newLog.recorded_at,
                },
              })
            );
          }
        }
      )
      .subscribe();

    // Cleanup subscriptions on unmount
    return () => {
      void supabase.removeChannel(alertsChannel);
      void supabase.removeChannel(sensorsChannel);
      void supabase.removeChannel(waterLevelLogsChannel);
      void supabase.removeChannel(rainfallLogsChannel);
      void supabase.removeChannel(flowRateLogsChannel);
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
