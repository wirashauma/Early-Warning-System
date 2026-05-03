"use client";

import { useEffect, useState } from "react";
import type { LiveWaterLevel, WaterLevelPoint } from "@/types/water-level";
import { getStatusFromLevel } from "@/lib/utils";

export function useWaterLevel() {
  const [latest, setLatest] = useState<LiveWaterLevel>({
    sensorId: "SEN-01",
    sensorName: "Sensor Hulu",
    levelCm: 132,
    rainfallMm: 8,
    status: "safe",
    updatedAt: new Date().toISOString(),
  });

  const [history, setHistory] = useState<WaterLevelPoint[]>(() => {
    return Array.from({ length: 12 }).map((_, i) => ({
      timestamp: new Date(Date.now() - (11 - i) * 10 * 60 * 1000).toISOString(),
      levelCm: 120 + i * 4,
      rainfallMm: 5 + i,
      sensorId: "SEN-01",
    }));
  });

  useEffect(() => {
    const timer = setInterval(() => {
      setLatest((prev) => {
        const delta = Math.floor(Math.random() * 9) - 2;
        const nextLevel = Math.max(80, prev.levelCm + delta);
        const nextLatest: LiveWaterLevel = {
          ...prev,
          levelCm: nextLevel,
          rainfallMm: Math.max(0, prev.rainfallMm + Math.floor(Math.random() * 3) - 1),
          status: getStatusFromLevel(nextLevel),
          updatedAt: new Date().toISOString(),
        };

        setHistory((prevHistory) => {
          const nextPoint: WaterLevelPoint = {
            timestamp: nextLatest.updatedAt,
            levelCm: nextLatest.levelCm,
            rainfallMm: nextLatest.rainfallMm,
            sensorId: nextLatest.sensorId,
          };

          return [...prevHistory, nextPoint].slice(-20);
        });

        return nextLatest;
      });
    }, 7000);

    return () => clearInterval(timer);
  }, []);

  return { latest, history };
}
