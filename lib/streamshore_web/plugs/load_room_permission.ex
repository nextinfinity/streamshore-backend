defmodule StreamshoreWeb.Plugs.LoadRoomPermission do
  @moduledoc false

  import Plug.Conn

  alias Streamshore.Rooms
  alias StreamshoreWeb.ApiResponses

  def init(opts), do: opts

  def call(%Plug.Conn{assigns: %{current_user: nil}} = conn, _opts) do
    conn
    |> ApiResponses.error(:unauthorized, conn.assigns[:auth_error] || "No valid token provided")
    |> halt()
  end

  def call(conn, opts) do
    param = Keyword.get(opts, :param, "room_id")
    room = conn.params[param]
    permission = Rooms.get_permission(room, conn.assigns.current_user)

    assign(conn, :current_room_permission, permission)
  end
end
