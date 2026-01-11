import { useState } from "react";
import type { Chat } from "./api/types";

type ChatPanelProps = {
  messages: Chat[];
  onMessageSent: (message: string) => void;
};

export function ChatPanel({ messages, onMessageSent }: ChatPanelProps) {
  const [draft, setDraft] = useState("");

  return (
    <div className="flex-1 min-w-0 p-4">
      <div className="h-full w-full p-4 flex flex-col">
        <h2 className="text-lg font-semibold">Chat</h2>
        <div className="space-y-3 overflow-y-auto flex-1">
          {messages.map((message, index) => (
            <div className="chat chat-start" key={`${message.user.name ?? "unknown"}-${index}`}>
              <div className="chat-header">
                {message.user.name ?? "Anonymous"}
                <time className="text-xs opacity-50">2 hours ago</time>
              </div>
              <div className="chat-bubble">{message.content}</div>
              <div className="chat-footer opacity-50">{index % 2 === 0 ? "Seen" : "Delivered"}</div>
            </div>
          ))}
        </div>
        <form
          className="mt-3"
          onSubmit={(event) => {
            event.preventDefault();
            onMessageSent(draft);
            setDraft("");
          }}
        >
          <input
            className="input input-bordered w-full"
            type="text"
            placeholder="Type a message..."
            value={draft}
            onChange={(event) => setDraft(event.target.value)}
          />
        </form>
      </div>
    </div>
  );
}
