# Week 14 Technical State Summary

This document captures the current implementation state of the repository, with a focus on the recent IoT ingestion, Prisma connection handling, polling, offline detection, and admin sensor UI work.

## 1) IoT Ingestion API & Data Handling

### Endpoint routing

The backend exposes the ingest endpoint through the `IotController`, and the app sets a global `api` prefix in `main.ts`, so the effective route is `POST /api/iot/ingest`.

```ts
// backend/src/main.ts
app.setGlobalPrefix('api');
```

```ts
// backend/src/iot/iot.controller.ts
@Controller('iot')
export class IotController {
  constructor(private readonly iotService: IotService) {}

  @Post('ingest')
  async ingest(@Body() body: IngestPayload): Promise<ApiResponse<IngestResult>> {
    const data = await this.iotService.ingest(body);
    return ok(data, 'Ingest accepted');
  }
}
```

### Null-safe `waterLevel` handling

The critical part is the `hasValue()` guard. It treats `null` and `undefined` as “missing,” so `waterLevel: null` does **not** get coerced to `0`. Instead, the code only processes the water branch when a real numeric value exists.

```ts
// backend/src/iot/iot.service.ts
async ingest(payload: IngestPayload): Promise<IngestResult> {
  const hasValue = (value: number | null | undefined) => value !== undefined && value !== null;

  const hasWater = hasValue(payload.waterLevel);
  const hasRain = hasValue(payload.rainfall);
  const hasFlow = hasValue(payload.flowRate);

  if (!hasWater && !hasRain && !hasFlow) {
    throw new BadRequestException(
      'waterLevel, rainfall, atau flowRate wajib diisi.',
    );
  }

  // ...

  if (hasWater && waterSensorId) {
    const sensor = await this.prisma.sensor.findFirst({
      where: {
        sensorId: waterSensorId,
        type: SensorType.WATER_LEVEL,
        isActive: true,
      },
    });

    if (!sensor) {
      throw new NotFoundException('Sensor water level tidak ditemukan.');
    }

    const waterStatus = this.resolveWaterStatus(
      payload.waterLevel as number,
      waterThreshold,
    );

    await this.prisma.waterLevelLog.create({
      data: {
        sensorId: sensor.id,
        waterLevel: payload.waterLevel as number,
        unit: 'cm',
        status: waterStatus,
        recordedAt,
      },
    });

    await this.updateSensorStatus(sensor.id, recordedAt, payload);

    result.water = {
      sensorId: sensor.sensorId,
      waterLevel: payload.waterLevel as number,
      status: waterStatus,
    };
  }
}
```

**How it works:** the request can carry water, rain, and/or flow data, but each branch is gated by `hasValue(...)`. That means `null` is treated as absent, not as a numeric zero. This preserves the distinction between “no reading received” and “reading of 0”.

## 2) Database Connection Pool Fix (`EMAXCONNSESSION`)

The Prisma setup is implemented as a global NestJS module with a single shared `PrismaService` provider. The service uses a PostgreSQL pool plus the Prisma PG adapter, then disconnects cleanly on shutdown.

```ts
// backend/src/prisma/prisma.module.ts
import { Global, Module } from '@nestjs/common';
import { PrismaService } from './prisma.service';

@Global()
@Module({
  providers: [PrismaService],
  exports: [PrismaService],
})
export class PrismaModule {}
```

```ts
// backend/src/prisma/prisma.service.ts
import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '@prisma/client';
import { Pool } from 'pg';
import * as dotenv from 'dotenv';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleDestroy {
  constructor() {
    dotenv.config();

    const connectionString =
      process.env.DATABASE_URL ??
      'postgresql://postgres:postgres@localhost:5432/postgres';

    const pool = new Pool({ connectionString });
    const adapter = new PrismaPg(pool);

    super({
      adapter,
      log: ['warn', 'error'],
    });
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
```

**How it works:** NestJS provides `PrismaService` through the global `PrismaModule`, so the app shares one DI-managed instance instead of creating ad hoc clients. The `pg` pool + Prisma adapter prevent frequent polling from spawning too many database connections, which is the practical fix behind the connection exhaustion issue.

## 3) Client-Side Polling Logic

The shared hook `useWaterLevel` fetches sensor data on a configurable interval. The admin sensors page passes `12_000` ms, which means polling every 12 seconds.

```ts
// frontend/src/app/admin/sensors/page.tsx
const POLL_REFRESH_MS = 12_000;

export default function AdminSensorsPage() {
  const { sensorsSnapshot: sensors, isLoading, error, reload } = useWaterLevel({ refreshMs: POLL_REFRESH_MS });
  // ...
}
```

```ts
// frontend/src/hooks/useWaterLevel.ts
export function useWaterLevel(options: UseWaterLevelOptions = {}) {
  const { sensorId, refreshMs = DEFAULT_REFRESH_MS } = options;

  // ...

  useEffect(() => {
    const activeId = activeSensorId;

    if (!activeId) {
      return;
    }

    let cancelled = false;
    const loadHistory = async () => {
      // history loading omitted
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
}
```

**How it works:** the hook performs an immediate fetch with `loadCurrent()`, then keeps the UI fresh through `window.setInterval(..., refreshMs)`. In the admin page, `refreshMs` is explicitly set to `12_000`, so the data refreshes every 12 seconds.

## 4) Last-Seen & Offline Logic (DRY Principle)

These helpers centralize freshness and relative-time logic so the UI can reuse the same behavior everywhere.

```ts
// frontend/src/lib/utils.ts
export const SENSOR_OFFLINE_THRESHOLD_MS = 3 * 60 * 1000;

function toTimestamp(value: string | Date | null | undefined) {
  if (!value) return null;

  const parsed = value instanceof Date ? value.getTime() : new Date(value).getTime();
  return Number.isNaN(parsed) ? null : parsed;
}

export function isSensorOffline(
  lastSeenAt: string | Date | null | undefined,
  nowMs = Date.now(),
  thresholdMs = SENSOR_OFFLINE_THRESHOLD_MS,
) {
  const parsed = toTimestamp(lastSeenAt);
  if (parsed === null) return true;

  return nowMs - parsed > thresholdMs;
}

export function isSensorOnline(
  lastSeenAt: string | Date | null | undefined,
  nowMs = Date.now(),
  thresholdMs = SENSOR_OFFLINE_THRESHOLD_MS,
) {
  return !isSensorOffline(lastSeenAt, nowMs, thresholdMs);
}

export function formatRelativeTime(dateValue: string | Date | null | undefined, nowMs = Date.now()) {
  const parsed = toTimestamp(dateValue);
  if (parsed === null) return "Belum ada ingest";

  const diffSeconds = Math.round((parsed - nowMs) / 1000);
  const absSeconds = Math.abs(diffSeconds);

  if (absSeconds < 45) {
    return diffSeconds <= 0 ? "beberapa detik yang lalu" : "dalam beberapa detik";
  }

  const formatter = new Intl.RelativeTimeFormat("id-ID", { numeric: "auto" });
  const diffMinutes = Math.round(diffSeconds / 60);
  if (Math.abs(diffMinutes) < 60) return formatter.format(diffMinutes, "minute");

  const diffHours = Math.round(diffMinutes / 60);
  if (Math.abs(diffHours) < 24) return formatter.format(diffHours, "hour");

  return formatter.format(Math.round(diffHours / 24), "day");
}
```

**How it works:** `isSensorOffline()` is the source of truth for determining staleness from `lastSeenAt`. `isSensorOnline()` simply negates it, and `formatRelativeTime()` provides a user-friendly timestamp label. The threshold is exactly 3 minutes.

## 5) Frontend UI Integration (Admin Sensors)

The admin sensors page consumes `isSensorOnline()` and uses the result to render pulsing status badges. It also shows a “Menunggu Data” fallback when water-level data has not been ingested yet.

```tsx
// frontend/src/app/admin/sensors/page.tsx
const sensorHealth = sensors.map((sensor) => {
  const online = isSensorOnline(sensor.lastSeenAt ?? sensor.updatedAt, nowMs);
  return { ...sensor, online };
});

// ...

{sensorHealth.map((sensor) => {
  const online = sensor.online;
  const tone = connectionTone(online);
  const battery = batteryTone(sensor.batteryPercent);
  const lastSeen = sensor.lastSeenAt ?? sensor.updatedAt;
  const exactTimestamp = lastSeen ? formatTimestamp(lastSeen) : "Belum ada ingest";
  const relativeTime = formatRelativeTime(lastSeen, nowMs);

  return (
    <div key={sensor.id} className="grid gap-4 px-5 py-4 lg:grid-cols-[2.3fr_1.25fr_1.1fr_1.1fr_1.25fr_1fr] lg:items-center">
      <div className="space-y-2">
        <div className="flex flex-wrap items-center gap-2">
          <h3 className="text-base font-semibold text-slate-900">{sensor.name}</h3>
          <span className="rounded-full border border-slate-200 bg-slate-50 px-2 py-0.5 text-[11px] font-mono text-slate-500">
            {sensor.id}
          </span>
          <StatusIndicator status={sensor.status} />
        </div>
      </div>

      <div className="space-y-2">
        <p className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500 lg:hidden">Ketinggian Air</p>
        {sensor.hasWaterLevelData ? (
          <div className="inline-flex items-center gap-2 rounded-full border border-slate-200 bg-slate-50 px-3 py-1.5 text-sm font-semibold text-slate-900 shadow-sm">
            <span>{sensor.lastLevelCm.toFixed(1)} cm</span>
          </div>
        ) : (
          <span className="inline-flex rounded-full border border-slate-200 bg-slate-50 px-3 py-1.5 text-xs font-semibold text-slate-500 shadow-sm">
            Menunggu Data
          </span>
        )}
      </div>

      <div className="space-y-2">
        <p className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500 lg:hidden">Status Koneksi</p>
        <span className={cn("inline-flex items-center gap-2 rounded-full border px-3 py-1.5 text-xs font-semibold shadow-sm", tone.badge)}>
          {connectionIcon(online)}
          {online ? "Online" : "Offline"}
        </span>
      </div>
    </div>
  );
})}
```

**How it works:** each sensor is normalized with an `online` flag derived from `isSensorOnline(sensor.lastSeenAt ?? sensor.updatedAt, nowMs)`. The badge uses `connectionIcon(online)` and the tone returned by `connectionTone(online)`, so the pulsing UI visually matches the freshness state. When no water reading exists yet, the UI intentionally shows `Menunggu Data` rather than pretending there is a 0 cm reading.

## Key takeaway

The implementation is cohesive:

- ingestion avoids false zero values by explicitly checking for `null`/`undefined`
- Prisma uses a shared, pool-backed global provider to reduce connection pressure
- the frontend polls every 12 seconds while still reacting to socket updates
- offline detection and relative time formatting are centralized in `utils.ts`
- the admin dashboard reflects real freshness state instead of assuming data exists

If you want, this can be expanded into a more narrative Week 14 progress report version next.