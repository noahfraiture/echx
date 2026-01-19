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
    } finally {
      await client.close();
    }
  });
});
