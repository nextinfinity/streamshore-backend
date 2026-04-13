defmodule StreamshoreWeb.PermissionController do
  use StreamshoreWeb, :controller

  alias Streamshore.Events
  alias Streamshore.PermissionLevel
  alias Streamshore.Rooms
  alias StreamshoreWeb.ApiResponses

  plug StreamshoreWeb.Plugs.RequireAuth
  plug StreamshoreWeb.Plugs.LoadRoomPermission when action in [:update]

  plug StreamshoreWeb.Plugs.RequireRoomPermission,
       [min: PermissionLevel.manager()] when action in [:update]

  def index(conn, params) do
    Rooms.list_permissions(params["room_id"])
    |> then(&ApiResponses.ok(conn, &1))
  end

  def show(conn, params) do
    Rooms.get_permission(params["room_id"], params["id"])
    |> then(&ApiResponses.ok(conn, &1))
  end

  def update(conn, params) do
    permission = params["permission"]

    cond do
      conn.assigns.current_room_permission <= permission ->
        ApiResponses.error(conn, :forbidden, "Insufficient permission")

      true ->
        case Rooms.update_permission(params["room_id"], params["id"], permission) do
          {:ok, _schema, events} ->
            Events.dispatch_all(events)
            ApiResponses.ok(conn)

          {:error, changeset} ->
            ApiResponses.changeset_error(conn, changeset)
        end
    end
  end
end
