import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import "./index.css";
import { TopBar } from "./TopBar.tsx";
import { App } from "./App.tsx";
import { useEffect, useState } from "react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <Main />
  </StrictMode>,
);

const queryClient = new QueryClient();

export function Main() {
  const [socket, setSocket] = useState<WebSocket | null>(null);

  useEffect(() => {
    const nextSocket = new WebSocket(resolveWebSocketUrl());

    const handleOpen = () => {
      setSocket(nextSocket);
    };

    nextSocket.addEventListener("open", handleOpen);

    return () => {
      nextSocket.removeEventListener("open", handleOpen);
      nextSocket.close();
      setSocket(null);
    };
  }, []);

  return (
    <div className="h-screen flex flex-col overflow-hidden">
      <TopBar />
      <div className="flex flex-1 min-h-0 overflow-hidden">
        <QueryClientProvider client={queryClient}>
          <App socket={socket} />
        </QueryClientProvider>
      </div>
    </div>
  );
}

function resolveWebSocketUrl(): string {
  const fromEnv = import.meta.env.VITE_WS_URL as string | undefined;
  if (fromEnv) {
    return fromEnv;
  }

  const url = new URL("/ws", window.location.origin);
  url.protocol = url.protocol === "https:" ? "wss:" : "ws:";

  if (url.hostname === "localhost" && url.port === "5173") {
    url.port = "8080";
  }

  return url.toString();
}
