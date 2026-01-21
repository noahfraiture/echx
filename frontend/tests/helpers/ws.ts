import WebSocket, { type RawData } from "ws";
import type { Request, Response } from "../../src/api/types";
import { RESPONSE_TIMEOUT, WS_URL } from "../config";

export type WsClient = {
  socket: WebSocket;
  send: (request: Request) => void;
  waitForResponse: (
    predicate: (response: Response) => boolean,
    timeoutMs?: number,
  ) => Promise<Response>;
  close: () => Promise<void>;
};

export async function openSocket(url = WS_URL): Promise<WebSocket> {
  const socket = new WebSocket(url);
  await new Promise<void>((resolve, reject) => {
    socket.once("open", resolve);
    socket.once("error", (error) => reject(error));
  });
  return socket;
}

export function createWsClient(socket: WebSocket): WsClient {
  const queue: Response[] = [];
  const pending: Array<{
    predicate: (response: Response) => boolean;
    resolve: (response: Response) => void;
    reject: (error: Error) => void;
    timeoutId: NodeJS.Timeout;
  }> = [];

  const handleMessage = (data: RawData) => {
    const payload = typeof data === "string" ? data : data.toString();
    const responses = parseResponses(payload);
    if (!responses) {
      return;
    }

    for (const response of responses) {
      const pendingIndex = pending.findIndex((entry) => entry.predicate(response));
      if (pendingIndex >= 0) {
        const [entry] = pending.splice(pendingIndex, 1);
        clearTimeout(entry.timeoutId);
        entry.resolve(response);
        continue;
      }
      queue.push(response);
    }
  };

  socket.on("message", handleMessage);

  const send = (request: Request) => {
    socket.send(JSON.stringify(request));
  };

  const waitForResponse = (
    predicate: (response: Response) => boolean,
    timeoutMs = RESPONSE_TIMEOUT,
  ) => {
    const queuedIndex = queue.findIndex(predicate);
    if (queuedIndex >= 0) {
      const [response] = queue.splice(queuedIndex, 1);
      return Promise.resolve(response);
    }

    return new Promise<Response>((resolve, reject) => {
      const timeoutId = setTimeout(() => {
        const index = pending.findIndex((entry) => entry.resolve === resolve);
        if (index >= 0) {
          pending.splice(index, 1);
        }
        reject(new Error("Timed out waiting for response"));
      }, timeoutMs);
      pending.push({ predicate, resolve, reject, timeoutId });
    });
  };

  const close = async () => {
    if (socket.readyState === WebSocket.CLOSED) {
      return;
    }
    await new Promise<void>((resolve) => {
      socket.once("close", () => resolve());
      socket.close();
    });
  };

  return { socket, send, waitForResponse, close };
}

function parseResponses(payload: string): Response[] | null {
  try {
    const parsed = JSON.parse(payload) as Response | Response[];
    return Array.isArray(parsed) ? parsed : [parsed];
  } catch {
    return null;
  }
}
