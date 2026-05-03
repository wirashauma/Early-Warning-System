# 🏗️ Arsitektur Sistem

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CLIENT LAYER                                │
│                                                                     │
│   ┌───────────────┐         ┌───────────────┐                      │
│   │  Next.js Web  │         │ Flutter Mobile │                      │
│   │  (Frontend)   │         │    (Mobile)    │                      │
│   │  Port: 3000   │         │   Android/iOS  │                      │
│   └──────┬────────┘         └──────┬─────────┘                      │
│          │                         │                                │
└──────────┼─────────────────────────┼────────────────────────────────┘
           │  REST API + WebSocket   │
           │                         │
┌──────────┼─────────────────────────┼────────────────────────────────┐
│          ▼                         ▼          API LAYER             │
│   ┌─────────────────────────────────────────┐                      │
│   │           NestJS Backend                │                      │
│   │           Port: 3001                    │                      │
│   │                                         │                      │
│   │  ┌──────────┐  ┌──────────┐  ┌───────┐ │                      │
│   │  │   Auth   │  │  Sensor  │  │ Alert │ │                      │
│   │  │  Module  │  │  Module  │  │Module │ │                      │
│   │  └──────────┘  └──────────┘  └───────┘ │                      │
│   │  ┌──────────┐  ┌──────────┐  ┌───────┐ │                      │
│   │  │  Water   │  │ Rainfall │  │Report │ │                      │
│   │  │  Level   │  │  Module  │  │Module │ │                      │
│   │  └──────────┘  └──────────┘  └───────┘ │                      │
│   └──────┬──────────────┬───────────┬───────┘                      │
│          │              │           │                                │
└──────────┼──────────────┼───────────┼────────────────────────────────┘
           │              │           │
┌──────────┼──────────────┼───────────┼────────────────────────────────┐
│          ▼              ▼           ▼        DATA LAYER             │
│   ┌─────────────┐  ┌──────────┐  ┌───────────────┐                │
│   │ PostgreSQL  │  │  Redis   │  │ MQTT Broker   │                │
│   │  Database   │  │  Cache   │  │ (IoT Sensors) │                │
│   └─────────────┘  └──────────┘  └───────────────┘                │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                     EXTERNAL SERVICES                               │
│                                                                     │
│   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│   │ Google Maps  │  │   Firebase   │  │  WhatsApp    │            │
│   │     API      │  │     FCM      │  │   API        │            │
│   └──────────────┘  └──────────────┘  └──────────────┘            │
│   ┌──────────────┐                                                 │
│   │  SMTP Email  │                                                 │
│   └──────────────┘                                                 │
└─────────────────────────────────────────────────────────────────────┘
```

## Data Flow

### 1. Sensor Data Flow (IoT → Dashboard)
```
IoT Sensor → MQTT Broker → NestJS (MQTT Subscriber)
                                  ↓
                           Data Processing
                           (Validate & Store)
                                  ↓
                           PostgreSQL (Store)
                                  ↓
                           WebSocket (Broadcast)
                                  ↓
                        Web Dashboard / Mobile App
```

### 2. Alert Flow (Threshold Exceeded)
```
Water Level > Threshold → NestJS Alert Module
                                  ↓
                        ┌─────────┼─────────┐
                        ↓         ↓         ↓
                   Push Notif  WhatsApp   Email
                    (FCM)       API      (SMTP)
                        ↓         ↓         ↓
                     Mobile    WhatsApp   Email
                      App      Users     Users
```

### 3. Admin Management Flow
```
Admin Login → JWT Authentication → Admin Dashboard
                                        ↓
                              ┌─────────┼─────────────┐
                              ↓         ↓             ↓
                          Manage     Set Threshold  Broadcast
                          Sensors    Configuration   Alert
                              ↓         ↓             ↓
                           Database  Database    Notification
                           Update    Update      Service
```

## Struktur Folder Monorepo

```
Early-Warning-System/
├── frontend/          # Next.js Web Application
├── backend/           # NestJS REST API Server
├── mobile/            # Flutter Mobile Application
├── docs/              # Project Documentation
├── .gitignore
└── README.md
```

## Teknologi & Versi

| Teknologi | Versi | Fungsi |
|-----------|-------|--------|
| Node.js | >= 18.x | Runtime JavaScript |
| Next.js | Latest | Frontend Web Framework |
| NestJS | 11.x | Backend API Framework |
| Flutter | >= 3.x | Mobile Framework |
| PostgreSQL | >= 14 | Primary Database |
| Redis | >= 7 | Cache & Session Store |
| MQTT | v5 | IoT Communication Protocol |
| Docker | Latest | Containerization |

## Port Allocation

| Service | Port | Keterangan |
|---------|------|------------|
| Frontend (Next.js) | 3000 | Web Application |
| Backend (NestJS) | 3001 | REST API |
| PostgreSQL | 5432 | Database |
| Redis | 6379 | Cache |
| MQTT Broker | 1883 | IoT Sensor Communication |
