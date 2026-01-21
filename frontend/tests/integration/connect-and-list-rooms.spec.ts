import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { createIdentity } from "../config";
import { createWsClient, openSocket } from "../helpers/ws";

const REQUIRED_ROOMS = ["programming", "cinema"];

describe("websocket connect and list rooms", () => {
  it("connects then lists rooms", async () => {
    const socket = await openSocket();
    const client = createWsClient(socket);

    try {
      const identity = createIdentity("list");
      client.send({ type: "connect", token: identity.token, name: identity.name });
      await client.waitForResponse((response) => response.type === "success");

      client.send({ type: "list_rooms" });
      const response = await client.waitForResponse(
        (message) => message.type === "list_rooms",
      );

      const roomIds = response.rooms.map((room) => room.id);
      for (const roomId of REQUIRED_ROOMS) {
        assert.ok(roomIds.includes(roomId));
      }

      const roomsById = new Map(response.rooms.map((room) => [room.id, room]));
      for (const roomId of REQUIRED_ROOMS) {
        const room = roomsById.get(roomId);
        assert.ok(room, `expected room ${roomId} in list`);
        assert.equal(typeof room?.current_size, "number");
        assert.equal(typeof room?.max_size, "number");
        assert.ok((room?.current_size ?? 0) >= 0);
        assert.ok((room?.max_size ?? 0) >= (room?.current_size ?? 0));
      }
    } finally {
      await client.close();
    }
  });
});
