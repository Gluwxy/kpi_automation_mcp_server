.PHONY: help lint format format-check type-check check test pre-commit ci \
	docker-build docker-smoke docker-push

PROJECT_ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SRC ?= $(PROJECT_ROOT)src/kpi_automation_mcp_server
TESTS ?= $(PROJECT_ROOT)tests
RUN := uv run
CONTAINER := smoketest

# Docker Image - GitHub Container Registry (GHCR)
IMAGE ?= ghcr.io/gluwxy/kpi_automation_mcp_server
TAG ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo dev)

help:
	@echo "Available Commands"
	@echo "  make lint          - Ruff linter without modifying files"
	@echo "  make format        - Ruff auto-fix lint issues + format"
	@echo "  make format-check  - Ruff format check without modifying files"
	@echo "  make type-check    - Mypy static type checker (strict)"
	@echo "  make check         - All checks (lint + format-check + type-check)"
	@echo "  make test          - Pytest with coverage"
	@echo "  make pre-commit    - Run pre-commit hooks on all files"
	@echo "  make ci            - Run pre-commit hooks and test suite"
	@echo "  make docker-build  - Build Docker image $(IMAGE):$(TAG)"
	@echo "  make docker-smoke  - Check container healthiness (/health)"
	@echo "  make docker-push   - Push Docker image to GHCR"

lint:
	@echo "Linting..."
	$(RUN) ruff check $(SRC) $(TESTS)

format:
	@echo "Formatting..."
	$(RUN) ruff check --fix $(SRC) $(TESTS)
	$(RUN) ruff format $(SRC) $(TESTS)

format-check:
	@echo "Format checking..."
	$(RUN) ruff format --check $(SRC) $(TESTS)

type-check:
	@echo "Type checking..."
	$(RUN) mypy $(SRC) $(TESTS)

check: lint format-check type-check

test:
	@echo "Running tests..."
	$(RUN) pytest --cov --cov-report=term-missing

# ruff/mypy flags: defined here, invoked by pre-commit hooks.
pre-commit:
	@echo "Running pre-commit hooks..."
	$(RUN) pre-commit run --all-files --show-diff-on-failure

# pre-commit already runs ruff (lint + format) and mypy, so `check` is not repeated.
ci: pre-commit test

docker-build:
	@echo "Building image $(IMAGE):$(TAG)..."
	docker build -t $(IMAGE):$(TAG) -t $(IMAGE):latest .

# No --rm: if the server crashes, the container must still exist so `docker logs` works.
docker-smoke:
	@echo "Smoke testing $(IMAGE):$(TAG)..."
	-@docker rm -f $(CONTAINER) >/dev/null 2>&1
	docker run -d --name $(CONTAINER) -p 8000:8000 \
		-e MCP_HOST=0.0.0.0 \
		-e POSTGRES_USER=smoke \
		-e POSTGRES_PASSWORD=smoke \
		-e POSTGRES_DB=smoke \
		$(IMAGE):$(TAG)

	@echo "Waiting for /health (up to 30s)..."
	@for i in $$(seq 1 15); do \
		if curl -fsS http://localhost:8000/health; then \
			echo " -> healthy"; docker rm -f $(CONTAINER) >/dev/null; exit 0; \
		fi; sleep 2; \
	done; \
	echo "Health check failed"; docker logs $(CONTAINER); \
	docker rm -f $(CONTAINER) >/dev/null; exit 1

docker-push:
	@echo "Pushing $(IMAGE):$(TAG) and $(IMAGE):latest to GHCR..."
	docker push $(IMAGE):$(TAG)
	docker push $(IMAGE):latest
