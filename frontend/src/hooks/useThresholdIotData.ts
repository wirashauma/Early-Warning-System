"use client";

import { useCallback, useEffect, useState } from "react";
import api from "@/lib/api";
import { API_URL } from "@/constants";

export interface ThresholdIotPoint {
  sensorId: string;
  sensorName: string;
  value: number;
  recordedAt: string;
}

interface IotState {
  rainfallData: ThresholdIotPoint[];
  flowRateData: ThresholdIotPoint[];
  waterLevelData: ThresholdIotPoint[];
  isLoading: boolean;
  error: string | null;
  lastUpdated: string | null;
}

interface ApiCurrentRow {
  sensorId: string;
  sensorName?: string;
  name?: string;
  rainfall?: number;
  flowRate?: number;
  waterLevel?: number;
  recordedAt?: string;
}

interface ApiCurrentResponse {
  data?: {
    data?: ApiCurrentRow[] | { items?: ApiCurrentRow[] };
  };
}

const DEFAULT_POLL_MS = 5000;

function normalizeRows(payload: unknown): ApiCurrentRow[] {
  if (Array.isArray(payload)) {
    return payload as ApiCurrentRow[];
  }

  if (payload && typeof payload === "object") {
    const maybeItems = (payload as { items?: ApiCurrentRow[] }).items;
    if (Array.isArray(maybeItems)) {
      return maybeItems;
    }
  }

  return [];
}

function toTimestamp(value?: string) {
  return value ?? new Date().toISOString();
}

export function useThresholdIotData(refreshMs = DEFAULT_POLL_MS) {
  const [state, setState] = useState<IotState>({
    rainfallData: [],
    flowRateData: [],
    waterLevelData: [],
    isLoading: true,
    error: null,
    lastUpdated: null,
  });

  const loadIotData = useCallback(async () => {
    setState((prev) => ({ ...prev, isLoading: prev.lastUpdated === null, error: null }));

    try {
      const [rainResp, flowResp, waterResp] = await Promise.all([
        api.get("/rainfall/current"),
        api.get("/flow-rate/current"),
        api.get("/water-levels/current"),
      ]);

      const rainfallRows = normalizeRows((rainResp as ApiCurrentResponse).data?.data);
      const flowRows = normalizeRows((flowResp as ApiCurrentResponse).data?.data);
      const waterRows = normalizeRows((waterResp as ApiCurrentResponse).data?.data);

      setState({
        rainfallData: rainfallRows.map((row) => ({
          sensorId: row.sensorId,
          sensorName: row.sensorName ?? row.name ?? row.sensorId,
          value: Number(row.rainfall ?? 0),
          recordedAt: toTimestamp(row.recordedAt),
        })),
        flowRateData: flowRows.map((row) => ({
          sensorId: row.sensorId,
          sensorName: row.sensorName ?? row.name ?? row.sensorId,
          value: Number(row.flowRate ?? 0),
          recordedAt: toTimestamp(row.recordedAt),
        })),
        waterLevelData: waterRows.map((row) => ({
          sensorId: row.sensorId,
          sensorName: row.sensorName ?? row.name ?? row.sensorId,
          value: Number(row.waterLevel ?? 0),
          recordedAt: toTimestamp(row.recordedAt),
        })),
        isLoading: false,
        error: null,
        lastUpdated: new Date().toISOString(),
      });
    } catch (error) {
      setState((prev) => ({
        ...prev,
        isLoading: false,
        error: error instanceof Error ? error.message : "Gagal memuat data IoT.",
      }));
    }
  }, []);

  useEffect(() => {
    let cancelled = false;

    const run = async () => {
      if (!cancelled) {
        await loadIotData();
      }
    };

    // 1. SSE Connection setup
    const streamUrl = API_URL.startsWith("/")
      ? `${window.location.protocol}//${window.location.host}${API_URL}/sensors/stream`
      : `${API_URL}/sensors/stream`;

    console.log("⚡ useThresholdIotData: SSE Connecting to stream:", streamUrl);
    const eventSource = new EventSource(streamUrl);

    eventSource.onmessage = (event) => {
      if (cancelled) return;
      try {
        const data = JSON.parse(event.data);
        console.log("⚡ useThresholdIotData: SSE Event received:", data);

        setState((prev) => {
          let nextRain = [...prev.rainfallData];
          let nextFlow = [...prev.flowRateData];
          let nextWater = [...prev.waterLevelData];
          let updated = false;

          if (data.water) {
            const idx = nextWater.findIndex((x) => x.sensorId === data.water.sensorId);
            const newPt = {
              sensorId: data.water.sensorId,
              sensorName: data.water.sensorName ?? (idx !== -1 ? nextWater[idx].sensorName : data.water.sensorId),
              value: Number(data.water.waterLevel),
              recordedAt: data.recordedAt ?? new Date().toISOString(),
            };
            if (idx !== -1) nextWater[idx] = newPt;
            else nextWater.push(newPt);
            updated = true;
          }

          if (data.rainfall) {
            const idx = nextRain.findIndex((x) => x.sensorId === data.rainfall.sensorId);
            const newPt = {
              sensorId: data.rainfall.sensorId,
              sensorName: data.rainfall.sensorName ?? (idx !== -1 ? nextRain[idx].sensorName : data.rainfall.sensorId),
              value: Number(data.rainfall.rainfall),
              recordedAt: data.recordedAt ?? new Date().toISOString(),
            };
            if (idx !== -1) nextRain[idx] = newPt;
            else nextRain.push(newPt);
            updated = true;
          }

          if (data.flowRate) {
            const idx = nextFlow.findIndex((x) => x.sensorId === data.flowRate.sensorId);
            const newPt = {
              sensorId: data.flowRate.sensorId,
              sensorName: data.flowRate.sensorName ?? (idx !== -1 ? nextFlow[idx].sensorName : data.flowRate.sensorId),
              value: Number(data.flowRate.flowRate),
              recordedAt: data.recordedAt ?? new Date().toISOString(),
            };
            if (idx !== -1) nextFlow[idx] = newPt;
            else nextFlow.push(newPt);
            updated = true;
          }

          if (!updated) return prev;

          return {
            ...prev,
            rainfallData: nextRain,
            flowRateData: nextFlow,
            waterLevelData: nextWater,
            lastUpdated: new Date().toISOString(),
          };
        });
      } catch (err) {
        console.error("Error parsing SSE data in useThresholdIotData:", err);
      }
    };

    eventSource.onerror = (err) => {
      console.warn("useThresholdIotData: SSE stream error or disconnect:", err);
    };

    void run();
    
    // Smooth fallback polling (reduced rate to 30s to respect SSE stream)
    const timer = window.setInterval(() => {
      console.log("🔄 useThresholdIotData: SSE Heartbeat Sync...");
      void run();
    }, Math.max(refreshMs, 30_000));

    return () => {
      cancelled = true;
      eventSource.close();
      window.clearInterval(timer);
    };
  }, [loadIotData, refreshMs]);

  return state;
}
