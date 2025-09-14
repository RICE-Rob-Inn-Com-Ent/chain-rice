IMAGE ?= examples-docker-hello:latest
CONTAINER ?= examples-docker-hello

.PHONY: build run stop push compose-up compose-down stack-up stack-down k8s-apply k8s-delete

build:
	docker build -t $(IMAGE) .

run:
	docker run --rm -d --name $(CONTAINER) -e APP_NAME=$(CONTAINER) -p 8080:8080 $(IMAGE)

stop:
	-docker rm -f $(CONTAINER)

push:
	@echo "Push to registry: update IMAGE with your registry/tag first"

compose-up:
	docker compose up --build -d

compose-down:
	docker compose down -v

stack-up:
	docker stack deploy -c docker-stack.yml examples

stack-down:
	docker stack rm examples

k8s-apply:
	kubectl apply -f k8s-deployment.yaml

k8s-delete:
	kubectl delete -f k8s-deployment.yaml || true


