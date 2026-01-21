import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { formatRoomSize } from "./Rooms";
import type { RoomSummary } from "./api/types";

describe("formatRoomSize", () => {
  it("returns count/capacity when both values exist", () => {
    const room: RoomSummary = {
      id: "programming",
      name: "Programming",
      joined: false,
      current_size: 3,
      max_size: 10,
    };

    assert.equal(formatRoomSize(room), "3/10");
  });

  it("returns null when values are missing", () => {
    const room: RoomSummary = {
      id: "cinema",
      name: "Cinema",
      joined: true,
    };

    assert.equal(formatRoomSize(room), null);
  });

  it("returns null when only one value exists", () => {
    const room: RoomSummary = {
      id: "games",
      name: "Games",
      joined: false,
      current_size: 4,
    };

    assert.equal(formatRoomSize(room), null);
  });
});
