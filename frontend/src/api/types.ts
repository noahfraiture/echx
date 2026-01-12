export type Request =
  | { type: "chat"; message: string; room_id: string }
  | { type: "connect"; token: string; name: string }
  | { type: "list_rooms" }
  | { type: "join_room"; room_id: string };

export type ChatUser = {
  name: string | null;
};

export type Chat = {
  content: string;
  user: ChatUser;
};

export type RoomSummary = {
  id: string;
  name: string;
  joined: boolean;
};

export type Response =
  | { type: "room_event"; chat: Chat }
  | { type: "error"; message: string }
  | { type: "list_rooms"; rooms: RoomSummary[] }
  | { type: "join_room"; status: "ok"; reason: null }
  | { type: "join_room"; status: "error"; reason: string };
