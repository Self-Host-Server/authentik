.PHONY: update up theme format hooks portainer-agent

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
	@if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then \
		echo "Not a git repository, skipping commit"; \
	elif ! git diff --quiet -- $(COMPOSE_FILE); then \
		git add $(COMPOSE_FILE); \
	else \
		echo "$(COMPOSE_FILE) unchanged, nothing to commit"; \
	fi
	make up

up:
	docker compose up -d
	make portainer-agent

portainer-agent:
	docker compose -f portainer-agent.compose.yml pull
	docker compose -f portainer-agent.compose.yml up -d

# Compile the SCSS partials in theme/ into the single theme.css uploaded via
# Admin Interface -> Customization -> Blueprints/Files. Requires `sass`
# (npm install sass) with node/npm on PATH.
theme:
	@command -v npx >/dev/null || (echo "npx not found on PATH (activate the conda env with node/npm)" && exit 1)
	npx --no-install sass theme/theme.scss theme.css --style=expanded --no-source-map

format:
	npx --no-install prettier --write "**/*.{json,yml,yaml,md,scss}"

# One-time setup: point git at the tracked hooks in .githooks/ so the
# pre-commit theme.css consistency check runs locally too (also enforced
# in CI regardless of whether this has been run).
hooks:
	git config core.hooksPath .githooks
	chmod +x .githooks/pre-commit