import { useEffect, useMemo, useRef, useState } from "react";
import type { Chat, Timestamp } from "./api/types";

type MessageStatus = "pending" | "confirmed" | "error";

export type ChatMessage = {
  chat: Chat;
  status: MessageStatus;
  isSelf: boolean;
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

  const timeFormatter = useMemo(
    () =>
      new Intl.DateTimeFormat(undefined, {
        hour: "2-digit",
        minute: "2-digit",
        year: "numeric",
        month: "short",
        day: "2-digit",
      }),
    [],
  );

  return (
    <div className="flex-1 min-w-0 p-4">
      <div className="h-full w-full p-4 flex flex-col">
        <h2 className="text-lg font-semibold">Chat</h2>
        <div className="space-y-3 overflow-y-auto flex-1" ref={scrollRef}>
          {messages.map((message) => {
            const bubbleClass = [
              "chat-bubble",
              message.isSelf ? "chat-bubble-primary text-primary-content" : "",
              message.status === "pending" ? "opacity-60" : "",
              message.status === "error" ? "border border-error" : "",
            ]
              .filter(Boolean)
              .join(" ");
            const alignmentClass = message.isSelf ? "chat chat-end" : "chat chat-start";

            return (
              <div className={alignmentClass} key={message.chat.message_id}>
                <div className="chat-header">
                  {message.chat.user.name ?? "Anonymous"}
                  <time
                    className="text-xs opacity-50"
                    dateTime={message.status === "confirmed" ? formatTimestamp(message.chat.timestamp) : undefined}
                  >
                    {message.status === "confirmed"
                      ? formatMessageTime(message.chat.timestamp, timeFormatter)
                      : "Sending..."}
                  </time>
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

function formatMessageTime(timestamp: Timestamp, formatter: Intl.DateTimeFormat): string {
  return formatter.format(timestampToDate(timestamp));
}

function formatTimestamp(timestamp: Timestamp): string {
  return timestampToDate(timestamp).toISOString();
}

function timestampToDate(timestamp: Timestamp): Date {
  const milliseconds = timestamp.seconds * 1000 + Math.floor(timestamp.nanoseconds / 1_000_000);
  return new Date(milliseconds);
}
