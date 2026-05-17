"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import api from "@/lib/api";
import { FLOW_SENSOR_ID } from "@/constants";
import type { LiveFlowRate, WaterLevelPoint } from "@/types/water-level";

interface UseFlowRateOptions {
  sensorId?: string;
  refreshMs?: number;
}

interface ApiFlowCurrent {
  sensorId: string;
  sensorName?: string;
  flowRate: number;
  recordedAt: string;
}

interface ApiFlowHistory {
  sensorId: string;
  flowRate: number;
  recordedAt: string;
}

const DEFAULT_REFRESH_MS = 5_000;
const HISTORY_HOURS = 7 * 24;
const STABLE_FALLBACK_TIMESTAMP = "2026-01-01T00:00:00.000Z";

function toIsoNow() {
  return new Date().toISOString();
}

export function useFlowRate(options: UseFlowRateOptions = {}) {
  const { sensorId, refreshMs = DEFAULT_REFRESH_MS } = options;
  const [latest, setLatest] = useState<LiveFlowRate>({
    sensorId: sensorId ?? FLOW_SENSOR_ID ?? "",
    sensorName: "Sensor",
    flowRateLpm: 0,
    updatedAt: STABLE_FALLBACK_TIMESTAMP,
  });
  const [history, setHistory] = useState<WaterLevelPoint[]>([]);
  const isMountedRef = useRef(true);

  useEffect(() => {
    return () => {
      isMountedRef.current = false;
    };
  }, []);

  const loadCurrent = useCallback(async () => {
    try {
      const response = await api.get("/flow-rate/current");
      if (!isMountedRef.current) {
        return;
      }

      const rows = (response.data?.data ?? []) as ApiFlowCurrent[];
      const preferredId = (sensorId ?? FLOW_SENSOR_ID ?? "").trim();
      const selected = preferredId
        ? rows.find((row) => row.sensorId === preferredId)
        : rows[0];

      if (!selected) {
        setLatest((prev) => ({
          ...prev,
          updatedAt: toIsoNow(),
        }));
        return;
      }

      setLatest({
        sensorId: selected.sensorId,
        sensorName: selected.sensorName ?? selected.sensorId,
        flowRateLpm: selected.flowRate ?? 0,
        updatedAt: selected.recordedAt ?? toIsoNow(),
      });
    } catch {
      if (isMountedRef.current) {
        setLatest((prev) => ({
          ...prev,
          updatedAt: toIsoNow(),
        }));
      }
    }
  }, [sensorId]);

  const loadHistory = useCallback(async () => {
    try {
      const activeId = latest.sensorId || (sensorId ?? FLOW_SENSOR_ID ?? "").trim();
      if (!activeId) {
        return;
      }

      const endDate = new Date();
      const startDate = new Date(endDate.getTime() - HISTORY_HOURS * 60 * 60 * 1000);

      const historyResp = await api.get("/flow-rate/history", {
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
        : historyPayload?.items ?? []) as ApiFlowHistory[];

      const sortedRows = [...rows].sort(
        (a, b) => new Date(a.recordedAt).getTime() - new Date(b.recordedAt).getTime(),
      );

      const mapped: WaterLevelPoint[] = sortedRows.map((row) => ({
        timestamp: row.recordedAt,
        levelCm: 0,
        rainfallMm: 0,
        flowRateLpm: row.flowRate ?? 0,
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
    void loadCurrent();
    void loadHistory();
    const timer = window.setInterval(() => {
      void loadCurrent();
      void loadHistory();
    }, refreshMs);

    return () => {
      window.clearInterval(timer);
    };
  }, [loadCurrent, loadHistory, refreshMs]);

  return { latest, history };
}
