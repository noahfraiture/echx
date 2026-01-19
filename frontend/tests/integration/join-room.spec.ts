import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { createIdentity } from "../config";
import { createWsClient, openSocket } from "../helpers/ws";

describe("websocket join room", () => {
  it("joins a room and marks it joined", async () => {
    const socket = await openSocket();
    const client = createWsClient(socket);

    try {
      const identity = createIdentity("join");
      client.send({ type: "connect", token: identity.token, name: identity.name });
      await client.waitForResponse((response) => response.type === "success");

      client.send({ type: "join_room", room_id: "programming" });
      const joinResponse = await client.waitForResponse(
        (response) => response.type === "join_room",
      );

      assert.equal(joinResponse.status, "ok");

      client.send({ type: "list_rooms" });
      const listResponse = await client.waitForResponse(
        (response) => response.type === "list_rooms",
      );

      const programmingRoom = listResponse.rooms.find((room) => room.id === "programming");
      assert.equal(programmingRoom?.joined, true);
    } finally {
      await client.close();
    }
  });
});
