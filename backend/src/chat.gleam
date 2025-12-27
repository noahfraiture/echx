import gleam/time/timestamp

pub type User {
  User(token: String)
}

pub type Chat {
  Chat(content: String, user: User, timestamp: timestamp.Timestamp)
}
