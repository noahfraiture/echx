import gleam/time/timestamp

pub type User {
  User(name: String)
}

pub type Chat {
  Chat(content: String, user: User, timestamp: timestamp.Timestamp)
}
