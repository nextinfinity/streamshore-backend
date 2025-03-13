# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :streamshore,
  ecto_repos: [Streamshore.Repo]

# Configures the endpoint
config :streamshore, StreamshoreWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "QrqZj1palDcW+pPZm346iKQkCYq4JvMK7WoSCRaT9T/E4FhHAY4jVX8fPXmabd/z",
  pubsub_server: Streamshore.PubSub,
  live_view: [signing_salt: "n76/WXj5"]

config :streamshore, Streamshore.Guardian,
       issuer: "streamshore",
       secret_key: "0CfBeMjI3pA3ZsZoV6EhZ0LgHDN/I46Nl/rUwWc15qbUmxCaOyaPiDMiQceWDPnP"

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Test junit output configuration
config :junit_formatter,
      report_dir: "/output",
      print_report_file: true,
      prepend_project_name?: true,
      include_filename?: true,
      include_file_line?: true,
      automatic_create_dir?: true

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
