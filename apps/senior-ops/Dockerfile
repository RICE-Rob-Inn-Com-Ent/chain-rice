# syntax=docker/dockerfile:1.6
FROM golang:1.22 AS build
WORKDIR /src
COPY . .
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go build -o /out/senior-ops ./cmd/server

FROM gcr.io/distroless/base-debian12:nonroot
WORKDIR /app
COPY --from=build /out/senior-ops /app/senior-ops
EXPOSE 8088 9098
USER nonroot:nonroot
ENTRYPOINT ["/app/senior-ops"]