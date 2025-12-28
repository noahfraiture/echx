import gleam/time/timestamp

pub type User {
  User(token: String, name: String)
  Unknown
}

pub type Chat {
  Chat(content: String, user: User, timestamp: timestamp.Timestamp)
}
