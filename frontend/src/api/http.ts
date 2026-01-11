import { type Request, type Response } from "./types";

export type HttpRequestOptions = {
  url?: string;
  token?: string;
  name?: string;
  signal?: AbortSignal;
};

export async function sendHttpRequest(
  request: Request,
  options: HttpRequestOptions = {},
): Promise<Response | null> {
  const headers = new Headers({ "content-type": "application/json" });
  if (options.token) {
    headers.set("token", options.token);
  }
  if (options.name) {
    headers.set("name", options.name);
  }

  const response = await fetch(options.url ?? "/api", {
    method: "POST",
    headers,
    body: JSON.stringify(request),
    signal: options.signal,
  });

  if (response.status === 204) {
    return null;
  }

  const payload = await response.text();
  return parseResponse(payload);
}

function parseResponse(payload: string): Response {
  return JSON.parse(payload) as Response;
}
