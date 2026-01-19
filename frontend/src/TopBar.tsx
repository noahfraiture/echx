import type { FormEvent } from "react";
import { useEffect, useRef, useState } from "react";

type TopBarProps = {
  userName: string;
  onRename: (nextName: string) => void;
};

export function TopBar({ userName, onRename }: TopBarProps) {
  const dialogRef = useRef<HTMLDialogElement | null>(null);
  const [draftName, setDraftName] = useState(userName);

  useEffect(() => {
    setDraftName(userName);
  }, [userName]);

  const openDialog = () => {
    setDraftName(userName);
    dialogRef.current?.showModal();
  };

  const closeDialog = () => {
    dialogRef.current?.close();
  };

  const submitRename = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const nextName = draftName.trim();
    if (!nextName) {
      return;
    }
    onRename(nextName);
    closeDialog();
  };

  return (
    <>
      <div className="navbar border-b border-base-300 bg-base-100 px-4 shadow-sm">
        <div className="navbar-start">
          <a className="btn btn-ghost text-lg font-semibold">echx</a>
        </div>
        <div className="navbar-end gap-2">
          <div className="hidden items-center gap-3 rounded-full border border-base-300 bg-base-200 px-3 py-1.5 text-sm md:flex">
            <span className="text-base-content/60">Signed in as</span>
            <span className="font-semibold text-base-content">{userName}</span>
          </div>
          <button type="button" className="btn btn-primary btn-sm" onClick={openDialog}>
            Rename
          </button>
        </div>
      </div>

      <dialog ref={dialogRef} className="modal">
        <div className="modal-box">
          <div className="flex items-center justify-between">
            <h3 className="text-lg font-bold">Change your name</h3>
            <form method="dialog">
              <button type="submit" className="btn btn-circle btn-ghost btn-sm" aria-label="Close">
                ✕
              </button>
            </form>
          </div>
          <p className="mt-2 text-sm text-base-content/70">
            Pick a name that appears to everyone you chat with. This updates immediately for your
            session.
          </p>
          <form className="mt-6 space-y-4" onSubmit={submitRename}>
            <label className="form-control w-full">
              <div className="label">
                <span className="label-text font-semibold">Display name</span>
              </div>
              <input
                type="text"
                value={draftName}
                onChange={(event) => setDraftName(event.target.value)}
                placeholder="Type a fresh name"
                className="input input-bordered w-full"
                maxLength={40}
                required
              />
            </label>
            <div className="flex items-center justify-between gap-2">
              <span className="text-xs text-base-content/50">Max 40 characters.</span>
              <div className="flex items-center gap-2">
                <button type="button" className="btn btn-ghost" onClick={closeDialog}>
                  Cancel
                </button>
                <button type="submit" className="btn btn-primary">
                  Save name
                </button>
              </div>
            </div>
          </form>
        </div>
        <form method="dialog" className="modal-backdrop">
          <button type="submit" aria-label="Close rename dialog">
            close
          </button>
        </form>
      </dialog>
    </>
  );
}
