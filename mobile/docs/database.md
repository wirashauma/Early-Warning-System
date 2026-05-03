# 🗄️ Database Schema

## Entity Relationship Diagram (ERD)

```
┌─────────────────┐     ┌──────────────────────┐
│      User       │     │       Sensor         │
├─────────────────┤     ├──────────────────────┤
│ id          PK  │     │ id              PK   │
│ email           │     │ sensor_id   UNIQUE   │
│ password        │     │ name                 │
│ name            │     │ type (ENUM)          │
│ role (ENUM)     │     │ latitude             │
│ phone           │     │ longitude            │
│ is_active       │     │ battery_level        │
│ created_at      │     │ connectivity (ENUM)  │
│ updated_at      │     │ installed_at         │
└─────────────────┘     │ last_active_at       │
                        │ is_active            │
                        │ created_at           │
                        │ updated_at           │
                        └──────┬───────────────┘
                               │ 1
                               │
                    ┌──────────┴──────────┐
                    │ N                   │ N
          ┌─────────────────┐   ┌──────────────────┐
          │  WaterLevelLog  │   │   RainfallLog    │
          ├─────────────────┤   ├──────────────────┤
          │ id          PK  │   │ id           PK  │
          │ sensor_id   FK  │   │ sensor_id    FK  │
          │ water_level     │   │ rainfall         │
          │ unit            │   │ unit             │
          │ status (ENUM)   │   │ intensity (ENUM) │
          │ recorded_at     │   │ recorded_at      │
          │ created_at      │   │ created_at       │
          └─────────────────┘   └──────────────────┘

┌─────────────────────┐   ┌──────────────────────┐
│     Threshold       │   │       Alert          │
├─────────────────────┤   ├──────────────────────┤
│ id             PK   │   │ id              PK   │
│ type (ENUM)         │   │ title                │
│ normal_min          │   │ message              │
│ normal_max          │   │ severity (ENUM)      │
│ warning_min         │   │ channels (JSON)      │
│ warning_max         │   │ target_area          │
│ danger_min          │   │ sent_by         FK   │ → User
│ danger_max          │   │ sent_at              │
│ updated_by     FK   │   │ created_at           │
│ updated_at          │   └──────────────────────┘
└─────────────────────┘

┌──────────────────────┐
│  EmergencyContact    │
├──────────────────────┤
│ id              PK   │
│ name                 │
│ phone                │
│ category (ENUM)      │
│ is_active            │
│ created_at           │
│ updated_at           │
└──────────────────────┘
```

## Enums

### UserRole
```
SUPER_ADMIN, ADMIN, FIELD_OFFICER
```

### SensorType
```
WATER_LEVEL, RAINFALL
```

### SensorConnectivity
```
ONLINE, OFFLINE, MAINTENANCE
```

### WaterLevelStatus
```
NORMAL, WARNING, DANGER
```

### RainfallIntensity
```
LIGHT, MODERATE, HEAVY
```

### AlertSeverity
```
INFO, WARNING, DANGER
```

### EmergencyCategory
```
BPBD, SAR, AMBULANCE, POLICE, HOSPITAL, OTHER
```

## Prisma Schema

```prisma
// prisma/schema.prisma

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

enum UserRole {
  SUPER_ADMIN
  ADMIN
  FIELD_OFFICER
}

enum SensorType {
  WATER_LEVEL
  RAINFALL
}

enum SensorConnectivity {
  ONLINE
  OFFLINE
  MAINTENANCE
}

enum WaterLevelStatus {
  NORMAL
  WARNING
  DANGER
}

enum RainfallIntensity {
  LIGHT
  MODERATE
  HEAVY
}

enum AlertSeverity {
  INFO
  WARNING
  DANGER
}

enum EmergencyCategory {
  BPBD
  SAR
  AMBULANCE
  POLICE
  HOSPITAL
  OTHER
}

model User {
  id         String    @id @default(uuid())
  email      String    @unique
  password   String
  name       String
  role       UserRole  @default(FIELD_OFFICER)
  phone      String?
  isActive   Boolean   @default(true)
  createdAt  DateTime  @default(now())
  updatedAt  DateTime  @updatedAt

  alerts     Alert[]
  thresholds Threshold[]

  @@map("users")
}

model Sensor {
  id             String             @id @default(uuid())
  sensorId       String             @unique @map("sensor_id")
  name           String
  type           SensorType
  latitude       Float
  longitude      Float
  batteryLevel   Int?               @map("battery_level")
  connectivity   SensorConnectivity @default(ONLINE)
  installedAt    DateTime?          @map("installed_at")
  lastActiveAt   DateTime?          @map("last_active_at")
  isActive       Boolean            @default(true)
  createdAt      DateTime           @default(now())
  updatedAt      DateTime           @updatedAt

  waterLevelLogs WaterLevelLog[]
  rainfallLogs   RainfallLog[]

  @@map("sensors")
}

model WaterLevelLog {
  id          String           @id @default(uuid())
  sensorId    String           @map("sensor_id")
  waterLevel  Float            @map("water_level")
  unit        String           @default("meter")
  status      WaterLevelStatus
  recordedAt  DateTime         @map("recorded_at")
  createdAt   DateTime         @default(now())

  sensor      Sensor           @relation(fields: [sensorId], references: [id])

  @@index([sensorId, recordedAt])
  @@map("water_level_logs")
}

model RainfallLog {
  id          String            @id @default(uuid())
  sensorId    String            @map("sensor_id")
  rainfall    Float
  unit        String            @default("mm/hour")
  intensity   RainfallIntensity
  recordedAt  DateTime          @map("recorded_at")
  createdAt   DateTime          @default(now())

  sensor      Sensor            @relation(fields: [sensorId], references: [id])

  @@index([sensorId, recordedAt])
  @@map("rainfall_logs")
}

model Threshold {
  id          String    @id @default(uuid())
  type        String    @unique  // 'water_level' or 'rainfall'
  normalMin   Float     @map("normal_min")
  normalMax   Float     @map("normal_max")
  warningMin  Float     @map("warning_min")
  warningMax  Float     @map("warning_max")
  dangerMin   Float     @map("danger_min")
  dangerMax   Float?    @map("danger_max")
  updatedBy   String?   @map("updated_by")
  updatedAt   DateTime  @updatedAt

  user        User?     @relation(fields: [updatedBy], references: [id])

  @@map("thresholds")
}

model Alert {
  id          String        @id @default(uuid())
  title       String
  message     String
  severity    AlertSeverity
  channels    Json          // ["PUSH", "WHATSAPP", "EMAIL"]
  targetArea  String?       @map("target_area")
  sentBy      String        @map("sent_by")
  sentAt      DateTime      @default(now()) @map("sent_at")
  createdAt   DateTime      @default(now())

  user        User          @relation(fields: [sentBy], references: [id])

  @@map("alerts")
}

model EmergencyContact {
  id          String            @id @default(uuid())
  name        String
  phone       String
  category    EmergencyCategory
  isActive    Boolean           @default(true)
  createdAt   DateTime          @default(now())
  updatedAt   DateTime          @updatedAt

  @@map("emergency_contacts")
}
```

## Indexes

| Table | Columns | Purpose |
|-------|---------|---------|
| water_level_logs | (sensor_id, recorded_at) | Query historis per sensor |
| rainfall_logs | (sensor_id, recorded_at) | Query historis per sensor |
| users | (email) UNIQUE | Login lookup |
| sensors | (sensor_id) UNIQUE | Sensor identification |
