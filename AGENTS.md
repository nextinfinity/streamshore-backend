# AGENTS.md

## Repo baseline

- App: `streamshore`
- Stack: Elixir, Phoenix, Ecto, MySQL
- Main source roots: `lib/`, `config/`, `priv/`, `test/`
- Release assets: `rel/`
- CI config: `.circleci/config.yml`

## Current project state

- `mix.exs` now targets Elixir `~> 1.18`.
- The dependency set is aligned with a modern runtime, including Phoenix `~> 1.7`, Ecto SQL `~> 3.12`, Phoenix HTML `~> 4.2`, Plug Cowboy `~> 2.7`, and Req `~> 0.5.8`.
- CI uses `cimg/elixir:1.18-erlang-26.2.1`.
- The old git-based `dictionary` dependency was removed and replaced with a local [`Dictionary`](./lib/dictionary.ex) module to avoid a fragile external dependency during restoration.
- Runtime configuration lives in `config/runtime.exs`.
- The application currently has `69` passing tests in the committed suite.

## Required environment

- Required in all environments:
  - `YOUTUBE_KEY`
- Defaulted in `config/runtime.exs` if not provided:
  - `DATABASE_URL`
  - `DATABASE_POOL_SIZE`
  - `HOST`
  - `PORT`
  - `SECRET_KEY_BASE`
  - `GUARDIAN_SECRET`
- Optional / feature-specific:
  - `PHX_SERVER`
  - `CHECK_ORIGIN`
  - `USE_HTTPS`
  - `HTTPS_PORT`
  - `SSL_KEYFILE_PATH`
  - `SSL_CERTFILE_PATH`
  - `EMAIL_KEY`

## Common workflow

- Install deps: `mix deps.get`
- Compile: `mix compile`
- Create, migrate, and seed DB: `mix ecto.setup`
- Start server: `mix phx.server`
- Run tests: `mix test`
- Format: `mix format`
- `mix` commands need to be run outside sandbox.
- If `YOUTUBE_KEY` is not set, runtime config will raise during boot.

## Database expectations

- Development and test use MySQL.
- Default local database URL is `ecto://root:password@localhost/streamshore`.
- Test automatically appends `_test`, so test expects `streamshore_test`.
- README and CI both assume root password `password`.

## Working assumptions for future updates

- Expect further cleanup may still be needed for long-term Phoenix 1.7 / Ecto 3.12 compatibility, even though the app compiles now.
- When debugging startup or tests, check these in order before changing app code:
  - `YOUTUBE_KEY`
  - MySQL availability
  - database credentials and schema state
  - only then application/runtime code issues
- The earlier controller failures around `StreamshoreWeb.ErrorView` were caused by invalid YouTube API responses from a stub key, not by Phoenix error rendering itself.
- The timing assertion in `VideoControllerTest` needed a tolerance-based check under the current runtime.

## Developer notes

- Environment setup issues can be highly machine-specific. Keep this file focused on repo behavior and committed expectations, not one developer's shell configuration, installed tool paths, or local ownership fixes.
- If Git reports `detected dubious ownership`, PowerShell blocks script execution, or Erlang networking behaves differently under a sandbox, treat those as environment concerns unless reproduced outside the local tooling layer.
