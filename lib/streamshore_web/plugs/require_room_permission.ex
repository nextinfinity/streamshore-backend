defmodule StreamshoreWeb.Plugs.RequireRoomPermission do
  @moduledoc false

  import Plug.Conn

  alias StreamshoreWeb.ApiResponses

  def init(opts), do: opts

  def call(conn, opts) do
    min_permission = Keyword.fetch!(opts, :min)

    if conn.assigns[:current_room_permission] >= min_permission do
      conn
    else
      conn
      |> ApiResponses.error(:forbidden, "Insufficient permission")
      |> halt()
    end
  end
end
