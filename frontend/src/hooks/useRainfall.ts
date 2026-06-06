"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import api from "@/lib/api";
import { PRIMARY_SENSOR_ID } from "@/constants";
import type { WaterLevelPoint } from "@/types/water-level";

interface UseRainfallOptions {
  sensorId?: string;
  refreshMs?: number;
}

interface ApiRainfallCurrent {
  sensorId: string;
  sensorName?: string;
  rainfall: number;
  recordedAt: string;
}

interface ApiRainfallHistory {
  sensorId: string;
  rainfall: number;
  recordedAt: string;
}

const DEFAULT_REFRESH_MS = 5_000;
const HISTORY_HOURS = 7 * 24;
const STABLE_FALLBACK_TIMESTAMP = "2026-01-01T00:00:00.000Z";

export function useRainfall(options: UseRainfallOptions = {}) {
  const { sensorId, refreshMs = DEFAULT_REFRESH_MS } = options;
  const [latest, setLatest] = useState({
    sensorId: sensorId ?? PRIMARY_SENSOR_ID ?? "EWS-RF-002",
    sensorName: "Sensor Curah Hujan",
    rainfallMm: 0,
    updatedAt: STABLE_FALLBACK_TIMESTAMP,
  });
  const [history, setHistory] = useState<WaterLevelPoint[]>([]);
  const isMountedRef = useRef(true);

  useEffect(() => {
    isMountedRef.current = true;
    return () => {
      isMountedRef.current = false;
    };
  }, []);

  const loadCurrent = useCallback(async () => {
    try {
      const response = await api.get("/rainfall/current");
      if (!isMountedRef.current) {
        return;
      }

      const rows = (response.data?.data ?? []) as ApiRainfallCurrent[];
      const preferredId = (sensorId ?? PRIMARY_SENSOR_ID ?? "EWS-RF-002").trim();
      const selected = preferredId
        ? rows.find((row) => row.sensorId === preferredId)
        : rows[0];

      if (!selected) {
        return;
      }

      setLatest({
        sensorId: selected.sensorId,
        sensorName: selected.sensorName ?? selected.sensorId,
        rainfallMm: selected.rainfall ?? 0,
        updatedAt: selected.recordedAt ?? new Date().toISOString(),
      });
    } catch {
      // ignore
    }
  }, [sensorId]);

  const loadHistory = useCallback(async () => {
    try {
      const activeId = latest.sensorId || (sensorId ?? PRIMARY_SENSOR_ID ?? "EWS-RF-002").trim();
      if (!activeId) {
        return;
      }

      const endDate = new Date();
      const startDate = new Date(endDate.getTime() - HISTORY_HOURS * 60 * 60 * 1000);

      const historyResp = await api.get("/rainfall/history", {
        params: {
          sensorId: activeId,
          startDate: startDate.toISOString(),
          endDate: endDate.toISOString(),
          interval: "hourly",
        },
      });

      if (!isMountedRef.current) {
        return;
      }

      const historyPayload = historyResp.data?.data;
      const rows = (Array.isArray(historyPayload)
        ? historyPayload
        : historyPayload?.items ?? []) as ApiRainfallHistory[];

      const sortedRows = [...rows].sort(
        (a, b) => new Date(a.recordedAt).getTime() - new Date(b.recordedAt).getTime(),
      );

      const mapped: WaterLevelPoint[] = sortedRows.map((row) => ({
        timestamp: row.recordedAt,
        levelCm: 0,
        rainfallMm: row.rainfall ?? 0,
        flowRateLpm: 0,
        sensorId: row.sensorId,
      }));

      setHistory(mapped);
    } catch {
      if (isMountedRef.current) {
        setHistory([]);
      }
    }
  }, [latest.sensorId, sensorId]);

  useEffect(() => {
    const fetchTimer = setTimeout(() => {
      void loadCurrent();
      void loadHistory();
    }, 0);

    const timer = window.setInterval(() => {
      void loadCurrent();
      void loadHistory();
    }, 60000);

    return () => {
      clearTimeout(fetchTimer);
      window.clearInterval(timer);
    };
  }, [loadCurrent, loadHistory]);

  return { latest, history };
}
