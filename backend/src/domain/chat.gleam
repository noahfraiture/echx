//// Chat domain types.

import gleam/time/timestamp

pub type User {
  User(token: String, name: String)
  // The authentication guard should catch Unknown at dispatch time.
  // This means it is not possible to have Unknown in in the pipeline
  Unknown
}

pub type Chat {
  Chat(
    content: String,
    user: User,
    timestamp: timestamp.Timestamp,
    message_id: String,
  )
}
