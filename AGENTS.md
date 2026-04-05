# AGENTS.md

## Repo baseline

- App: `streamshore`
- Stack: Elixir, Phoenix, Ecto, MySQL
- Main source roots: `lib/`, `config/`, `priv/`, `test/`
- Release assets: `rel/`
- CI config: `.circleci/config.yml`

## Required environment

- Required in non-test runtime environments:
  - `YOUTUBE_KEY`
- Defaulted in `config/runtime.exs` if not provided:
  - `DATABASE_URL`
  - `DATABASE_POOL_SIZE`
  - `HOST`
  - `PORT`
  - `FRONTEND_BASE_URL`
  - `SECRET_KEY_BASE`
  - `GUARDIAN_SECRET`
- Optional / feature-specific:
  - `PHX_SERVER`
  - `CHECK_ORIGIN`
  - `USE_HTTPS`
  - `HTTPS_PORT`
  - `SSL_KEYFILE_PATH`
  - `SSL_CERTFILE_PATH`
  - `EMAIL_KEY` and `EMAIL_ADDRESS`

## Common workflow

- Install deps: `mix deps.get`
- Compile: `mix compile`
- Create, migrate, and seed DB: `mix ecto.setup`
- Start server: `mix phx.server`
- Run tests: `mix test`
- Format: `mix format`
- `mix` commands need to be run outside sandbox.
- If `YOUTUBE_KEY` is not set, runtime config will raise during boot outside `MIX_ENV=test`.

## Database expectations

- Development and test use MySQL.
- Default local database URL is `ecto://root:password@localhost/streamshore`.
- Test automatically appends `_test`, so test expects `streamshore_test`.
- README and CI both assume root password `password`.

## Developer notes

- Environment setup issues can be highly machine-specific. Keep this file focused on repo behavior and committed expectations, not one developer's shell configuration, installed tool paths, or local ownership fixes.
- If Git reports `detected dubious ownership`, PowerShell blocks script execution, or Erlang networking behaves differently under a sandbox, treat those as environment concerns unless reproduced outside the local tooling layer.
