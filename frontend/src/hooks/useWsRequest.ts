import { useEffect } from "react";
import { type Request, type Response } from "../api/types";
import { onWsResponses, sendWsRequest } from "../api/ws";

export function useWsRequest(
  socket: WebSocket | null,
  request: Request,
  onResponse: undefined | ((response: Response) => void),
): void {
  useEffect(() => {
    if (!socket) {
      return;
    }

    const handleResponse = (response: Response) => {
      if (onResponse === undefined) {
        return;
      }
      onResponse(response);
    };

    const cleanupResponses = onWsResponses(socket, handleResponse);
    const sendRequest = () => sendWsRequest(socket, request);

    if (socket.readyState === WebSocket.OPEN) {
      sendRequest();
    } else {
      socket.addEventListener("open", sendRequest);
    }

    return () => {
      socket.removeEventListener("open", sendRequest);
      cleanupResponses();
    };
  }, [socket, request, onResponse]);
}
