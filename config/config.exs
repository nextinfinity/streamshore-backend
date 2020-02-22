# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :streamshore,
  ecto_repos: [Streamshore.Repo]

# Configures the endpoint
config :streamshore, StreamshoreWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "QrqZj1palDcW+pPZm346iKQkCYq4JvMK7WoSCRaT9T/E4FhHAY4jVX8fPXmabd/z",
  render_errors: [view: StreamshoreWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Streamshore.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [signing_salt: "n76/WXj5"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
