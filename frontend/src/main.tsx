import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import "./index.css";
import { TopBar } from "./TopBar.tsx";
import { Chat } from "./Chat.tsx";
import { Rooms } from "./Rooms.tsx";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <div className="h-screen flex flex-col overflow-hidden">
      <TopBar />
      <div className="flex flex-1 min-h-0 overflow-hidden">
        <Chat />
        <Rooms />
      </div>
    </div>
  </StrictMode>,
);
