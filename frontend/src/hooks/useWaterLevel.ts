"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { io, type Socket } from "socket.io-client";
import { PRIMARY_SENSOR_ID, WS_URL } from "@/constants";
import api from "@/lib/api";
import type { Sensor } from "@/types/sensor";
import type { LiveWaterLevel, WaterLevelPoint } from "@/types/water-level";

interface UseWaterLevelOptions {
  sensorId?: string;
  refreshMs?: number;
}

const DEFAULT_REFRESH_MS = 5_000;
const HISTORY_HOURS = 7 * 24;
const STABLE_FALLBACK_TIMESTAMP = "2026-01-01T00:00:00.000Z";

interface ApiSensor {
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
  const { sensorId, refreshMs = DEFAULT_REFRESH_MS } = options;
  const [historyBySensor, setHistoryBySensor] = useState<Record<string, WaterLevelPoint[]>>({});
  const [latestBySensor, setLatestBySensor] = useState<Record<string, LiveWaterLevel>>({});
  const [sensorsSnapshot, setSensorsSnapshot] = useState<Sensor[]>([]);
  const isMountedRef = useRef(true);
  const waterSensorIdsRef = useRef<Set<string>>(new Set());

  useEffect(() => {
    return () => {
      isMountedRef.current = false;
    };
  }, []);

  const loadCurrent = useCallback(async () => {
    try {
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
      const waterRows = (waterResp.data?.data ?? []) as ApiWaterCurrent[];
      const rainfallRows = (rainfallResp.data?.data ?? []) as ApiRainfallCurrent[];
      const flowRows = (flowResp.data?.data ?? []) as ApiFlowCurrent[];

      const waterBySensorId = new Map(waterRows.map((row) => [row.sensorId, row]));
      const rainfallBySensorId = new Map(rainfallRows.map((row) => [row.sensorId, row]));
      const flowBySensorId = new Map(flowRows.map((row) => [row.sensorId, row]));

      const normalizedPrimaryId = PRIMARY_SENSOR_ID.trim();
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
        const updatedAt = water?.recordedAt ?? rain?.recordedAt ?? sensor.lastActiveAt ?? toIsoNow();
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
    } catch {
      if (isMountedRef.current) {
        setSensorsSnapshot([]);
        setLatestBySensor({});
      }
    }
  }, []);

  useEffect(() => {
    const socket: Socket = io(WS_URL, {
      transports: ["websocket"],
      reconnectionAttempts: 5,
    });

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
    };

    socket.on("sensorUpdate", applyRealtimeUpdate);
    socket.on("statusChange", applyRealtimeUpdate);

    void loadCurrent();
    const timer = window.setInterval(() => {
      void loadCurrent();
    }, refreshMs);

    return () => {
      window.clearInterval(timer);
      socket.off("sensorUpdate", applyRealtimeUpdate);
      socket.off("statusChange", applyRealtimeUpdate);
      socket.disconnect();
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
        const latestRain = latestBySensor[activeId]?.rainfallMm ?? 0;

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

    void loadHistory();
    return () => {
      cancelled = true;
    };
  }, [activeSensorId, isRainSensor, isFlowSensor, latestBySensor]);

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

  return { latest, history, sensorsSnapshot, liveBySensor };
}
