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

    // Immediate initial fetch
    void run();

    // Setup bulletproof 60-second silent background polling
    const timer = window.setInterval(() => {
      void run();
    }, 60000);

    return () => {
      cancelled = true;
      window.clearInterval(timer);
    };
  }, [loadIotData]);

  return state;
}
