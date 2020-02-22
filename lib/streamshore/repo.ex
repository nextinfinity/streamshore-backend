defmodule Streamshore.Repo do
  use Ecto.Repo,
    otp_app: :streamshore,
    adapter: Ecto.Adapters.MyXQL
end
