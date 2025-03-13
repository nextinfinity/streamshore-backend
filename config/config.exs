import Config

config :streamshore,
  ecto_repos: [Streamshore.Repo]

# Configures the endpoint
config :streamshore, StreamshoreWeb.Endpoint,
  pubsub_server: Streamshore.PubSub

config :streamshore, Streamshore.Guardian,
  issuer: "streamshore"

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
