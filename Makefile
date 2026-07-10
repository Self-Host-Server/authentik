.PHONY: update up

# Resolve the latest authentik release tag from GitHub, e.g. "2026.5.4"
LATEST_TAG := $(shell curl -fsSL https://api.github.com/repos/goauthentik/authentik/releases/latest | grep '"tag_name"' | sed -E 's/.*"version\/([^"]+)".*/\1/')
LATEST_MINOR := $(shell echo $(LATEST_TAG) | cut -d. -f1-2)

# Use docker-compose.yml if that's already the file in use, otherwise compose.yml
COMPOSE_FILE := $(shell [ -f docker-compose.yml ] && echo docker-compose.yml || echo compose.yml)

update:
	@test -n "$(LATEST_TAG)" || (echo "Could not resolve latest authentik version" && exit 1)
	@echo "Latest authentik version: $(LATEST_TAG)"
	wget -O $(COMPOSE_FILE) https://goauthentik.io/version/$(LATEST_MINOR)/lifecycle/container/compose.yml
	@if [ -f .env ]; then \
		sed -i 's/^AUTHENTIK_TAG=.*/AUTHENTIK_TAG=$(LATEST_TAG)/' .env; \
	else \
		echo "No .env found, skipping AUTHENTIK_TAG update (set AUTHENTIK_TAG=$(LATEST_TAG) manually)"; \
	fi
	@if ! git diff --quiet -- $(COMPOSE_FILE); then \
		git add $(COMPOSE_FILE); \
		git commit -m "Bump authentik image tag to $(LATEST_TAG)"; \
	else \
		echo "$(COMPOSE_FILE) unchanged, nothing to commit"; \
	fi

up:
	docker compose up -d
