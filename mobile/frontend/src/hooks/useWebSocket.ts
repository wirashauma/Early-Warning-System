"use client";

import { useEffect, useState } from "react";
import { getSocket } from "@/lib/socket";

export function useWebSocket<T>(eventName: string, initialValue: T) {
  const [data, setData] = useState<T>(initialValue);
  const [connected, setConnected] = useState(false);

  useEffect(() => {
    const socket = getSocket();
    if (!socket) return;

    const onConnect = () => setConnected(true);
    const onDisconnect = () => setConnected(false);
    const onEvent = (payload: T) => setData(payload);

    socket.on("connect", onConnect);
    socket.on("disconnect", onDisconnect);
    socket.on(eventName, onEvent);

    return () => {
      socket.off("connect", onConnect);
      socket.off("disconnect", onDisconnect);
      socket.off(eventName, onEvent);
    };
  }, [eventName]);

  return { data, connected };
}
