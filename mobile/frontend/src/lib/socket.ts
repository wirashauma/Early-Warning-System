import { io, type Socket } from "socket.io-client";
import { WS_URL } from "@/constants";

let socket: Socket | null = null;

export function getSocket() {
  if (typeof window === "undefined") return null;
  if (socket) return socket;

  socket = io(WS_URL, {
    transports: ["websocket"],
    reconnectionAttempts: 5,
  });

  return socket;
}
