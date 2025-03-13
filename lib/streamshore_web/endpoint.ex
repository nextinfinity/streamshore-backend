defmodule StreamshoreWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :streamshore

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_streamshore_key",
    signing_salt: "41tWQZVt"
  ]

  socket "/socket", StreamshoreWeb.UserSocket,
    websocket: true,
    longpoll: false

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Corsica, max_age: 600, origins: "*", allow_headers: :all, allow_methods: :all
  plug Plug.Session, @session_options
  plug StreamshoreWeb.Router
end
