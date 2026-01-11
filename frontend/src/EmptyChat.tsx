export function EmptyChat() {
  return (
    <div className="flex-1 min-w-0 p-4">
      <div className="h-full w-full p-6 flex items-center justify-center">
        <div className="w-full max-w-xl text-center">
          <p className="text-xs uppercase tracking-[0.3em] text-base-content/50">No room selected</p>
          <h2 className="mt-3 text-3xl sm:text-4xl font-black leading-tight">
            Pick a room and
            <span className="block text-accent">light up the conversation.</span>
          </h2>
          <p className="mt-4 text-base sm:text-lg text-base-content/70">
            Your messages are waiting for a place to land. Choose a room on the right to start
            the flow.
          </p>
          <div className="mt-6 inline-flex items-center gap-3 rounded-full bg-base-200 px-5 py-2 text-sm">
            <span className="text-base-content/60">Tip</span>
            <span className="font-medium">Rooms with bold names already know you.</span>
          </div>
        </div>
      </div>
    </div>
  );
}
