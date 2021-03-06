# Streamshore Backend [![CircleCI](https://circleci.com/gh/nextinfinity/streamshore-backend.svg?style=shield&circle-token=04368b5676827c2ede46717553395b3a9f2e0796)](https://circleci.com/gh/nextinfinity/streamshore-backend)

This is the backend for Streamshore, a web application for synchronized YouTube video playback. Streamshore's backend is written in Elixir, and contains support for video playback syncing, live chat, rooms, accounts, and more.

Documentation for this repository is a work in progress.

#### [Frontend Repository](https://github.com/sethmaxwl/streamshore)

## Running

**The environment variable YOUTUBE_KEY must be set to a Google API key with YouTube access for Streamshore to run.**

In order to run in production, the following additional environment variables must be set:
- AWS_ACCESS_KEY_ID, AWS_ECR_ACCOUNT_URL, AWS_REGION, and AWS_SECRET_ACCESS_KEY set to AWS credentials (ECR and ECS used).
- DATABASE_URL	set to the URL of a MySQL database login, formatted as ecto://USER:PASS@HOST/DATABASE
- DOMAIN and FRONTEND set to the backend and frontend domains, respectively
- GUARDIAN_SECRET set to the secret JWT key
- SECRET_KEY_BASE set to a random secret key
- SENDGRID_KEY set to a SendGrid API key

To start your Phoenix server:

*Note: this requires a running MySQL server with the root password set in config/dev.exs*

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
