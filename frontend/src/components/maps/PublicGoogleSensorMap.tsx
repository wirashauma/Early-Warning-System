"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { cn } from "@/lib/utils";
import type { Sensor } from "@/types/sensor";

interface PublicGoogleSensorMapProps {
  sensors: Sensor[];
  selectedSensorId?: string;
  onMarkerSelect?: (sensorId: string) => void;
  className?: string;
}

interface ScriptState {
  ready: boolean;
  error: string | null;
}

declare global {
  interface Window {
    google?: {
      maps?: {
        Map: new (element: HTMLElement, options: Record<string, unknown>) => {
          setCenter: (latLng: { lat: number; lng: number }) => void;
        };
        Marker: new (options: Record<string, unknown>) => {
          addListener: (eventName: string, callback: () => void) => void;
        };
        InfoWindow: new () => {
          setContent: (content: string) => void;
          open: (map: unknown, marker?: unknown) => void;
        };
      };
    };
  }
}

const SCRIPT_ID = "ews-google-maps-script-public";

function getStatusBadge(status: Sensor["status"]) {
  if (status === "danger") {
    return { label: "Bahaya", color: "#e11d48" };
  }
  if (status === "alert") {
    return { label: "Siaga", color: "#f97316" }; // Orange 500
  }
  if (status === "warning") {
    return { label: "Waspada", color: "#f59e0b" }; // Amber 500
  }

  return { label: "Normal", color: "#10b981" };
}

export function PublicGoogleSensorMap({
  sensors,
  selectedSensorId,
  onMarkerSelect,
  className,
}: PublicGoogleSensorMapProps) {
  const mapRef = useRef<HTMLDivElement | null>(null);
  const [scriptState, setScriptState] = useState<ScriptState>({ ready: false, error: null });

  const apiKey = process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY;
  const isKeyInvalid = !apiKey || apiKey === "your_google_maps_api_key";

  const center = useMemo(() => {
    if (sensors.length === 0) {
      return { lat: -0.95, lng: 100.37 };
    }

    const latitude = sensors.reduce((sum, sensor) => sum + sensor.latitude, 0) / sensors.length;
    const longitude = sensors.reduce((sum, sensor) => sum + sensor.longitude, 0) / sensors.length;

    return { lat: latitude, lng: longitude };
  }, [sensors]);

  useEffect(() => {
    if (isKeyInvalid) {
      return;
    }

    const initReadyState = () => {
      if (window.google?.maps) {
        setScriptState({ ready: true, error: null });
      }
    };

    if (window.google?.maps) {
      initReadyState();
      return;
    }

    const existing = document.getElementById(SCRIPT_ID) as HTMLScriptElement | null;

    const handleLoad = () => {
      initReadyState();
    };

    const handleError = () => {
      setScriptState({ ready: false, error: "Gagal memuat Google Maps API." });
    };

    if (existing) {
      existing.addEventListener("load", handleLoad);
      existing.addEventListener("error", handleError);

      return () => {
        existing.removeEventListener("load", handleLoad);
        existing.removeEventListener("error", handleError);
      };
    }

    const script = document.createElement("script");
    script.id = SCRIPT_ID;
    script.src = `https://maps.googleapis.com/maps/api/js?key=${apiKey}`;
    script.async = true;
    script.defer = true;
    script.addEventListener("load", handleLoad);
    script.addEventListener("error", handleError);

    document.head.appendChild(script);

    return () => {
      script.removeEventListener("load", handleLoad);
      script.removeEventListener("error", handleError);
    };
  }, [apiKey, isKeyInvalid]);

  useEffect(() => {
    if (!scriptState.ready || !window.google?.maps || !mapRef.current) {
      return;
    }

    const selectedSensor = sensors.find((sensor) => sensor.id === selectedSensorId) ?? sensors[0];

    const map = new window.google.maps.Map(mapRef.current, {
      center: selectedSensor ? { lat: selectedSensor.latitude, lng: selectedSensor.longitude } : center,
      zoom: 13,
      mapTypeId: "hybrid",
      mapTypeControl: true,
      streetViewControl: false,
      fullscreenControl: false,
      gestureHandling: "cooperative",
    });

    const infoWindow = new window.google.maps.InfoWindow();

    sensors.forEach((sensor) => {
      const status = getStatusBadge(sensor.status);
      const marker = new window.google!.maps!.Marker({
        map,
        position: { lat: sensor.latitude, lng: sensor.longitude },
        title: sensor.name,
      });

      marker.addListener("click", () => {
        onMarkerSelect?.(sensor.id);
        infoWindow.setContent(`
          <div style="min-width:190px;font-family:Inter,Arial,sans-serif;padding:2px 0;">
            <p style="font-size:13px;font-weight:700;margin:0 0 6px;color:#0f172a;">${sensor.name}</p>
            <p style="font-size:12px;margin:0 0 4px;color:#334155;">Sungai: <strong>${sensor.riverName}</strong></p>
            <p style="font-size:12px;margin:0 0 4px;color:#334155;">Tinggi Air: <strong>${sensor.lastLevelCm} cm</strong></p>
            <p style="font-size:12px;margin:0;color:#334155;">Status: <strong style=\"color:${status.color};\">${status.label}</strong></p>
          </div>
        `);
        infoWindow.open(map, marker);
      });
    });
  }, [center, onMarkerSelect, scriptState.ready, selectedSensorId, sensors]);

  if (isKeyInvalid || scriptState.error) {
    return (
      <div className="rounded-xl border border-amber-200 bg-amber-50/80 p-4 text-sm text-amber-800">
        <p className="font-semibold">Peta Google belum aktif</p>
        <p className="mt-1 text-xs text-amber-700">Isi nilai `NEXT_PUBLIC_GOOGLE_MAPS_API_KEY` pada `frontend/.env` atau `frontend/.env.local`.</p>
      </div>
    );
  }

  return (
    <div className={cn("relative h-96 w-full overflow-hidden rounded-xl border border-slate-200", className)}>
      {!scriptState.ready && (
        <div className="absolute inset-0 z-10 flex items-center justify-center bg-slate-100/70 backdrop-blur-[1px]">
          <span className="rounded-full border border-slate-200 bg-white px-3 py-1 text-xs font-semibold text-slate-600">Memuat peta sensor...</span>
        </div>
      )}
      <div ref={mapRef} className="h-full w-full" aria-label="Peta publik sensor banjir" />
    </div>
  );
}
