import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { createIdentity } from "../config";
import { createWsClient, openSocket } from "../helpers/ws";

describe("websocket chat broadcast", () => {
  it("broadcasts messages to other joined clients", async () => {
    const senderSocket = await openSocket();
    const receiverSocket = await openSocket();
    const sender = createWsClient(senderSocket);
    const receiver = createWsClient(receiverSocket);

    try {
      const senderIdentity = createIdentity("sender");
      const receiverIdentity = createIdentity("receiver");

      sender.send({ type: "connect", token: senderIdentity.token, name: senderIdentity.name });
      receiver.send({ type: "connect", token: receiverIdentity.token, name: receiverIdentity.name });

      await Promise.all([
        sender.waitForResponse((response) => response.type === "success"),
        receiver.waitForResponse((response) => response.type === "success"),
      ]);

      sender.send({ type: "join_room", room_id: "programming" });
      receiver.send({ type: "join_room", room_id: "programming" });

      const [senderJoin, receiverJoin] = await Promise.all([
        sender.waitForResponse((response) => response.type === "join_room"),
        receiver.waitForResponse((response) => response.type === "join_room"),
      ]);

      assert.equal(senderJoin.status, "ok");
      assert.equal(receiverJoin.status, "ok");

      receiver.send({ type: "list_rooms" });
      const receiverRooms = await receiver.waitForResponse(
        (response) => response.type === "list_rooms",
      );
      const receiverRoom = receiverRooms.rooms.find((room) => room.id === "programming");
      assert.equal(receiverRoom?.joined, true);

      const message = "hello from integration";
      const messageId = `msg-${Date.now()}`;
      sender.send({ type: "chat", message, room_id: "programming", message_id: messageId });

      const event = await receiver.waitForResponse(
        (response) => response.type === "room_event" && response.chat.content === message,
        2000,
      );

      assert.equal(event.type, "room_event");
      assert.equal(event.chat.user.name, senderIdentity.name);
    } finally {
      await Promise.all([sender.close(), receiver.close()]);
    }
  });
});
