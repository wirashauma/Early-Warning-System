# 🚀 Deployment Guide

## Prerequisites

- Docker & Docker Compose
- Node.js >= 18
- Flutter SDK >= 3.x
- PostgreSQL >= 14
- Redis >= 7

---

## Development Setup

### 1. Clone Repository

```bash
git clone https://github.com/wirashauma/Early-Warning-System.git
cd Early-Warning-System
```

### 2. Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Copy environment file
cp .env.example .env
# Edit .env with your configuration

# Run database migrations
npx prisma migrate dev

# Seed initial data
npx prisma db seed

# Start development server
npm run start:dev
```

Server berjalan di: `http://localhost:3001`

### 3. Frontend Setup

```bash
cd frontend

# Install dependencies
npm install

# Copy environment file
cp .env.example .env.local
# Edit .env.local with your configuration

# Start development server
npm run dev
```

Aplikasi berjalan di: `http://localhost:3000`

### 4. Mobile Setup

```bash
cd mobile

# Get dependencies
flutter pub get

# Run on Android Emulator
flutter run

# Run on iOS Simulator (macOS only)
flutter run -d ios
```

---

## Docker Deployment

### docker-compose.yml (Production)

```yaml
version: '3.8'

services:
  # PostgreSQL Database
  postgres:
    image: postgres:16-alpine
    container_name: ews-postgres
    environment:
      POSTGRES_DB: ews_db
      POSTGRES_USER: ews_user
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    restart: unless-stopped

  # Redis Cache
  redis:
    image: redis:7-alpine
    container_name: ews-redis
    ports:
      - "6379:6379"
    restart: unless-stopped

  # NestJS Backend
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: ews-backend
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://ews_user:${DB_PASSWORD}@postgres:5432/ews_db
      - REDIS_HOST=redis
      - REDIS_PORT=6379
    ports:
      - "3001:3001"
    depends_on:
      - postgres
      - redis
    restart: unless-stopped

  # Next.js Frontend
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: ews-frontend
    environment:
      - NEXT_PUBLIC_API_URL=https://api.ews.example.com/api
    ports:
      - "3000:3000"
    depends_on:
      - backend
    restart: unless-stopped

  # Nginx Reverse Proxy
  nginx:
    image: nginx:alpine
    container_name: ews-nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/ssl:/etc/nginx/ssl
    depends_on:
      - frontend
      - backend
    restart: unless-stopped

volumes:
  postgres_data:
```

### Backend Dockerfile

```dockerfile
# backend/Dockerfile
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npx prisma generate
RUN npm run build

FROM node:18-alpine AS runner
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
COPY --from=builder /app/prisma ./prisma
EXPOSE 3001
CMD ["node", "dist/main.js"]
```

### Frontend Dockerfile

```dockerfile
# frontend/Dockerfile
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:18-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public
EXPOSE 3000
CMD ["node", "server.js"]
```

---

## Mobile Build & Release

### Android (APK / AAB)

```bash
cd mobile

# Build APK (debug)
flutter build apk --debug

# Build APK (release)
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

Output:
- APK: `mobile/build/app/outputs/flutter-apk/app-release.apk`
- AAB: `mobile/build/app/outputs/bundle/release/app-release.aab`

### iOS (macOS only)

```bash
cd mobile
flutter build ios --release
```

---

## Nginx Configuration

```nginx
# nginx/nginx.conf
events {
    worker_connections 1024;
}

http {
    upstream frontend {
        server frontend:3000;
    }

    upstream backend {
        server backend:3001;
    }

    server {
        listen 80;
        server_name ews.example.com;

        # Frontend
        location / {
            proxy_pass http://frontend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
        }

        # Backend API
        location /api {
            proxy_pass http://backend;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }

        # WebSocket
        location /ws {
            proxy_pass http://backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "Upgrade";
            proxy_set_header Host $host;
        }
    }
}
```

---

## CI/CD (GitHub Actions - Example)

```yaml
# .github/workflows/deploy.yml
name: Deploy EWS

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build & Push Docker Images
        run: |
          docker compose build
          docker compose push

      - name: Deploy to Server
        run: |
          ssh ${{ secrets.SERVER_USER }}@${{ secrets.SERVER_HOST }} \
            "cd /app/ews && docker compose pull && docker compose up -d"
```
