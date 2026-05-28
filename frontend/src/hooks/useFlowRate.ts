"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import api from "@/lib/api";
import { FLOW_SENSOR_ID, API_URL } from "@/constants";
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
    isMountedRef.current = true;
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
    const applyRealtimeUpdate = (payload: { sensorId: string; flowRate: number; recordedAt?: string }) => {
      const preferredId = (sensorId ?? FLOW_SENSOR_ID ?? "").trim();
      if (!payload.sensorId || (preferredId && payload.sensorId !== preferredId)) {
        return;
      }

      const timestamp = payload.recordedAt ?? toIsoNow();

      setLatest((prev) => {
        if (prev.sensorId && prev.sensorId !== payload.sensorId) {
          return prev;
        }
        return {
          ...prev,
          flowRateLpm: payload.flowRate,
          updatedAt: timestamp,
        };
      });

      setHistory((prev) => {
        const existingIndex = prev.findIndex((p) => p.timestamp === timestamp);
        let newHistory = [...prev];

        if (existingIndex !== -1) {
          newHistory[existingIndex] = {
            ...newHistory[existingIndex],
            flowRateLpm: payload.flowRate,
          };
        } else {
          const lastPoint = prev[prev.length - 1];
          const newPoint: WaterLevelPoint = {
            timestamp,
            levelCm: lastPoint?.levelCm ?? 0,
            rainfallMm: lastPoint?.rainfallMm ?? 0,
            flowRateLpm: payload.flowRate,
            sensorId: payload.sensorId,
          };
          newHistory.push(newPoint);
        }

        newHistory.sort((a, b) => new Date(a.timestamp).getTime() - new Date(b.timestamp).getTime());
        return newHistory;
      });
    };

    // 1. Establish SSE EventSource connection
    const streamUrl = API_URL.startsWith("/")
      ? `${window.location.protocol}//${window.location.host}${API_URL}/sensors/stream`
      : `${API_URL}/sensors/stream`;

    console.log("⚡ useFlowRate: SSE Connecting to stream:", streamUrl);
    const eventSource = new EventSource(streamUrl);

    eventSource.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        console.log("⚡ useFlowRate: SSE Real-Time Event received:", data);

        if (data.flowRate) {
          applyRealtimeUpdate({
            sensorId: data.flowRate.sensorId,
            flowRate: data.flowRate.flowRate,
            recordedAt: data.recordedAt,
          });
        }
      } catch (err) {
        console.error("Error parsing SSE message in useFlowRate:", err);
      }
    };

    eventSource.onerror = (err) => {
      console.warn("useFlowRate: SSE stream closed or error, will reconnect...", err);
    };

    void loadCurrent();
    void loadHistory();

    const timer = window.setInterval(() => {
      console.log("🔄 useFlowRate: Heartbeat sync...");
      void loadCurrent();
      void loadHistory();
    }, Math.max(refreshMs, 30_000));

    return () => {
      window.clearInterval(timer);
      eventSource.close();
    };
  }, [loadCurrent, loadHistory, refreshMs, sensorId]);

  return { latest, history };
}
