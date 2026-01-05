//// Session updates for connect requests.

import domain/chat
import domain/session

pub fn connect(
  state: session.Session,
  token: String,
  name: String,
) -> session.Session {
  session.Session(..state, user: chat.User(token:, name:))
}
