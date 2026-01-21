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
  const [joinedRooms, setJoinedRooms] = useState<Set<string>>(new Set());
  const [messagesByRoom, setMessagesByRoom] = useState<Record<string, Chat[]>>({});
  const [userName] = useState(() => createGuestName());
  const [userToken] = useState(() => crypto.randomUUID());

  const handleListRooms = useCallback((response: Response) => {
    if (response.type === "list_rooms") {
      setRooms(response.rooms);
    }
  }, []);

  const listRoomsRequest = useWsRequest(socket, handleListRooms);
  useEffect(() => {
    listRoomsRequest({ type: "list_rooms" });
  }, [listRoomsRequest]);

  const sendMessageRequest = useWsRequest(socket, undefined);
  const connectRequest = useWsRequest(socket, undefined);

  useEffect(() => {
    if (!socket) {
      return;
    }

    connectRequest({ type: "connect", token: userToken, name: userName });
  }, [connectRequest, socket, userName, userToken]);

  const onMessageSent = (content: string) => {
    const chat: Chat = { content, user: { name: userName } };

    if (!roomID) {
      return;
    }

    setMessagesByRoom((prev) => ({
      ...prev,
      [roomID]: [...(prev[roomID] ?? []), chat],
    }));

    const chatRequest: Request = { type: "chat", message: content, room_id: roomID };
    sendMessageRequest(chatRequest);
  };

  const joinRoomRequest = useWsRequest(socket, undefined); // TODO : add callback
  const joinRoom = (roomID: RoomSummary["id"]) => {
    const request: Request = { type: "join_room", room_id: roomID };
    joinRoomRequest(request);
    setRoomID(roomID);
    setJoinedRooms((prev) => new Set(prev).add(roomID));
  };

  return (
    <>
      {roomID ? (
        <ChatPanel
          currentUserName={userName}
          messages={messagesByRoom[roomID] ?? []}
          onMessageSent={onMessageSent}
        />
      ) : (
        <EmptyChat />
      )}
      <Rooms roomID={roomID} rooms={rooms} joinedRooms={joinedRooms} setRoomID={setRoomID} joinRoom={joinRoom} />
    </>
  );
}

function createGuestName(): string {
  const adjectives = ["Amber", "Brisk", "Golden", "Quiet", "Sandy", "Silver", "Sunny", "Velvet"];
  const nouns = ["Comet", "Dawn", "Drift", "Ember", "Harbor", "Horizon", "Lumen", "Spark"];
  const adjective = adjectives[Math.floor(Math.random() * adjectives.length)];
  const noun = nouns[Math.floor(Math.random() * nouns.length)];
  const suffix = Math.floor(100 + Math.random() * 900);
  return `${adjective}${noun}${suffix}`;
}
