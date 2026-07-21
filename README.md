# authentik

Self-hosted [authentik](https://goauthentik.io/) deployment via Docker Compose, with a custom glassmorphism theme.

## Layout

- `compose.yml` - PostgreSQL, authentik server, and worker services.
- `.env.sample` - copy to `.env` and fill in your values (DB credentials, secret key, host, ports, LDAP outpost token, optional email settings).
- `theme/` - SCSS source for the custom theme, split into partials (`_dark-mode.scss`, `_login-buttons.scss`, `_admin-interface.scss`, etc.) and assembled by `theme/theme.scss`.
- `theme.css` - the compiled output of `theme/`. Upload this file in Admin Interface -> Customization -> Blueprints/Files. Don't edit it by hand - edit the partials and rebuild.
- `custom-templates/` - mounted into the server/worker containers at `/templates` (see `compose.yml`).
- `Makefile` - update/run the stack and rebuild the theme.

## Getting started

```bash
cp .env.sample .env
# edit .env: PG_PASS, AUTHENTIK_SECRET_KEY, AUTHENTIK_HOST, etc.
make up
```

authentik will be available on the ports set by `COMPOSE_PORT_HTTP`/`COMPOSE_PORT_HTTPS` in `.env` (default `9000`/`9443`).

## Makefile targets

- `make up` - start the stack (`docker compose up -d`).
- `make update` - fetch the latest authentik release's `compose.yml` from goauthentik.io, bump `AUTHENTIK_TAG` in `.env`, and commit the change if anything differs.
- `make theme` - compile `theme/theme.scss` into `theme.css` via `sass` (dart-sass). Requires Node/npm on `PATH` (see below).
- `make format` - run `prettier` over JSON/YAML/Markdown/SCSS files.

## Theme toolchain

The theme build needs Node with the `sass` and `prettier` packages (declared in `package.json`):

```bash
npm install
make theme    # rebuild theme.css from theme/*.scss
make format   # format theme/*.scss and other files
```

If `npx`/`npm` aren't on `PATH`, activate whatever environment provides Node first (this repo's `environment.yml` sets up a conda env named `authentik` with Python tooling; Node isn't managed by it, so install/activate Node separately).
