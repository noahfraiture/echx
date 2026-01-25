import { ChatPanel, type ChatMessage } from "./ChatPanel";
import { EmptyChat } from "./EmptyChat";
import { Rooms } from "./Rooms";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { type Chat, type Response, type RoomSummary } from "./api/types";
import { useWsRequest } from "./hooks/useWsRequest";
import { type Request } from "./api/types";

type AppProps = {
  socket: WebSocket | null;
};

type Identity = {
  token: string;
  name: string;
};

export function App({ socket }: AppProps) {
  const [roomID, setRoomID] = useState<string>("");
  const [rooms, setRooms] = useState<RoomSummary[]>([]);
  const [joinedRooms, setJoinedRooms] = useState<Set<string>>(new Set());
  const [messagesByRoom, setMessagesByRoom] = useState<Record<string, ChatMessage[]>>({});
  const [isConnected, setIsConnected] = useState(false);
  const [createRoomStatus, setCreateRoomStatus] = useState<
    | { status: "idle" }
    | { status: "pending" }
    | { status: "success" }
    | { status: "error"; message: string }
  >({ status: "idle" });
  const [pendingCreateRoom, setPendingCreateRoom] = useState<{
    name: string;
    maxSize: number;
  } | null>(null);
  const hasSentConnect = useRef(false);
  const pendingTimers = useRef<Map<string, number>>(new Map());
  const [identity, setIdentity] = useState<Identity>(() => createIdentity());

  const handleListRooms = useCallback((response: Response) => {
    if (response.type === "list_rooms") {
      setRooms(response.rooms);
    }
  }, []);

  const handleConnectResponse = useCallback((response: Response) => {
    if (response.type === "error") {
      console.warn("connect failed", response.message);
    }
  }, []);

  const handleRoomEvent = useCallback(
    (response: Response) => {
      if (response.type !== "room_event") {
        return;
      }

      if (!roomID) {
        return;
      }

      const messageId = response.chat.message_id;
      const timer = pendingTimers.current.get(messageId);
      if (timer) {
        window.clearTimeout(timer);
        pendingTimers.current.delete(messageId);
      }

      setMessagesByRoom((prev) => {
        const existing = prev[roomID] ?? [];
        const matchIndex = existing.findIndex((message) => message.chat.message_id === messageId);

        if (matchIndex >= 0) {
          const nextMessages = [...existing];
          nextMessages[matchIndex] = { chat: response.chat, status: "confirmed" };
          return { ...prev, [roomID]: nextMessages };
        }

        return {
          ...prev,
          [roomID]: [...existing, { chat: response.chat, status: "confirmed" }],
        };
      });
    },
    [roomID],
  );

  const connectRequest = useWsRequest(socket, handleConnectResponse);
  const listRoomsRequest = useWsRequest(socket, handleListRooms);
  useWsRequest(socket, handleRoomEvent);

  const renameSelf = useCallback(
    (nextName: string) => {
      const trimmed = nextName.trim();
      if (!trimmed || trimmed === identity.name) {
        return;
      }

      setIdentity((prev) => ({ ...prev, name: trimmed }));
      connectRequest({ type: "connect", token: identity.token, name: trimmed });
    },
    [connectRequest, identity.name, identity.token],
  );

  const handleCreateRoom = useCallback(
    (response: Response) => {
      if (response.type !== "create_room") {
        return;
      }

      if (response.status === "ok") {
        setCreateRoomStatus({ status: "success" });
        listRoomsRequest({ type: "list_rooms" });
        return;
      }

      setCreateRoomStatus({ status: "error", message: response.reason });
      setPendingCreateRoom(null);
    },
    [listRoomsRequest],
  );

  useWsRequest(socket, handleCreateRoom);

  const joinRoomRequest = useWsRequest(socket, undefined); // TODO : add callback
  const joinRoom = useCallback(
    (roomID: RoomSummary["id"]) => {
      const request: Request = { type: "join_room", room_id: roomID };
      joinRoomRequest(request);
      setRoomID(roomID);
      setJoinedRooms((prev) => new Set(prev).add(roomID));
      setRooms((prev) => {
        const existing = prev.find((room) => room.id === roomID);
        if (!existing) {
          return prev;
        }
        return prev.map((room) => {
          if (room.id !== roomID) {
            return room;
          }
          const currentSize = typeof room.current_size === "number" ? room.current_size : 0;
          return { ...room, current_size: currentSize + 1, joined: true };
        });
      });
    },
    [joinRoomRequest],
  );

  useEffect(() => {
    if (!socket || hasSentConnect.current) {
      return;
    }

    connectRequest({ type: "connect", token: identity.token, name: identity.name });
    hasSentConnect.current = true;
    setIsConnected(true);
  }, [socket, connectRequest, identity.name, identity.token]);

  useEffect(() => {
    if (!isConnected) {
      return;
    }

    listRoomsRequest({ type: "list_rooms" });
  }, [isConnected, listRoomsRequest]);

  useEffect(() => {
    if (!pendingCreateRoom || createRoomStatus.status !== "success") {
      return;
    }

    joinRoom(pendingCreateRoom.name);
    setPendingCreateRoom(null);
  }, [createRoomStatus.status, joinRoom, pendingCreateRoom]);

  useEffect(() => {
    if (!isConnected) {
      return;
    }

    let pollTimer: number | null = null;

    const startPolling = () => {
      if (document.visibilityState !== "visible" || pollTimer !== null) {
        return;
      }

      pollTimer = window.setInterval(() => {
        if (document.visibilityState === "visible") {
          listRoomsRequest({ type: "list_rooms" });
        }
      }, 5000);
    };

    const stopPolling = () => {
      if (pollTimer !== null) {
        window.clearInterval(pollTimer);
        pollTimer = null;
      }
    };

    const handleVisibilityChange = () => {
      if (document.visibilityState === "visible") {
        startPolling();
      } else {
        stopPolling();
      }
    };

    startPolling();
    document.addEventListener("visibilitychange", handleVisibilityChange);

    return () => {
      stopPolling();
      document.removeEventListener("visibilitychange", handleVisibilityChange);
    };
  }, [isConnected, listRoomsRequest]);

  useEffect(() => {
    return () => {
      pendingTimers.current.forEach((timer) => window.clearTimeout(timer));
      pendingTimers.current.clear();
    };
  }, []);

  const sendMessageRequest = useWsRequest(socket, undefined);

  const onMessageSent = (content: string) => {
    if (!roomID) {
      return;
    }

    const messageId = createMessageId();
    const chat: Chat = { content, user: { name: identity.name }, message_id: messageId };
    const pendingMessage: ChatMessage = { chat, status: "pending" };

    setMessagesByRoom((prev) => ({
      ...prev,
      [roomID]: [...(prev[roomID] ?? []), pendingMessage],
    }));

    const timeout = window.setTimeout(() => {
      setMessagesByRoom((prev) => {
        const existing = prev[roomID] ?? [];
        const matchIndex = existing.findIndex((message) => message.chat.message_id === messageId);
        if (matchIndex < 0) {
          return prev;
        }

        const nextMessages = [...existing];
        const target = nextMessages[matchIndex];
        if (target.status !== "pending") {
          return prev;
        }

        nextMessages[matchIndex] = { ...target, status: "error" };
        return { ...prev, [roomID]: nextMessages };
      });
      pendingTimers.current.delete(messageId);
    }, 3000);

    pendingTimers.current.set(messageId, timeout);

    const chatRequest: Request = {
      type: "chat",
      message: content,
      room_id: roomID,
      message_id: messageId,
    };
    sendMessageRequest(chatRequest);
  };

  const createRoomRequest = useWsRequest(socket, undefined);
  const createRoom = (name: string, maxSize: number) => {
    setCreateRoomStatus({ status: "pending" });
    setPendingCreateRoom({ name, maxSize });
    const request: Request = { type: "create_room", name, max_size: maxSize };
    createRoomRequest(request);
  };

  const resetCreateRoomStatus = () => {
    setCreateRoomStatus({ status: "idle" });
  };

  if (!isConnected) {
    return <EmptyChat />;
  }

  return (
    <>
      {roomID ? <ChatPanel messages={messagesByRoom[roomID] ?? []} onMessageSent={onMessageSent} /> : <EmptyChat />}
      <Rooms
        roomID={roomID}
        rooms={rooms}
        joinedRooms={joinedRooms}
        setRoomID={setRoomID}
        joinRoom={joinRoom}
        createRoom={createRoom}
        createRoomStatus={createRoomStatus}
        resetCreateRoomStatus={resetCreateRoomStatus}
        identity={identity}
        renameSelf={renameSelf}
      />
    </>
  );
}

function createIdentity(): Identity {
  const token = typeof crypto !== "undefined" && crypto.randomUUID ? crypto.randomUUID() : fallbackId();
  return {
    token,
    name: `guest-${token.slice(0, 6)}`,
  };
}

function createMessageId(): string {
  if (typeof crypto !== "undefined" && crypto.randomUUID) {
    return crypto.randomUUID();
  }
  return `msg-${fallbackId()}`;
}

function fallbackId(): string {
  return Math.random().toString(36).slice(2, 10);
}
