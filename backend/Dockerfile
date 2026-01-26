FROM ghcr.io/gleam-lang/gleam:v1.14.0-erlang

WORKDIR /app

COPY gleam.toml manifest.toml ./
COPY src ./src

RUN gleam deps download
RUN gleam build

EXPOSE 8080

CMD ["gleam", "run"]
