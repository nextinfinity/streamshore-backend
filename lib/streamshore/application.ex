defmodule Streamshore.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Streamshore.Repo,
      StreamshoreWeb.Endpoint,
      Streamshore.Videos,
      Streamshore.QueueManager,
      {Phoenix.PubSub, name: Streamshore.PubSub},
      StreamshoreWeb.Presence
    ]

    opts = [strategy: :one_for_one, name: Streamshore.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    StreamshoreWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
