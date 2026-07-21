# Contributing

This repo is a personal Docker Compose deployment of authentik plus a custom theme - not the authentik project itself. If you're looking to contribute to authentik, see [goauthentik/authentik](https://github.com/goauthentik/authentik).

## Making changes

1. Branch off `main`.
2. Never commit `.env`, `certs/`, or anything else holding real secrets/tokens - only `.env.sample` should be tracked.
3. Open a PR. `CODEOWNERS` routes review to `@Self-Host-Server/code-owners`.

## Editing the theme

Edit the SCSS partials under `theme/`, never `theme.css` directly - it's generated and gets overwritten.

```bash
npm install       # once, installs sass + prettier
make theme        # rebuild theme.css from theme/*.scss
make format       # prettier over json/yml/md/scss
```

Commit both the changed partial(s) under `theme/` and the regenerated `theme.css` in the same PR.

`theme.css` is a generated file - it can only change alongside a matching `theme/*.scss` change, and only via `make theme`. Run `make hooks` once (per clone) to install a pre-commit hook that rebuilds `theme.css` from `theme/*.scss` and blocks the commit if they don't match; the same check runs in CI on every push/PR touching `theme/` or `theme.css` as a backstop.

## Editing the Compose stack

`compose.yml` is normally managed by `make update` (pulls the latest upstream compose file and bumps `AUTHENTIK_TAG`). If you hand-edit it instead, keep it close to upstream so future `make update` runs stay a clean diff.

## Commit messages

Keep them short and imperative (`Fix ...`, `Add ...`, `Bump ...`), matching the existing history (`git log --oneline`).
