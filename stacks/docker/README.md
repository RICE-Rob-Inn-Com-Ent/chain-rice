## Docker Hello World (minimalny serwis HTTP)

**Build & Run (pojedynczy kontener)**

- Build: `docker build -t examples-docker-hello .`
- Run: `docker run --rm -p 8080:8080 -e APP_NAME=examples-docker-hello examples-docker-hello`
- Otwórz: `http://localhost:8080`

**Docker Compose**

- `docker compose up --build`
- `docker compose down -v`

**Docker Swarm (stack)**

- `docker stack deploy -c docker-stack.yml examples`
- `docker stack rm examples`

**Kubernetes (kubectl)**

- `kubectl apply -f k8s-deployment.yaml`
- `kubectl delete -f k8s-deployment.yaml`

## Do czego najlepiej pasuje Docker?

- Izolacja aplikacji i zależności, powtarzalne środowiska build/run.
- CI/CD, testy end-to-end, szybkie uruchamianie usług lokalnie.
- Standaryzacja wdrożeń (Compose/Swarm/Kubernetes).

## Kiedy rozważyć alternatywy?

- Bardzo proste skrypty lokalne: bez kontenerów, odpal bezpośrednio.
- Silna izolacja jądra i wielo-tenant: maszyny wirtualne/Firecracker.

## Oceny (1–5 gwiazdek)

- Skala: 1 = niskie/małe, 5 = wysokie/duże.
- Poziom trudności nauki: ★★★☆☆
- Bogactwo ekosystemu: ★★★★★
- Zastosowania w praktyce: ★★★★★
- Powtarzalność/portability: ★★★★★
- Złożoność narzędzi: ★★★★☆

## Co zawiera przykład?

- Minimalny serwis HTTP na porcie 8080 (Python HTTP server).
- Konfiguracje: `Dockerfile`, `docker-compose.yml`, `docker-stack.yml`, `k8s-deployment.yaml`.
- `Makefile` z najczęstszymi komendami.

Zajrzyj do `ARCHITECTURE.md` po szczegóły.


