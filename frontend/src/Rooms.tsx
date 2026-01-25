import { useEffect, useMemo, useState } from "react";
import type { RoomSummary } from "./api/types";

type CreateRoomStatus =
  | { status: "idle" }
  | { status: "pending" }
  | { status: "success" }
  | { status: "error"; message: string };

type RoomsProps = {
  roomID: RoomSummary["id"] | null;
  rooms: RoomSummary[];
  joinedRooms: Set<RoomSummary["id"]>;
  setRoomID: (roomID: RoomSummary["id"]) => void;
  joinRoom: (roomID: RoomSummary["id"]) => void;
  createRoom: (name: string, maxSize: number) => void;
  createRoomStatus: CreateRoomStatus;
  resetCreateRoomStatus: () => void;
  identity: { token: string; name: string };
  renameSelf: (nextName: string) => void;
};

export function formatRoomSize(room: RoomSummary): string | null {
  if (typeof room.current_size !== "number" || typeof room.max_size !== "number") {
    return null;
  }

  return `${room.current_size}/${room.max_size}`;
}

export function Rooms({
  roomID,
  rooms,
  joinedRooms,
  setRoomID,
  joinRoom,
  createRoom,
  createRoomStatus,
  resetCreateRoomStatus,
  identity,
  renameSelf,
}: RoomsProps) {
  const [showForm, setShowForm] = useState(false);
  const [roomName, setRoomName] = useState("");
  const [roomSize, setRoomSize] = useState("12");
  const [pendingName, setPendingName] = useState(identity.name);

  const trimmedName = roomName.trim();
  const trimmedRename = pendingName.trim();
  const parsedSize = Number(roomSize);
  const sizeIsValid = Number.isFinite(parsedSize) && parsedSize >= 3 && parsedSize <= 50;
  const nameIsValid = trimmedName.length >= 3 && trimmedName.length <= 50;
  const renameIsValid = trimmedRename.length >= 3 && trimmedRename.length <= 50;
  const canSubmit = nameIsValid && sizeIsValid && createRoomStatus.status !== "pending";
  const canRename = renameIsValid && trimmedRename !== identity.name;

  const createRoomMessage = useMemo(() => {
    if (createRoomStatus.status !== "error") {
      return "";
    }
    return createRoomStatus.message;
  }, [createRoomStatus.status]);

  const maxRoomNameLength = useMemo(() => {
    if (rooms.length === 0) {
      return 12;
    }

    const longest = Math.max(...rooms.map((room) => room.name.length));
    return Math.min(20, Math.max(12, longest));
  }, [rooms]);

  const panelWidth = `calc(${maxRoomNameLength}ch + 18rem)`;
  const minPanelWidth = "calc(12ch + 18rem)";
  const maxPanelWidth = "calc(20ch + 18rem)";

  useEffect(() => {
    if (createRoomStatus.status !== "success") {
      return;
    }
    setShowForm(false);
    setRoomName("");
    setRoomSize("12");
    resetCreateRoomStatus();
  }, [createRoomStatus.status, resetCreateRoomStatus]);

  useEffect(() => {
    setPendingName(identity.name);
  }, [identity.name]);

  return (
    <div
      className="p-4 min-w-0 shrink-0"
      style={{ width: panelWidth, minWidth: minPanelWidth, maxWidth: maxPanelWidth }}
    >
      <div className="h-full w-full card overflow-hidden border border-base-300 bg-base-100 shadow-lg">
        <div className="bg-linear-to-r from-base-200 via-base-100 to-base-200 px-5 py-4">
          <div className="flex items-center justify-between gap-3">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.2em] text-base-content/60">Rooms</p>
              <h2 className="text-lg font-semibold text-base-content">Where to?</h2>
            </div>
            <div className="flex items-center gap-2">
              <span className="badge badge-outline badge-sm">{rooms.length}</span>
              <button
                type="button"
                onClick={() => {
                  setShowForm((prev) => !prev);
                  resetCreateRoomStatus();
                }}
                className="btn btn-xs btn-primary rounded-full"
              >
                New
              </button>
            </div>
          </div>
        </div>
        <div className="card-body gap-3">
          <div className="rounded-2xl border border-base-200 bg-base-100 p-4 shadow-sm">
            <div className="flex flex-col gap-3">
              <label className="form-control">
                <div className="label">
                  <span className="label-text text-xs uppercase tracking-[0.2em] text-base-content/60">Your name</span>
                  <span className="label-text-alt text-xs text-base-content/50">3-50 chars</span>
                </div>
                <input
                  type="text"
                  value={pendingName}
                  onChange={(event) => setPendingName(event.target.value)}
                  className="input input-sm input-bordered w-full"
                  placeholder="e.g. Trinity"
                />
              </label>
              <div className="flex items-center justify-end gap-2">
                <button
                  type="button"
                  disabled={!canRename}
                  onClick={() => {
                    if (!canRename) {
                      return;
                    }
                    renameSelf(trimmedRename);
                  }}
                  className="btn btn-primary btn-xs"
                >
                  Update name
                </button>
              </div>
            </div>
          </div>
          {showForm ? (
            <div className="rounded-2xl border border-base-200 bg-base-100 p-4 shadow-sm">
              <div className="flex flex-col gap-3">
                <label className="form-control">
                  <div className="label">
                    <span className="label-text text-xs uppercase tracking-[0.2em] text-base-content/60">
                      Room name
                    </span>
                    <span className="label-text-alt text-xs text-base-content/50">3-50 chars</span>
                  </div>
                  <input
                    type="text"
                    value={roomName}
                    onChange={(event) => setRoomName(event.target.value)}
                    className="input input-sm input-bordered w-full"
                    placeholder="e.g. Coffee chat"
                  />
                </label>
                <label className="form-control">
                  <div className="label">
                    <span className="label-text text-xs uppercase tracking-[0.2em] text-base-content/60">
                      Max size
                    </span>
                    <span className="label-text-alt text-xs text-base-content/50">3-50</span>
                  </div>
                  <input
                    type="number"
                    min={3}
                    max={50}
                    value={roomSize}
                    onChange={(event) => setRoomSize(event.target.value)}
                    className="input input-sm input-bordered w-full"
                  />
                </label>
                {createRoomStatus.status === "error" ? (
                  <div className="alert alert-error rounded-2xl px-3 py-2 text-xs">
                    {createRoomMessage}
                  </div>
                ) : null}
                <div className="flex items-center justify-end gap-2">
                  <button
                    type="button"
                    onClick={() => {
                      setShowForm(false);
                      resetCreateRoomStatus();
                    }}
                    className="btn btn-ghost btn-xs"
                  >
                    Cancel
                  </button>
                  <button
                    type="button"
                    disabled={!canSubmit}
                    onClick={() => {
                      if (!canSubmit) {
                        return;
                      }
                      createRoom(trimmedName, parsedSize);
                    }}
                    className="btn btn-primary btn-xs"
                  >
                    {createRoomStatus.status === "pending" ? "Creating..." : "Create room"}
                  </button>
                </div>
              </div>
            </div>
          ) : null}
          <div className="flex flex-col gap-2">
            {rooms.map((room) => {
              const isActive = room.id === roomID;
              const isJoined = joinedRooms.has(room.id) || room.joined;
              return (
                <div
                  key={room.id}
                  className={[
                    "group relative flex items-center justify-between rounded-2xl px-4 py-3 text-left",
                    "border border-base-200 bg-base-100 transition-all",
                    "hover:border-base-300 hover:bg-base-200/70",
                    isActive ? "border-primary/40 bg-primary/10 ring-2 ring-primary/30" : "",
                    isJoined ? "font-semibold" : "font-medium text-base-content/80",
                  ].join(" ")}
                >
                  <button
                    type="button"
                    onClick={() => {
                      if (isActive) {
                        setRoomID("");
                        return;
                      }
                      if (isJoined) {
                        setRoomID(room.id);
                      }
                    }}
                    className={[
                      "flex min-w-0 flex-1 items-center justify-between gap-3 text-left",
                      isJoined || isActive ? "cursor-pointer" : "cursor-not-allowed",
                    ].join(" ")}
                  >
                    <span className="flex min-w-0 items-center gap-3">
                      <span
                        className={[
                          "h-2.5 w-2.5 rounded-full",
                          isActive
                            ? "bg-primary shadow-[0_0_0_4px_rgba(0,0,0,0.06)]"
                            : isJoined
                              ? "bg-success shadow-[0_0_0_4px_rgba(16,185,129,0.18)]"
                              : "bg-base-300",
                        ].join(" ")}
                      />
                      <span className="truncate">{room.name}</span>
                    </span>
                    <span className="flex items-center gap-2">
                      {formatRoomSize(room) ? (
                        <span className="text-[0.65rem] font-semibold text-base-content/60">
                          {formatRoomSize(room)}
                        </span>
                      ) : null}
                      <span
                        className={[
                          "badge badge-xs uppercase tracking-wide",
                          isActive
                            ? "badge-primary text-primary-content"
                            : isJoined
                              ? "badge-success text-success-content"
                              : "badge-ghost",
                        ].join(" ")}
                      >
                        {isActive ? "selected" : isJoined ? "joined" : "open"}
                      </span>
                    </span>
                  </button>
                  <button
                    type="button"
                    onClick={() => joinRoom(room.id)}
                    disabled={isJoined}
                    className="btn btn-xs rounded-full border-base-300 bg-base-100 text-base-content shadow-sm hover:border-primary/40 hover:bg-primary/10 disabled:opacity-60"
                  >
                    Join
                  </button>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}
