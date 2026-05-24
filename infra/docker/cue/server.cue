package docker

// server.cue — OTP / RPC / agent / docs container Dockerfiles (when stack.*.enabled).

_serverDockerfileOtp: """
# Dockerfile.otp — SMITH Elixir umbrella (generated from infra/docker/cue/server.cue)
FROM hexpm/elixir:1.18.3-erlang-27.3.2-debian-bookworm-20250317-slim AS build
RUN apt-get update && apt-get install -y build-essential git && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY service/mix.exs service/mix.lock ./
COPY service/config config
COPY service/messages service/messages
COPY service/guard service/guard
COPY service/core service/core
COPY service/pipeline service/pipeline
COPY service/cluster service/cluster
COPY service/connection service/connection
ENV MIX_ENV=prod
RUN mix local.hex --force && mix local.rebar --force
RUN mix deps.get --only prod
RUN mix release core

FROM gcr.io/distroless/cc-debian12:nonroot
WORKDIR /app
COPY --from=build /app/_build/prod/rel/core ./
ENV HOME=/app
USER nonroot:nonroot
EXPOSE 4000
ENTRYPOINT ["/app/bin/core", "start"]
"""

_serverDockerfileRpc: """
# Dockerfile.rpc — Go RPC stub (enable when server.rice sets rpc)
FROM alpine:3.21
RUN echo "rpc stub — build function/ when ready" > /README
CMD ["sleep", "infinity"]
"""

_serverDockerfileAgent: """
# Dockerfile.agent — Python agent stub
FROM python:3.12-slim-bookworm
WORKDIR /app
RUN echo "agent stub" > /README
CMD ["sleep", "infinity"]
"""

_serverDockerfileDocs: """
# Dockerfile.docs — MkDocs + PlantUML static site (generated)
FROM plantuml/plantuml:1.2024.8 AS puml
FROM squidfunk/mkdocs-material:9.5 AS mkdocs
WORKDIR /site
COPY infra/gen/chief/docs /site/docs/diagrams
COPY .docker/server/docs/mkdocs.yml /site/mkdocs.yml
COPY .docker/server/docs/docs /site/docs
RUN mkdocs build -d /site/site

FROM nginx:1.27-alpine
COPY --from=mkdocs /site/site /usr/share/nginx/html
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
"""
