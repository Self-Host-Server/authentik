.PHONY: update pull-latest fetch-compose update-env-tag commit-compose redeploy up theme format hooks portainer-agent ldap down

# Resolve the latest authentik release tag from GitHub, e.g. "2026.5.4"
LATEST_TAG := $(shell curl -fsSL https://api.github.com/repos/goauthentik/authentik/releases/latest | grep '"tag_name"' | sed -E 's/.*"version\/([^"]+)".*/\1/')
LATEST_MINOR := $(shell echo $(LATEST_TAG) | cut -d. -f1-2)

# Use docker-compose.yml if that's already the file in use, otherwise compose.yml
COMPOSE_FILE := $(shell [ -f docker-compose.yml ] && echo docker-compose.yml || echo compose.yml)

# All three stacks combined, so every invocation recognizes each other's
# containers as part of the same project instead of flagging them as orphans.
COMPOSE_FILES := -f $(COMPOSE_FILE) -f portainer-agent.compose.yml -f authentik-ldap.compose.yml
COMPOSE := docker compose $(COMPOSE_FILES)

define compose-up-service
	$(COMPOSE) pull $(1)
	$(COMPOSE) up -d --build $(1)
endef

define compose-down-service
	$(COMPOSE) down --remove-orphans $(1)
endef

update:
	make pull-latest
	make fetch-compose
	make update-env-tag
	make commit-compose
	make redeploy

pull-latest:
	git pull
	@test -n "$(LATEST_TAG)" || (echo "Could not resolve latest authentik version" && exit 1)
	@echo "Latest authentik version: $(LATEST_TAG)"

fetch-compose:
	wget -O $(COMPOSE_FILE) https://goauthentik.io/version/$(LATEST_MINOR)/lifecycle/container/compose.yml
	@if ! grep -q '^networks:' $(COMPOSE_FILE); then \
		printf '\nnetworks:\n  default:\n    name: authentik_default\n' >> $(COMPOSE_FILE); \
	fi

update-env-tag:
	@if [ -f .env ]; then \
		if grep -q '^AUTHENTIK_TAG=' .env; then \
			sed -i 's/^AUTHENTIK_TAG=.*/AUTHENTIK_TAG=$(LATEST_TAG)/' .env; \
		else \
			echo "AUTHENTIK_TAG=$(LATEST_TAG)" >> .env; \
		fi; \
	else \
		echo "No .env found, skipping AUTHENTIK_TAG update (set AUTHENTIK_TAG=$(LATEST_TAG) manually)"; \
	fi

commit-compose:
	@if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then \
		echo "Not a git repository, skipping commit"; \
	elif ! git diff --quiet -- $(COMPOSE_FILE); then \
		git add $(COMPOSE_FILE); \
		git commit -m "Bump authentik image tag to $(LATEST_TAG)"; \
		git push; \
	else \
		echo "$(COMPOSE_FILE) unchanged, nothing to commit"; \
	fi

redeploy:
	make up
	git status
	git push
	docker system prune -fa

up:
	$(COMPOSE) up -d --build
	make portainer-agent
	make ldap

portainer-agent:
	$(call compose-up-service,agent)

ldap:
	$(call compose-up-service,authentik-ldap)

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

down:
	git pull
	$(call compose-down-service,agent)
	$(call compose-down-service,authentik-ldap)
	$(COMPOSE) down --remove-orphans