# Streamshore Backend [![CircleCI](https://dl.circleci.com/status-badge/img/gh/nextinfinity/streamshore-backend/tree/master.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/gh/nextinfinity/streamshore-backend/tree/master)

This is the backend for Streamshore, a web application for synchronized YouTube video playback. Streamshore's backend is written in Elixir, and contains support for video playback syncing, live chat, rooms, accounts, and more.

Documentation for this repository is a work in progress.

#### [Frontend Repository](https://github.com/sethmaxwl/streamshore)

## Running

**The environment variable `YOUTUBE_KEY` must be set to a Google API key with YouTube access for non-test runtime environments. Tests use a mock video fetcher and do not require it.**

This project currently targets modern Elixir and Phoenix:

- Elixir `~> 1.18`
- Erlang/OTP `26+`
- Phoenix `~> 1.7`
- MySQL on `localhost:3306` by default

Runtime configuration is loaded from `config/runtime.exs`.

Required environment variables:

- Non-test environments: `YOUTUBE_KEY` set to a Google API key with YouTube access

Common optional overrides:

- `DATABASE_URL` formatted as `ecto://USER:PASS@HOST/DATABASE`
- `DATABASE_POOL_SIZE`
- `HOST`
- `PORT`
- `FRONTEND_BASE_URL` for links included in account emails such as verification and password reset
- `SECRET_KEY_BASE`
- `GUARDIAN_SECRET`
- `PHX_SERVER`
- `CHECK_ORIGIN`
- `USE_HTTPS`
- `HTTPS_PORT`
- `SSL_KEYFILE_PATH`
- `SSL_CERTFILE_PATH`
- `EMAIL_KEY`
- `EMAIL_ADDRESS`

To start your Phoenix server:

*Note: local startup requires a running MySQL server and a `YOUTUBE_KEY`. The default local database URL is `ecto://root:password@localhost/streamshore`. Tests use `streamshore_test` and do not require a `YOUTUBE_KEY`.*

  * Install dependencies with `mix.bat deps.get` on Windows, or `mix deps.get` on Unix-like shells
  * Create, migrate, and seed your database with `mix.bat ecto.setup`
  * Start Phoenix with `mix.bat phx.server`
  * Run tests with `mix.bat test`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).
