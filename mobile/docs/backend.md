# ⚙️ Backend Documentation (NestJS)

## Tech Stack

| Teknologi | Fungsi |
|-----------|--------|
| NestJS 11 | Backend Framework |
| TypeScript | Type Safety |
| Prisma | ORM (Database) |
| PostgreSQL | Primary Database |
| Redis | Cache & Real-time Session |
| Socket.IO | WebSocket (Real-time) |
| Passport.js + JWT | Authentication |
| MQTT.js | IoT Sensor Communication |
| Swagger | API Documentation |
| Jest | Testing |

## Struktur Folder

```
backend/
├── src/
│   ├── main.ts                     # Entry point
│   ├── app.module.ts               # Root module
│   ├── app.controller.ts
│   ├── app.service.ts
│   │
│   ├── auth/                       # Authentication Module
│   │   ├── auth.module.ts
│   │   ├── auth.controller.ts
│   │   ├── auth.service.ts
│   │   ├── guards/
│   │   │   ├── jwt-auth.guard.ts
│   │   │   └── roles.guard.ts
│   │   ├── strategies/
│   │   │   └── jwt.strategy.ts
│   │   ├── decorators/
│   │   │   └── roles.decorator.ts
│   │   └── dto/
│   │       ├── login.dto.ts
│   │       └── refresh-token.dto.ts
│   │
│   ├── water-level/                # Water Level Module
│   │   ├── water-level.module.ts
│   │   ├── water-level.controller.ts
│   │   ├── water-level.service.ts
│   │   ├── water-level.gateway.ts  # WebSocket gateway
│   │   └── dto/
│   │       └── water-level.dto.ts
│   │
│   ├── rainfall/                   # Rainfall Module
│   │   ├── rainfall.module.ts
│   │   ├── rainfall.controller.ts
│   │   ├── rainfall.service.ts
│   │   └── dto/
│   │       └── rainfall.dto.ts
│   │
│   ├── sensor/                     # Sensor Management Module
│   │   ├── sensor.module.ts
│   │   ├── sensor.controller.ts
│   │   ├── sensor.service.ts
│   │   └── dto/
│   │       ├── create-sensor.dto.ts
│   │       └── update-sensor.dto.ts
│   │
│   ├── threshold/                  # Threshold Settings Module
│   │   ├── threshold.module.ts
│   │   ├── threshold.controller.ts
│   │   ├── threshold.service.ts
│   │   └── dto/
│   │       └── update-threshold.dto.ts
│   │
│   ├── alert/                      # Alert & Notification Module
│   │   ├── alert.module.ts
│   │   ├── alert.controller.ts
│   │   ├── alert.service.ts
│   │   ├── notification/
│   │   │   ├── notification.service.ts
│   │   │   ├── push.service.ts     # Firebase FCM
│   │   │   ├── whatsapp.service.ts # WhatsApp API
│   │   │   └── email.service.ts    # SMTP Email
│   │   └── dto/
│   │       └── broadcast-alert.dto.ts
│   │
│   ├── report/                     # Report Module
│   │   ├── report.module.ts
│   │   ├── report.controller.ts
│   │   ├── report.service.ts
│   │   └── generators/
│   │       ├── pdf.generator.ts
│   │       └── excel.generator.ts
│   │
│   ├── user/                       # User Management Module
│   │   ├── user.module.ts
│   │   ├── user.controller.ts
│   │   ├── user.service.ts
│   │   └── dto/
│   │       ├── create-user.dto.ts
│   │       └── update-user.dto.ts
│   │
│   ├── emergency-contact/          # Emergency Contact Module
│   │   ├── emergency-contact.module.ts
│   │   ├── emergency-contact.controller.ts
│   │   └── emergency-contact.service.ts
│   │
│   ├── mqtt/                       # MQTT IoT Module
│   │   ├── mqtt.module.ts
│   │   └── mqtt.service.ts         # Subscribe to sensor topics
│   │
│   ├── common/                     # Shared utilities
│   │   ├── decorators/
│   │   ├── filters/
│   │   │   └── http-exception.filter.ts
│   │   ├── interceptors/
│   │   │   └── response.interceptor.ts
│   │   ├── pipes/
│   │   └── enums/
│   │       ├── status.enum.ts      # NORMAL, WARNING, DANGER
│   │       ├── role.enum.ts        # ADMIN, SUPER_ADMIN, FIELD_OFFICER
│   │       └── intensity.enum.ts   # LIGHT, MODERATE, HEAVY
│   │
│   └── prisma/                     # Prisma Service
│       ├── prisma.module.ts
│       └── prisma.service.ts
│
├── prisma/
│   ├── schema.prisma               # Database schema
│   ├── migrations/                 # Database migrations
│   └── seed.ts                     # Seed data
│
├── test/
│   ├── app.e2e-spec.ts
│   └── jest-e2e.json
│
├── nest-cli.json
├── tsconfig.json
├── tsconfig.build.json
├── package.json
└── .env
```

## NestJS Modules Overview

```
AppModule
├── AuthModule          → Login, JWT, Guards, Roles
├── WaterLevelModule    → Real-time water level data + WebSocket
├── RainfallModule      → Rainfall intensity data
├── SensorModule        → Sensor CRUD & health monitoring
├── ThresholdModule     → Threshold configuration
├── AlertModule         → Alert broadcast & notification services
├── ReportModule        → PDF/Excel report generation
├── UserModule          → User CRUD (Admin management)
├── EmergencyContactModule → Emergency contacts CRUD
├── MqttModule          → IoT sensor data subscriber
└── PrismaModule        → Database connection
```

## Environment Variables

```env
# .env
# Application
PORT=3001
NODE_ENV=development

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/ews_db

# Redis
REDIS_HOST=localhost
REDIS_PORT=6379

# JWT
JWT_SECRET=your_super_secret_key
JWT_EXPIRATION=1h
JWT_REFRESH_SECRET=your_refresh_secret_key
JWT_REFRESH_EXPIRATION=7d

# MQTT
MQTT_BROKER_URL=mqtt://localhost:1883
MQTT_USERNAME=
MQTT_PASSWORD=

# Google Maps
GOOGLE_MAPS_API_KEY=your_google_maps_api_key

# Firebase (Push Notification)
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_PRIVATE_KEY=your_private_key
FIREBASE_CLIENT_EMAIL=your_client_email

# WhatsApp API
WHATSAPP_API_URL=https://api.whatsapp.com
WHATSAPP_API_TOKEN=your_token

# Email (SMTP)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your_email@gmail.com
SMTP_PASS=your_app_password
```

## Scripts

```bash
npm run start           # Start server
npm run start:dev       # Start in watch mode (development)
npm run start:prod      # Start production server
npm run build           # Build project
npm run test            # Run unit tests
npm run test:e2e        # Run e2e tests
npm run test:cov        # Run tests with coverage
```

## Database Commands (Prisma)

```bash
npx prisma generate     # Generate Prisma Client
npx prisma migrate dev  # Run migrations (development)
npx prisma migrate deploy  # Run migrations (production)
npx prisma db seed      # Seed database
npx prisma studio       # Open Prisma Studio (GUI)
```

## API Documentation (Swagger)

Setelah server berjalan, akses Swagger UI di:
```
http://localhost:3001/api/docs
```
