import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { createWsClient, openSocket } from "../helpers/ws";

describe("integration error cases", () => {
  it("returns unauthenticated error for websocket requests", async () => {
    const socket = await openSocket();
    const client = createWsClient(socket);

    try {
      client.send({ type: "join_room", room_id: "programming" });
      const response = await client.waitForResponse(
        (message) => message.type === "unauthorized",
      );

      assert.equal(response.message, "unauthenticated");
    } finally {
      await client.close();
    }
  });
});
