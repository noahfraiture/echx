import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { createIdentity } from "../config";
import { createWsClient, openSocket } from "../helpers/ws";

const ROOM_NAME = `integration-room-${Date.now()}`;

describe("websocket create room", () => {
  it("creates a room and allows joining", async () => {
    const socket = await openSocket();
    const client = createWsClient(socket);

    try {
      const identity = createIdentity("create-room");
      client.send({ type: "connect", token: identity.token, name: identity.name });
      await client.waitForResponse((response) => response.type === "success");

      client.send({ type: "create_room", name: ROOM_NAME, max_size: 8 });
      const createResponse = await client.waitForResponse(
        (response) => response.type === "create_room",
      );
      assert.equal(createResponse.status, "ok");

      client.send({ type: "list_rooms" });
      const listResponse = await client.waitForResponse(
        (response) => response.type === "list_rooms",
      );
      const createdRoom = listResponse.rooms.find((room) => room.id === ROOM_NAME);
      assert.ok(createdRoom);
      assert.equal(createdRoom?.max_size, 8);

      client.send({ type: "join_room", room_id: ROOM_NAME });
      const joinResponse = await client.waitForResponse(
        (response) => response.type === "join_room",
      );
      assert.equal(joinResponse.status, "ok");
    } finally {
      await client.close();
    }
  });

  it("rejects invalid size", async () => {
    const socket = await openSocket();
    const client = createWsClient(socket);

    try {
      const identity = createIdentity("create-room-invalid");
      client.send({ type: "connect", token: identity.token, name: identity.name });
      await client.waitForResponse((response) => response.type === "success");

      client.send({ type: "create_room", name: "invalid-size", max_size: 2 });
      const createResponse = await client.waitForResponse(
        (response) => response.type === "create_room",
      );
      assert.equal(createResponse.status, "error");
      assert.equal(createResponse.reason, "max size must be between 3 and 50");
    } finally {
      await client.close();
    }
  });
});
