# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
use Mix.Config

database_url =
  System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

config :streamshore, Streamshore.Repo,
  # ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

config :streamshore, StreamshoreWeb.Endpoint,
  secret_key_base: secret_key_base

guardian_secret =
  System.get_env("GUARDIAN_SECRET") ||
    raise """
    environment variable GUARDIAN_SECRET is missing.
    You can generate one by calling: mix guardian.gen.secret
    """

config :streamshore, Streamshore.Guardian,
  secret_key: guardian_secret

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :streamshore, StreamshoreWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
