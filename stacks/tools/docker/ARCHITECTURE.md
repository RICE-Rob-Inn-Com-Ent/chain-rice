# Architektura

- `app.sh`: Prosty serwer HTTP (Python) nasłuchujący na porcie 8080.
- `Dockerfile`: Obraz produkcyjny (alpine), expose 8080, uruchamia `app.sh`.
- `Dockerfile.dev`: Wariant developerski z volume i hot-reload (prosty przykład).
- `.dockerignore`: Wykluczenia builda.
- `docker-compose.yml`: Uruchomienie lokalne jednego serwisu.
- `docker-stack.yml`: Definicja stacka dla Docker Swarm.
- `k8s-deployment.yaml`: Minimalny Deployment + Service dla K8s.
- `Makefile`: Skróty do komend (build/up/down/push).

## Flow

1. Build obrazu.
2. Run (docker lub compose).
3. Opcjonalnie: Swarm/K8s dla bardziej zaawansowanych scenariuszy.

## Rozszerzanie

- Podmień `app.sh` na właściwą aplikację (Node/Go/Java/etc.).
- Dodaj healthcheck, sekrety, zmienne środowiskowe, logowanie, monitoring.
