"use client";

import { useCallback, useEffect, useState } from "react";
import api from "@/lib/api";
import { API_URL, WS_URL } from "@/constants";

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
    const directApiUrl = WS_URL.replace(/^ws/, "http");
    const streamUrl = `${directApiUrl}/api/sensors/stream`;

    const eventSource = new EventSource(streamUrl);
    let lastMessageTime = Date.now();

    eventSource.onopen = () => {
      // SSE connection opened
    };

    eventSource.onmessage = (event) => {
      if (cancelled) return;
      try {
        lastMessageTime = Date.now();
        const data = JSON.parse(event.data);

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
        console.error("❌ [useThresholdIotData SSE] Error parsing SSE data:", err);
      }
    };

    eventSource.onerror = (err) => {
      console.warn("⚠️ [useThresholdIotData SSE] SSE stream closed or error, will reconnect...", err);
    };

    // Listen to custom Supabase Realtime telemetry update events
    const handleRealtimeTelemetry = (e: Event) => {
      if (cancelled) return;
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
      const { sensorId, waterLevel, rainfall, flowRate, recordedAt } = customEvent.detail;
      
      if (!sensorId) return;

      setState((prev) => {
        let nextRain = [...prev.rainfallData];
        let nextFlow = [...prev.flowRateData];
        let nextWater = [...prev.waterLevelData];
        let updated = false;

        if (waterLevel !== undefined) {
          const idx = nextWater.findIndex((x) => x.sensorId === sensorId);
          const newPt = {
            sensorId,
            sensorName: idx !== -1 ? nextWater[idx].sensorName : sensorId,
            value: Number(waterLevel),
            recordedAt: recordedAt ?? new Date().toISOString(),
          };
          if (idx !== -1) nextWater[idx] = newPt;
          else nextWater.push(newPt);
          updated = true;
        }

        if (rainfall !== undefined) {
          const idx = nextRain.findIndex((x) => x.sensorId === sensorId);
          const newPt = {
            sensorId,
            sensorName: idx !== -1 ? nextRain[idx].sensorName : sensorId,
            value: Number(rainfall),
            recordedAt: recordedAt ?? new Date().toISOString(),
          };
          if (idx !== -1) nextRain[idx] = newPt;
          else nextRain.push(newPt);
          updated = true;
        }

        if (flowRate !== undefined) {
          const idx = nextFlow.findIndex((x) => x.sensorId === sensorId);
          const newPt = {
            sensorId,
            sensorName: idx !== -1 ? nextFlow[idx].sensorName : sensorId,
            value: Number(flowRate),
            recordedAt: recordedAt ?? new Date().toISOString(),
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
    };

    if (typeof window !== "undefined") {
      window.addEventListener("sensorTelemetryUpdated", handleRealtimeTelemetry);
    }

    void run();

    // Smooth fallback polling (reduced rate to 30s to respect SSE stream)
    const timer = window.setInterval(() => {
      void run();
    }, Math.max(refreshMs, 30_000));

    // Active 3s polling fallback: if no SSE events received for > 8 seconds, poll backend
    const fallbackTimer = window.setInterval(() => {
      const timeSinceLastMessage = Date.now() - lastMessageTime;
      if (timeSinceLastMessage > 8000) {
        void run();
      }
    }, 3000);

    return () => {
      cancelled = true;
      window.clearInterval(timer);
      window.clearInterval(fallbackTimer);
      eventSource.close();
      if (typeof window !== "undefined") {
        window.removeEventListener("sensorTelemetryUpdated", handleRealtimeTelemetry);
      }
    };
  }, [loadIotData, refreshMs]);

  return state;
}
