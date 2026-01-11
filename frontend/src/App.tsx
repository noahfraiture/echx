import { ChatPanel } from "./ChatPanel";
import { EmptyChat } from "./EmptyChat";
import { Rooms } from "./Rooms";
import { useCallback, useMemo, useState } from "react";
import { type Chat, type Response, type RoomSummary } from "./api/types";
import { useWsRequest } from "./hooks/useWsRequest";

type AppProps = {
  socket: WebSocket | null;
};

export function App({ socket }: AppProps) {
  const [roomID, setRoomID] = useState<string>("");
  const [rooms, setRooms] = useState<RoomSummary[]>([]);
  const [messagesByRoom, setMessagesByRoom] = useState<Record<string, Chat[]>>({});

  const onMessageSent = (content: string) => {
    const chat: Chat = { content, user: { name: "You" } };

    if (!roomID) {
      return;
    }

    setMessagesByRoom((prev) => ({
      ...prev,
      [roomID]: [...(prev[roomID] ?? []), chat],
    }));
  };

  const listRoomsRequest = useMemo(() => ({ type: "list_rooms" as const }), []);
  const handleListRooms = useCallback((response: Response) => {
    if (response.type === "list_rooms") {
      setRooms(response.rooms);
    }
  }, []);

  useWsRequest(socket, listRoomsRequest, handleListRooms);

  return (
    <>
      {roomID ? <ChatPanel messages={messagesByRoom[roomID] ?? []} onMessageSent={onMessageSent} /> : <EmptyChat />}
      <Rooms roomID={roomID} rooms={rooms} setRoomID={setRoomID} />
    </>
  );
}
