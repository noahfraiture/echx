import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import "./index.css";
import { TopBar } from "./TopBar.tsx";
import { App } from "./App.tsx";
import { useEffect, useState } from "react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { useWsRequest } from "./hooks/useWsRequest";
import { type Request } from "./api/types";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <Main />
  </StrictMode>,
);

const queryClient = new QueryClient();

export function Main() {
  const [socket, setSocket] = useState<WebSocket | null>(null);
  const [identity, setIdentity] = useState(() => loadIdentity());
  const connectRequest = useWsRequest(socket, undefined);

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

  useEffect(() => {
    saveIdentity(identity);
  }, [identity]);

  useEffect(() => {
    if (!identity.name.trim()) {
      return;
    }

    const request: Request = { type: "connect", token: identity.token, name: identity.name };
    connectRequest(request);
  }, [connectRequest, identity]);

  const handleRename = (nextName: string) => {
    setIdentity((prev) => ({ ...prev, name: nextName }));
  };

  return (
    <div className="h-screen flex flex-col overflow-hidden">
      <TopBar displayName={identity.name} onRename={handleRename} />
      <div className="flex flex-1 min-h-0 overflow-hidden">
        <QueryClientProvider client={queryClient}>
          <App socket={socket} userName={identity.name} />
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

const IDENTITY_STORAGE_KEY = "echx.identity";
const DEFAULT_NAME = "Guest";

type Identity = {
  token: string;
  name: string;
};

function loadIdentity(): Identity {
  if (typeof window === "undefined") {
    return { token: createToken(), name: DEFAULT_NAME };
  }

  const stored = window.localStorage.getItem(IDENTITY_STORAGE_KEY);
  if (stored) {
    try {
      const parsed = JSON.parse(stored) as Partial<Identity>;
      if (parsed?.token && parsed?.name) {
        return { token: parsed.token, name: parsed.name };
      }
    } catch {
      // ignore invalid storage
    }
  }

  const identity = { token: createToken(), name: DEFAULT_NAME };
  window.localStorage.setItem(IDENTITY_STORAGE_KEY, JSON.stringify(identity));
  return identity;
}

function saveIdentity(identity: Identity): void {
  if (typeof window === "undefined") {
    return;
  }

  window.localStorage.setItem(IDENTITY_STORAGE_KEY, JSON.stringify(identity));
}

function createToken(): string {
  if (typeof crypto !== "undefined" && "randomUUID" in crypto) {
    return crypto.randomUUID();
  }
  return `token-${Date.now()}`;
}
