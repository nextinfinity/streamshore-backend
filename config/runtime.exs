import Config

# Required config - YouTube API Key
youtube_key = System.get_env("YOUTUBE_KEY") ||
  raise """
  environment variable YOUTUBE_KEY is missing.
  """

# Database config
database_test_suffix = if Mix.env() == :test do "_test" else "" end
database_url = (System.get_env("DATABASE_URL") || "ecto://root:password@localhost/streamshore") <> database_test_suffix
database_pool_size = String.to_integer(System.get_env("DATABASE_POOL_SIZE") || "10")

# HTTP endpoint config
host = System.get_env("HOST") || "localhost"
default_port = if Mix.env() == :prod do "80" else "4000" end
port = String.to_integer(System.get_env("PORT") || default_port)
secret_key_base = System.get_env("SECRET_KEY_BASE") || "iwMrJzdbfIoFs9WKmnGZqcuufR4llFRraIZDH0+58YSAOsqsdAuIDteOfm7AHqQY"
check_origin = System.get_env("CHECK_ORIGIN") || false

# Additional HTTPS endpoint config
use_https = System.get_env("USE_HTTPS") || "false"
https_port = String.to_integer(System.get_env("HTTPS_PORT") || "443")
keyfile_path = System.get_env("SSL_KEYFILE_PATH") || "/cert/privkey.pem"
certfile_path = System.get_env("SSL_CERTFILE_PATH") || "/cert/cert.pem"

# Other config
guardian_secret = System.get_env("GUARDIAN_SECRET") || "A9uQgqHb60mVqn9tap1S9IRhcS/vY73HeHjYpCpNtBoraYk36KZlDcHmaTeI35OP"
email_key = System.get_env("EMAIL_KEY") || false

config :streamshore, Streamshore.Repo,
  url: database_url,
  pool_size: database_pool_size

config :streamshore, StreamshoreWeb.Endpoint,
  url: [
    host: host,
    port: port
  ],
  http: [
    port: port
  ],
  secret_key_base: secret_key_base,
  check_origin: check_origin

if (use_https == "true") do
  config :streamshore, StreamshoreWeb.Endpoint,
    url: [
      host: host,
      port: https_port
    ],
    https: [
      port: https_port,
      cipher_suite: :strong,
      keyfile: keyfile_path,
      certfile: certfile_path
    ],
    force_ssl: [
      hsts: true
    ]
end

config :streamshore, Streamshore.Guardian,
  secret_key: guardian_secret

if (email_key) do
  config :sendgrid,
    api_key: email_key
end