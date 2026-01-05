import domain/response

pub type Reply {
  Text(String)
  Response(response.Response)
}
