defmodule StreamshoreWeb.Presence do
  use Phoenix.Presence,
    otp_app: :streamshore,
    pubsub_server: Streamshore.PubSub

  @moduledoc false
end
