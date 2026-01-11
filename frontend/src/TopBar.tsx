export function TopBar() {
  return (
    <div className="navbar border-b border-base-300 bg-base-100 px-4 shadow-sm">
      <div className="navbar-start">
        <a className="btn btn-ghost text-lg font-semibold">echx</a>
      </div>
      <div className="navbar-end">
        <button type="button" className="btn btn-ghost btn-sm">
          New room
        </button>
      </div>
    </div>
  );
}
