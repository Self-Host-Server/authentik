.PHONY: update up

# Resolve the latest authentik release tag from GitHub, e.g. "2026.5.4"
LATEST_TAG := $(shell curl -fsSL https://api.github.com/repos/goauthentik/authentik/releases/latest | grep -m1 '"tag_name"' | sed -E 's/.*"version\/([^"]+)".*/\1/')
LATEST_MINOR := $(shell echo $(LATEST_TAG) | cut -d. -f1-2)

update:
	@test -n "$(LATEST_TAG)" || (echo "Could not resolve latest authentik version" && exit 1)
	@echo "Latest authentik version: $(LATEST_TAG)"
	wget -O compose.yml https://goauthentik.io/version/$(LATEST_MINOR)/lifecycle/container/compose.yml
	@if [ -f .env ]; then \
		sed -i 's/^AUTHENTIK_TAG=.*/AUTHENTIK_TAG=$(LATEST_TAG)/' .env; \
	else \
		echo "No .env found, skipping AUTHENTIK_TAG update (set AUTHENTIK_TAG=$(LATEST_TAG) manually)"; \
	fi

up:
	docker compose up -d
