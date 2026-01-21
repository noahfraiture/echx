import { useState } from "react";
import type { Chat } from "./api/types";

type ChatPanelProps = {
  currentUserName: string;
  messages: Chat[];
  onMessageSent: (message: string) => void;
};

export function ChatPanel({ currentUserName, messages, onMessageSent }: ChatPanelProps) {
  const [draft, setDraft] = useState("");

  return (
    <div className="flex-1 min-w-0 p-4">
      <div className="h-full w-full p-4 flex flex-col">
        <h2 className="text-lg font-semibold">Chat</h2>
        <div className="space-y-3 overflow-y-auto flex-1">
          {messages.map((message, index) => {
            const isOwnMessage = message.user.name === currentUserName;
            const chatAlignment = isOwnMessage ? "chat-end" : "chat-start";
            const bubbleTone = isOwnMessage ? "chat-bubble-primary" : "chat-bubble-secondary";
            const footerText = isOwnMessage ? "Sent" : "Delivered";

            return (
              <div className={`chat ${chatAlignment}`} key={`${message.user.name ?? "unknown"}-${index}`}>
                <div className="chat-header">
                  {isOwnMessage ? "You" : (message.user.name ?? "Anonymous")}
                  <time className="text-xs opacity-50">{isOwnMessage ? "Just now" : "Moments ago"}</time>
                </div>
                <div className={`chat-bubble ${bubbleTone}`}>{message.content}</div>
                <div className="chat-footer opacity-50">{footerText}</div>
              </div>
            );
          })}
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
