//// Reply envelope for handlers.

import domain/chat
import domain/response
import domain/session

pub type Reply {
  Text(String)
  Response(response.Response)
}

pub fn try_authentication(
  state: session.Session,
  success: fn(chat.User) -> #(session.Session, Reply),
) -> #(session.Session, Reply) {
  case state.user {
    chat.User(_, _) -> {
      success(state.user)
    }
    chat.Unknown -> #(
      state,
      Response(response.JoinRoom(Error("unauthenticated"))),
    )
  }
}
