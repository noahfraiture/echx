import { useState } from "react";

export function Chat() {
  // Make a list of 50 messages with random user and content
  const [messages] = useState(() =>
    Array.from({ length: 50 }, () => ({
      user: Math.random() > 0.5 ? "Obi-Wan Kenobi" : "Luke Skywalker",
      content: Math.random() > 0.5 ? "You were the Chosen One!" : "I loved you.",
    })),
  );

  return (
    <div className="flex-1 min-w-0 p-4">
      <div className="h-full w-full p-4 flex flex-col">
        <h2 className="text-lg font-semibold">Chat</h2>
        <div className="space-y-3 overflow-y-auto flex-1">
          {messages.map((message, index) => (
            <div className="chat chat-start" key={`${message.user}-${index}`}>
              <div className="chat-header">
                {message.user}
                <time className="text-xs opacity-50">2 hours ago</time>
              </div>
              <div className="chat-bubble">{message.content}</div>
              <div className="chat-footer opacity-50">{index % 2 === 0 ? "Seen" : "Delivered"}</div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
