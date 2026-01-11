import { useCallback, useEffect } from "react";
import { type Request, type Response } from "../api/types";
import { onWsResponses, sendWsRequest } from "../api/ws";

// Hook for WebSocket request/response flow.
// - registers a single response listener for the socket
// - returns a send(request) function for imperative use
export function useWsRequest(
  socket: WebSocket | null,
  onResponse: undefined | ((response: Response) => void),
): (request: Request) => void {
  const send = useCallback(
    (request: Request) => {
      if (!socket) {
        return;
      }

      const sendRequest = () => sendWsRequest(socket, request);

      if (socket.readyState === WebSocket.OPEN) {
        sendRequest();
        return;
      }

      const handleOpen = () => {
        socket.removeEventListener("open", handleOpen);
        sendRequest();
      };

      socket.addEventListener("open", handleOpen);
    },
    [socket],
  );

  useEffect(() => {
    if (!socket) {
      return;
    }

    if (onResponse === undefined) {
      return;
    }

    return onWsResponses(socket, onResponse);
  }, [socket, onResponse]);

  return send;
}
