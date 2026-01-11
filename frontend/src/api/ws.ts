import { type Request, type Response } from "./types";

export function sendWsRequest(socket: WebSocket, request: Request): void {
  socket.send(JSON.stringify(request));
}

export function onWsResponses(
  socket: WebSocket,
  handler: (response: Response) => void,
): () => void {
  const listener = (event: MessageEvent) => {
    const payload = typeof event.data === "string" ? event.data : String(event.data);
    const responses = parseResponses(payload);
    if (!responses) {
      return;
    }

    for (const response of responses) {
      handler(response);
    }
  };

  socket.addEventListener("message", listener);
  return () => {
    socket.removeEventListener("message", listener);
  };
}

function parseResponses(payload: string): Response[] | null {
  try {
    const parsed = JSON.parse(payload) as Response | Response[];
    return Array.isArray(parsed) ? parsed : [parsed];
  } catch {
    return null;
  }
}
