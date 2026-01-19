// Integration tests expect the backend running on localhost:8080.
export const BASE_URL = process.env.INTEGRATION_BASE_URL ?? "http://localhost:8080";
export const WS_URL = makeWsUrl(BASE_URL);
export const RESPONSE_TIMEOUT = 2000;

export type Identity = {
  token: string;
  name: string;
};

export function createIdentity(suffix: string): Identity {
  return {
    token: `integration-${suffix}-${Date.now()}`,
    name: `tester-${suffix}`,
  };
}

function makeWsUrl(baseUrl: string): string {
  const url = new URL(baseUrl);
  url.protocol = url.protocol === "https:" ? "wss:" : "ws:";
  url.pathname = "/ws";
  url.search = "";
  url.hash = "";
  return url.toString();
}
