# Build stage
FROM node:20-slim AS builder

WORKDIR /app

COPY package.json pnpm-lock.yaml ./

RUN corepack enable \
  && pnpm install --frozen-lockfile

COPY . .

ENV VITE_WS_URL=wss://api.echx.app/ws

RUN pnpm build

# Runtime stage
FROM nginx:alpine

COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
