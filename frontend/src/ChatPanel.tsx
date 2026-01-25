import { useEffect, useRef, useState } from "react";
import type { Chat } from "./api/types";

type MessageStatus = "pending" | "confirmed" | "error";

export type ChatMessage = {
  chat: Chat;
  status: MessageStatus;
};

type ChatPanelProps = {
  messages: ChatMessage[];
  onMessageSent: (message: string) => void;
};

export function ChatPanel({ messages, onMessageSent }: ChatPanelProps) {
  const [draft, setDraft] = useState("");
  const scrollRef = useRef<HTMLDivElement | null>(null);

  useEffect(() => {
    scrollRef.current?.scrollTo({
      top: scrollRef.current.scrollHeight,
      behavior: "smooth",
    });
  }, [messages]);

  return (
    <div className="flex-1 min-w-0 p-4">
      <div className="h-full w-full p-4 flex flex-col">
        <h2 className="text-lg font-semibold">Chat</h2>
        <div className="space-y-3 overflow-y-auto flex-1" ref={scrollRef}>
          {messages.map((message) => {
            const bubbleClass =
              message.status === "pending"
                ? "chat-bubble opacity-60"
                : message.status === "error"
                  ? "chat-bubble border border-error"
                  : "chat-bubble";

            return (
              <div className="chat chat-start" key={message.chat.message_id}>
                <div className="chat-header">
                  {message.chat.user.name ?? "Anonymous"}
                  <time className="text-xs opacity-50">2 hours ago</time>
                </div>
                <div className={bubbleClass}>{message.chat.content}</div>
                {message.status === "error" ? (
                  <div className="text-xs text-error mt-1">Delivery failed</div>
                ) : null}
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
