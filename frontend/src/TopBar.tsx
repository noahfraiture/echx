import { useRef, useState, type FormEvent } from "react";

type TopBarProps = {
  displayName: string;
  onRename: (name: string) => void;
};

export function TopBar({ displayName, onRename }: TopBarProps) {
  const dialogRef = useRef<HTMLDialogElement | null>(null);
  const [draftName, setDraftName] = useState(displayName);
  const initials = getInitials(displayName);

  const openDialog = () => {
    setDraftName(displayName);
    dialogRef.current?.showModal();
  };

  const closeDialog = () => {
    dialogRef.current?.close();
  };

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const trimmed = draftName.trim();
    if (!trimmed) {
      return;
    }
    onRename(trimmed);
    closeDialog();
  };

  return (
    <div className="navbar border-b border-base-300 bg-base-100 px-4 shadow-sm">
      <div className="navbar-start">
        <a className="btn btn-ghost text-lg font-semibold">echx</a>
      </div>
      <div className="navbar-end gap-2">
        <div className="hidden flex-col items-end text-right sm:flex">
          <span className="text-[0.7rem] uppercase tracking-[0.2em] text-base-content/50">Signed in as</span>
          <span className="text-sm font-semibold text-base-content">{displayName}</span>
        </div>
        <div className="avatar placeholder">
          <div className="w-9 rounded-full bg-primary text-primary-content">
            <span className="text-xs font-semibold">{initials}</span>
          </div>
        </div>
        <button type="button" className="btn btn-ghost btn-sm" onClick={openDialog}>
          Rename
        </button>
        <button type="button" className="btn btn-ghost btn-sm">
          New room
        </button>
      </div>
      <dialog ref={dialogRef} className="modal">
        <div className="modal-box">
          <h3 className="text-lg font-bold">Rename profile</h3>
          <p className="mt-1 text-sm text-base-content/70">
            Your new name will be used the next time you connect.
          </p>
          <form className="mt-4 space-y-4" onSubmit={handleSubmit}>
            <label className="form-control">
              <div className="label">
                <span className="label-text">Display name</span>
              </div>
              <input
                className="input input-bordered"
                value={draftName}
                onChange={(event) => setDraftName(event.target.value)}
                maxLength={32}
                placeholder="Enter a new name"
              />
            </label>
            <div className="modal-action">
              <button type="button" className="btn btn-ghost" onClick={closeDialog}>
                Cancel
              </button>
              <button type="submit" className="btn btn-primary" disabled={!draftName.trim()}>
                Save
              </button>
            </div>
          </form>
        </div>
        <form method="dialog" className="modal-backdrop">
          <button type="button">close</button>
        </form>
      </dialog>
    </div>
  );
}

function getInitials(name: string): string {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) {
    return "?";
  }
  if (parts.length === 1) {
    return parts[0].slice(0, 2).toUpperCase();
  }
  return (parts[0][0] + parts[1][0]).toUpperCase();
}
