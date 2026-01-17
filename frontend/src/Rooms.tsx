import type { RoomSummary } from "./api/types";

type RoomsProps = {
  roomID: RoomSummary["id"] | null;
  rooms: RoomSummary[];
  joinedRooms: Set<RoomSummary["id"]>;
  setRoomID: (roomID: RoomSummary["id"]) => void;
  joinRoom: (roomID: RoomSummary["id"]) => void;
};

export function Rooms({ roomID, rooms, joinedRooms, setRoomID, joinRoom }: RoomsProps) {
  return (
    <div className="w-72 p-4">
      <div className="h-full w-full card overflow-hidden border border-base-300 bg-base-100 shadow-lg">
        <div className="bg-linear-to-r from-base-200 via-base-100 to-base-200 px-5 py-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.2em] text-base-content/60">Rooms</p>
              <h2 className="text-lg font-semibold text-base-content">Where to?</h2>
            </div>
            <span className="badge badge-outline badge-sm">{rooms.length}</span>
          </div>
        </div>
        <div className="card-body gap-3">
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
