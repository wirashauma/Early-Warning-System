"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { io, type Socket } from "socket.io-client";
import { PRIMARY_SENSOR_ID, WS_URL, API_URL } from "@/constants";
import api from "@/lib/api";
import type { Sensor } from "@/types/sensor";
import type { LiveWaterLevel, WaterLevelPoint } from "@/types/water-level";

interface UseWaterLevelOptions {
  sensorId?: string;
  refreshMs?: number;
  showAll?: boolean;
}

const DEFAULT_REFRESH_MS = 5_000;
const HISTORY_HOURS = 7 * 24;
const MAX_HISTORY_POINTS = 500;
const STABLE_FALLBACK_TIMESTAMP = "2026-01-01T00:00:00.000Z";

interface ApiSensor {
  id: string;
  sensorId: string;
  name: string;
  type?: "WATER_LEVEL" | "RAINFALL" | "FLOW_RATE";
  latitude: number;
  longitude: number;
  batteryLevel: number | null;
  connectivity: string;
  lastActiveAt: string | null;
}

interface ApiWaterCurrent {
  sensorId: string;
  sensorName: string;
  waterLevel: number;
  status: string;
  recordedAt: string;
}

interface ApiRainfallCurrent {
  sensorId: string;
  rainfall: number;
  recordedAt?: string;
}

interface ApiWaterHistory {
  sensorId: string;
  waterLevel: number;
  recordedAt: string;
}

interface ApiRainHistory {
  sensorId: string;
  rainfall: number;
  recordedAt: string;
}

interface ApiFlowCurrent {
  sensorId: string;
  flowRate: number;
}

interface ApiFlowHistory {
  sensorId: string;
  flowRate: number;
  recordedAt: string;
}

interface RealtimeSensorUpdatePayload {
  sensorId: string;
  sensorName?: string;
  waterLevel?: number;
  rainfall?: number;
  flowRate?: number;
  status?: string;
  batteryLevel?: number | null;
  connectivity?: string;
  latitude?: number;
  longitude?: number;
  lastActiveAt?: string;
  recordedAt?: string;
}

function mapStatus(status?: string) {
  const normalized = status?.toUpperCase();

  if (normalized === "DANGER") return "danger" as const;
  if (normalized === "WARNING") return "alert" as const;
  if (normalized === "ALERT") return "alert" as const;
  if (normalized === "SAFE") return "safe" as const;
  return "safe" as const;
}

function mapConnectivity(connectivity?: string) {
  return connectivity?.toUpperCase() === "ONLINE" ? "online" : "offline";
}

function toIsoNow() {
  return new Date().toISOString();
}

export function useWaterLevel(options: UseWaterLevelOptions = {}) {
  const { sensorId, refreshMs = DEFAULT_REFRESH_MS, showAll = false } = options;
  const [historyBySensor, setHistoryBySensor] = useState<Record<string, WaterLevelPoint[]>>({});
  const [latestBySensor, setLatestBySensor] = useState<Record<string, LiveWaterLevel>>({});
  const [historyVersion, setHistoryVersion] = useState(0);
  const [sensorsSnapshot, setSensorsSnapshot] = useState<Sensor[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const isMountedRef = useRef(true);
  const waterSensorIdsRef = useRef<Set<string>>(new Set());
  const sensorUuidMapRef = useRef<Record<string, string>>({});

  useEffect(() => {
    isMountedRef.current = true;
    return () => {
      isMountedRef.current = false;
    };
  }, []);

  const loadCurrent = useCallback(async () => {
    try {
      setIsLoading(true);
      setError(null);
      const [sensorsResp, waterResp, rainfallResp, flowResp] = await Promise.all([
        api.get("/sensors"),
        api.get("/water-levels/current"),
        api.get("/rainfall/current"),
        api.get("/flow-rate/current"),
      ]);

      if (!isMountedRef.current) {
        return;
      }

      const sensorPayload = sensorsResp.data?.data;
      const sensors = (Array.isArray(sensorPayload)
        ? sensorPayload
        : sensorPayload?.items ?? []) as ApiSensor[];

      const uuidMap: Record<string, string> = {};
      sensors.forEach((s) => {
        if (s.id && s.sensorId) {
          uuidMap[s.id] = s.sensorId;
        }
      });
      sensorUuidMapRef.current = uuidMap;

      const waterRows = (waterResp.data?.data ?? []) as ApiWaterCurrent[];
      const rainfallRows = (rainfallResp.data?.data ?? []) as ApiRainfallCurrent[];
      const flowRows = (flowResp.data?.data ?? []) as ApiFlowCurrent[];

      const waterBySensorId = new Map(waterRows.map((row) => [row.sensorId, row]));
      const rainfallBySensorId = new Map(rainfallRows.map((row) => [row.sensorId, row]));
      const flowBySensorId = new Map(flowRows.map((row) => [row.sensorId, row]));

      const normalizedPrimaryId = showAll ? "" : PRIMARY_SENSOR_ID.trim();
      const primaryFiltered = normalizedPrimaryId
        ? sensors.filter((sensor) => sensor.sensorId === normalizedPrimaryId)
        : sensors;
      const effectiveSensors = primaryFiltered.length > 0 ? primaryFiltered : sensors;
      const effectiveSensorIds = new Set(effectiveSensors.map((sensor) => sensor.sensorId));

      waterSensorIdsRef.current = new Set(
        waterRows
          .map((row) => row.sensorId)
          .filter((id) => effectiveSensorIds.has(id)),
      );

      const nextSensors: Sensor[] = effectiveSensors.map((sensor) => {
        const water = waterBySensorId.get(sensor.sensorId);
        const rain = rainfallBySensorId.get(sensor.sensorId);
        const flow = flowBySensorId.get(sensor.sensorId);
        const lastSeenAt = sensor.lastActiveAt ?? water?.recordedAt ?? rain?.recordedAt ?? null;
        const updatedAt = lastSeenAt ?? STABLE_FALLBACK_TIMESTAMP;
        return {
          id: sensor.sensorId,
          name: sensor.name,
          riverName: sensor.name,
          type: sensor.type,
          latitude: sensor.latitude,
          longitude: sensor.longitude,
          connectivity: mapConnectivity(sensor.connectivity),
          batteryPercent: sensor.batteryLevel ?? 0,
          lastLevelCm: water?.waterLevel ?? 0,
          hasWaterLevelData: Boolean(water),
          lastRainfall: rain?.rainfall ?? 0,
          hasRainfallData: Boolean(rain),
          lastFlowRate: flow?.flowRate ?? 0,
          hasFlowRateData: Boolean(flow),
          lastSeenAt,
          status: mapStatus(water?.status),
          updatedAt,
        };
      });

      setSensorsSnapshot(nextSensors);

      const nextLiveBySensor = nextSensors.reduce<Record<string, LiveWaterLevel>>((acc, sensor) => {
        const rain = rainfallBySensorId.get(sensor.id);
        const flow = flowBySensorId.get(sensor.id);
        acc[sensor.id] = {
          sensorId: sensor.id,
          sensorName: sensor.name,
          levelCm: sensor.lastLevelCm,
          rainfallMm: rain?.rainfall ?? 0,
          flowRateLpm: flow?.flowRate ?? 0,
          status: sensor.status,
          updatedAt: sensor.updatedAt,
        };
        return acc;
      }, {});

      setLatestBySensor(nextLiveBySensor);
      setIsLoading(false);
    } catch (e) {
      console.error("Gagal memuat data sensor saat polling:", e);
      if (isMountedRef.current) {
        setSensorsSnapshot([]);
        setLatestBySensor({});
        setError("Gagal memuat data sensor. Silakan coba lagi.");
        setIsLoading(false);
      }
    }
  }, []);

  useEffect(() => {
    const applyRealtimeUpdate = (payload: RealtimeSensorUpdatePayload) => {
      if (!payload.sensorId) {
        return;
      }

      const timestamp = payload.recordedAt ?? payload.lastActiveAt ?? toIsoNow();

      // Functional updates keep the merge atomic and avoid stale closure/race-condition issues.
      setSensorsSnapshot((prev) => {
        const sensorIndex = prev.findIndex((sensor) => sensor.id === payload.sensorId);

        if (sensorIndex === -1) {
          return prev;
        }

        const next = [...prev];
        const currentSensor = next[sensorIndex];

        next[sensorIndex] = {
          ...currentSensor,
          name: payload.sensorName ?? currentSensor.name,
          riverName: payload.sensorName ?? currentSensor.riverName,
          latitude: payload.latitude ?? currentSensor.latitude,
          longitude: payload.longitude ?? currentSensor.longitude,
          connectivity:
            payload.connectivity !== undefined
              ? mapConnectivity(payload.connectivity)
              : currentSensor.connectivity,
          batteryPercent: payload.batteryLevel ?? currentSensor.batteryPercent,
          lastLevelCm: payload.waterLevel ?? currentSensor.lastLevelCm,
          hasWaterLevelData:
            payload.waterLevel !== undefined && payload.waterLevel !== null
              ? true
              : currentSensor.hasWaterLevelData,
          lastRainfall: payload.rainfall ?? currentSensor.lastRainfall,
          hasRainfallData:
            payload.rainfall !== undefined && payload.rainfall !== null
              ? true
              : currentSensor.hasRainfallData,
          lastFlowRate: payload.flowRate ?? currentSensor.lastFlowRate,
          hasFlowRateData:
            payload.flowRate !== undefined && payload.flowRate !== null
              ? true
              : currentSensor.hasFlowRateData,
          lastSeenAt: timestamp,
          status: payload.status ? mapStatus(payload.status) : currentSensor.status,
          updatedAt: timestamp,
        };

        return next;
      });

      setLatestBySensor((prev) => {
        const currentLive = prev[payload.sensorId];

        if (!currentLive) {
          return prev;
        }

        return {
          ...prev,
          [payload.sensorId]: {
            sensorId: payload.sensorId,
            sensorName: payload.sensorName ?? currentLive.sensorName,
            levelCm: payload.waterLevel ?? currentLive.levelCm,
            rainfallMm: payload.rainfall ?? currentLive.rainfallMm,
            flowRateLpm: payload.flowRate ?? currentLive.flowRateLpm,
            status: payload.status ? mapStatus(payload.status) : currentLive.status,
            updatedAt: timestamp,
          },
        };
      });

      setHistoryBySensor((prev) => {
        const currentHistory = prev[payload.sensorId] ?? [];
        
        // Find if there is an existing point with the exact same timestamp
        const existingIndex = currentHistory.findIndex((p) => p.timestamp === timestamp);

        let newHistory = [...currentHistory];
        if (existingIndex !== -1) {
          // Merge updates into the existing point
          newHistory[existingIndex] = {
            ...newHistory[existingIndex],
            levelCm: payload.waterLevel !== undefined ? payload.waterLevel : newHistory[existingIndex].levelCm,
            rainfallMm: payload.rainfall !== undefined ? payload.rainfall : newHistory[existingIndex].rainfallMm,
            flowRateLpm: payload.flowRate !== undefined ? payload.flowRate : newHistory[existingIndex].flowRateLpm,
          };
        } else {
          // Get the last known values as fallback
          const lastPoint = currentHistory[currentHistory.length - 1];
          const newPoint: WaterLevelPoint = {
            timestamp,
            levelCm: payload.waterLevel ?? lastPoint?.levelCm ?? 0,
            rainfallMm: payload.rainfall ?? lastPoint?.rainfallMm ?? 0,
            flowRateLpm: payload.flowRate ?? lastPoint?.flowRateLpm ?? 0,
            sensorId: payload.sensorId,
          };
          newHistory.push(newPoint);
        }

        // Sort strictly chronologically to prevent visual shifts or backwards loops!
        newHistory.sort((a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime());

        // Rolling window: trim old points to keep chart x-axis stable
        if (newHistory.length > MAX_HISTORY_POINTS) {
          newHistory = newHistory.slice(newHistory.length - MAX_HISTORY_POINTS);
        }

        return {
          ...prev,
          [payload.sensorId]: newHistory,
        };
      });
    };

    // 1. Establish SSE EventSource connection
    const directApiUrl = WS_URL.replace(/^ws/, "http");
    const streamUrl = `${directApiUrl}/api/sensors/stream`;

    console.log("⚡ SSE Connecting to stream:", streamUrl);
    const eventSource = new EventSource(streamUrl);
    let lastMessageTime = Date.now();

    eventSource.onopen = () => {
      console.log("🟢 [useWaterLevel SSE] Connection successfully opened to:", streamUrl);
    };

    eventSource.onmessage = (event) => {
      try {
        lastMessageTime = Date.now();
        const data = JSON.parse(event.data);
        console.log("⚡ [useWaterLevel SSE] Real-Time Event received:", data);

        if (data.water) {
          applyRealtimeUpdate({
            sensorId: data.water.sensorId,
            waterLevel: data.water.waterLevel,
            status: data.water.status,
            recordedAt: data.recordedAt,
          });
        }
        if (data.rainfall) {
          applyRealtimeUpdate({
            sensorId: data.rainfall.sensorId,
            rainfall: data.rainfall.rainfall,
            status: data.rainfall.intensity,
            recordedAt: data.recordedAt,
          });
        }
        if (data.flowRate) {
          applyRealtimeUpdate({
            sensorId: data.flowRate.sensorId,
            flowRate: data.flowRate.flowRate,
            recordedAt: data.recordedAt,
          });
        }
      } catch (err) {
        console.error("❌ [useWaterLevel SSE] Error parsing message:", err);
      }
    };

    eventSource.onerror = (err) => {
      console.warn("⚠️ [useWaterLevel SSE] Connection encountered error or closed. Reconnecting...", err);
    };

    // Listen to custom Supabase Realtime connectivity update events
    const handleRealtimeSensorUpdate = (e: Event) => {
      const customEvent = e as CustomEvent<{ sensor_id: string; connectivity: string }>;
      if (customEvent?.detail?.sensor_id) {
        const { sensor_id, connectivity } = customEvent.detail;
        const mappedConn = connectivity.toLowerCase() === "online" ? "online" : "offline";
        setSensorsSnapshot((prev) =>
          prev.map((sensor) =>
            sensor.id === sensor_id ? { ...sensor, connectivity: mappedConn } : sensor
          )
        );
      }
      void loadCurrent();
    };

    // Listen to custom Supabase Realtime telemetry update events
    const handleRealtimeTelemetry = (e: Event) => {
      const customEvent = e as CustomEvent<{
        sensorUuid: string;
        sensorId: string;
        waterLevel?: number;
        rainfall?: number;
        flowRate?: number;
        status?: string;
        recordedAt: string;
      }>;
      
      if (!customEvent.detail) return;
      const { sensorUuid, sensorId, waterLevel, rainfall, flowRate, status, recordedAt } = customEvent.detail;
      
      const resolvedSensorId = sensorId || sensorUuidMapRef.current[sensorUuid];
      
      if (resolvedSensorId) {
        applyRealtimeUpdate({
          sensorId: resolvedSensorId,
          waterLevel,
          rainfall,
          flowRate,
          status,
          recordedAt,
        });
      }
    };

    if (typeof window !== "undefined") {
      window.addEventListener("sensorConnectivityUpdated", handleRealtimeSensorUpdate);
      window.addEventListener("sensorTelemetryUpdated", handleRealtimeTelemetry);
    }

    void loadCurrent();
    
    // Smooth fallback polling (reduced rate to 30s to respect SSE stream)
    const timer = window.setInterval(() => {
      void loadCurrent();
    }, Math.max(refreshMs, 30_000));

    // Active 3s polling fallback: if no SSE events received for > 8 seconds, poll backend
    const fallbackTimer = window.setInterval(() => {
      const timeSinceLastMessage = Date.now() - lastMessageTime;
      if (timeSinceLastMessage > 8000) {
        void loadCurrent();
        setHistoryVersion((v) => v + 1);
      }
    }, 3000);

    return () => {
      window.clearInterval(timer);
      window.clearInterval(fallbackTimer);
      eventSource.close();
      if (typeof window !== "undefined") {
        window.removeEventListener("sensorConnectivityUpdated", handleRealtimeSensorUpdate);
        window.removeEventListener("sensorTelemetryUpdated", handleRealtimeTelemetry);
      }
    };
  }, [loadCurrent, refreshMs]);

  const preferredWaterSensorId =
    sensorsSnapshot.find((sensor) => waterSensorIdsRef.current.has(sensor.id))?.id ?? "";
  const activeSensorId =
    sensorId && latestBySensor[sensorId]
      ? sensorId
      : preferredWaterSensorId || sensorsSnapshot[0]?.id || "";
  const activeSensor = sensorsSnapshot.find((sensor) => sensor.id === activeSensorId);
  const isRainSensor = activeSensor?.type === "RAINFALL";
  const isFlowSensor = activeSensor?.type === "FLOW_RATE";

  // Stable ref to access latestBySensor without triggering history re-fetches
  const latestBySensorRef = useRef(latestBySensor);
  useEffect(() => {
    latestBySensorRef.current = latestBySensor;
  }, [latestBySensor]);

  useEffect(() => {
    const activeId = activeSensorId;

    if (!activeId) {
      return;
    }

    let cancelled = false;
    const loadHistory = async () => {
      try {
        const endDate = new Date();
        const startDate = new Date(endDate.getTime() - HISTORY_HOURS * 60 * 60 * 1000);

        const historyResp = await api.get(
          isRainSensor ? "/rainfall/history" : isFlowSensor ? "/flow-rate/history" : "/water-levels/history",
          {
          params: {
            sensorId: activeId,
            startDate: startDate.toISOString(),
            endDate: endDate.toISOString(),
            interval: "hourly",
          },
          },
        );

        if (cancelled) {
          return;
        }

        const historyPayload = historyResp.data?.data;
        const rows = (Array.isArray(historyPayload)
          ? historyPayload
          : historyPayload?.items ?? []) as Array<
          ApiWaterHistory & Partial<ApiRainHistory> & Partial<ApiFlowHistory>
        >;
        const latestRain = latestBySensorRef.current[activeId]?.rainfallMm ?? 0;

        const sortedRows = [...rows].sort(
          (a, b) => new Date(a.recordedAt).getTime() - new Date(b.recordedAt).getTime(),
        );

        const mapped: WaterLevelPoint[] = sortedRows.map((row) => {
          const levelCm = isRainSensor || isFlowSensor ? 0 : row.waterLevel ?? 0;
          const rainfallMm = isRainSensor ? row.rainfall ?? 0 : latestRain;
          const derivedFlow = Number((Math.max(0.3, levelCm / 220 + rainfallMm / 35)).toFixed(2));
          return {
            timestamp: row.recordedAt,
            levelCm,
            rainfallMm,
            flowRateLpm: row.flowRate ?? derivedFlow,
            sensorId: row.sensorId,
          };
        });

        setHistoryBySensor((prev) => ({
          ...prev,
          [activeId]: mapped,
        }));
      } catch {
        if (!cancelled) {
          setHistoryBySensor((prev) => ({ ...prev, [activeId]: [] }));
        }
      }
    };

    // Initial load
    void loadHistory();

    // Periodic history refresh — keeps charts current even when SSE is down
    const historyTimer = window.setInterval(() => {
      if (!cancelled) {
        void loadHistory();
      }
    }, 12_000);

    return () => {
      cancelled = true;
      window.clearInterval(historyTimer);
    };
  }, [activeSensorId, isRainSensor, isFlowSensor, historyVersion]);

  const latest = latestBySensor[activeSensorId] ?? {
    sensorId: activeSensorId,
    sensorName: "Sensor",
    levelCm: 0,
    rainfallMm: 0,
    flowRateLpm: 0,
    status: "safe",
    updatedAt: STABLE_FALLBACK_TIMESTAMP,
  };

  const history = historyBySensor[activeSensorId] ?? [];

  const liveBySensor = useMemo(() => {
    return sensorsSnapshot.map((sensor) => {
      const live = latestBySensor[sensor.id];
      return {
        sensorId: sensor.id,
        sensorName: sensor.name,
        levelCm: live?.levelCm ?? sensor.lastLevelCm,
        rainfallMm: live?.rainfallMm ?? 0,
        flowRateLpm: live?.flowRateLpm ?? 0,
        status: live?.status ?? sensor.status,
        updatedAt: live?.updatedAt ?? sensor.updatedAt,
      } as LiveWaterLevel;
    });
  }, [latestBySensor, sensorsSnapshot]);

  const reload = () => {
    void loadCurrent();
  };

  return { latest, history, sensorsSnapshot, liveBySensor, isLoading, error, reload };
}
