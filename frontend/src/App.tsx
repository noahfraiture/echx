import { ChatPanel } from "./ChatPanel";
import { EmptyChat } from "./EmptyChat";
import { Rooms } from "./Rooms";
import { useCallback, useEffect, useState } from "react";
import { type Chat, type Response, type RoomSummary } from "./api/types";
import { useWsRequest } from "./hooks/useWsRequest";
import { type Request } from "./api/types";

type AppProps = {
  socket: WebSocket | null;
};

export function App({ socket }: AppProps) {
  const [roomID, setRoomID] = useState<string>("");
  const [rooms, setRooms] = useState<RoomSummary[]>([]);
  const [messagesByRoom, setMessagesByRoom] = useState<Record<string, Chat[]>>({});

  const handleListRooms = useCallback((response: Response) => {
    if (response.type === "list_rooms") {
      setRooms(response.rooms);
    }
  }, []);

  const listRoomsRequest = useWsRequest(socket, handleListRooms);
  useEffect(() => {
    listRoomsRequest({ type: "list_rooms" });
  }, [listRoomsRequest]);

  const onMessageSent = (content: string) => {
    const chat: Chat = { content, user: { name: "You" } };

    if (!roomID) {
      return;
    }

    setMessagesByRoom((prev) => ({
      ...prev,
      [roomID]: [...(prev[roomID] ?? []), chat],
    }));

    const chatRequest: Request = { type: "chat", message: content };
    listRoomsRequest(chatRequest);
  };

  return (
    <>
      {roomID ? <ChatPanel messages={messagesByRoom[roomID] ?? []} onMessageSent={onMessageSent} /> : <EmptyChat />}
      <Rooms roomID={roomID} rooms={rooms} setRoomID={setRoomID} />
    </>
  );
}
