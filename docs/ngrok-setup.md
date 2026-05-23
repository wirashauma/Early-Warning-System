# Ngrok Setup for Early Warning System

Use ngrok when you want the ESP8266, mobile app, or a browser client to reach a backend that is running on your local machine.

## What ngrok changes

- Exposes the local backend port to the internet through a public URL.
- Lets devices on another Wi-Fi or location call the backend without a LAN IP.
- Avoids hardcoding `192.168.x.x` addresses in device firmware.

## Backend

1. Run the NestJS backend on its normal port, usually `4101`.
2. Start an ngrok tunnel for that port.
3. Copy the HTTPS forwarding URL from ngrok.

Example target:

- Local backend: `http://localhost:4101`
- Public tunnel: `https://your-ngrok-domain.ngrok-free.app`

The ingest endpoint becomes:

- `https://your-ngrok-domain.ngrok-free.app/api/iot/ingest`

## Backend CORS

The backend accepts ngrok origins in development when:

- `ALLOW_NGROK_ORIGINS=true`

This is already documented in `backend/.env.example`.

## ESP8266 / Arduino

Point the firmware to the public ngrok URL instead of the LAN IP.

Example:

- old: `http://192.168.1.12:3001/api/iot/ingest`
- new: `https://your-ngrok-domain.ngrok-free.app/api/iot/ingest`

## Web frontend

If the browser frontend calls the backend directly, set:

- `NEXT_PUBLIC_API_URL`
- `NEXT_PUBLIC_WS_URL`

Use the ngrok HTTPS/WSS URL.

Example:

- `NEXT_PUBLIC_API_URL="https://your-ngrok-domain.ngrok-free.app/api"`
- `NEXT_PUBLIC_WS_URL="wss://your-ngrok-domain.ngrok-free.app"`

## Mobile app

For mobile, update the API base URL in `mobile/.env` to the ngrok URL.

Example:

- `API_URL="https://your-ngrok-domain.ngrok-free.app/api"`

## Notes

- ngrok free domains can change when the tunnel restarts.
- If you need a stable domain, use a paid ngrok plan or a custom domain.
- Always prefer `https` / `wss` when the tunnel is public.