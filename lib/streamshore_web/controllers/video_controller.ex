defmodule StreamshoreWeb.VideoController do
  use StreamshoreWeb, :controller

  alias Streamshore.PermissionLevel
  alias Streamshore.QueueManager
  alias Streamshore.Rooms
  alias StreamshoreWeb.ApiResponses

  plug StreamshoreWeb.Plugs.RequireAuth
  plug StreamshoreWeb.Plugs.LoadRoomPermission

  plug StreamshoreWeb.Plugs.RequireRoomPermission,
       [min: PermissionLevel.user()] when action in [:create]

  plug StreamshoreWeb.Plugs.RequireRoomPermission,
       [min: PermissionLevel.manager()] when action in [:update, :delete]

  def create(conn, params) do
    room = params["room_id"]
    user = conn.assigns.current_user

    cond do
      conn.assigns.current_room_permission < Rooms.queue_perm(room) ->
        ApiResponses.error(conn, :forbidden, "Insufficient permission")

      !Rooms.anon_queue?(room) && conn.assigns.current_anon ->
        ApiResponses.error(conn, :forbidden, "You must be logged in to perform this action")

      true ->
        case QueueManager.add_to_queue(room, params["id"], user) do
          :ok ->
            ApiResponses.ok(conn)

          {:error, :queue_limit, error} ->
            ApiResponses.error(conn, :conflict, error)

          {:error, :invalid_video, error} ->
            ApiResponses.error(conn, :unprocessable_entity, error)
        end
    end
  end

  def update(conn, params) do
    QueueManager.move_to_front(params["room_id"], params["id"])
    ApiResponses.ok(conn)
  end

  def delete(conn, params) do
    QueueManager.remove_from_queue(params["room_id"], params["id"])
    ApiResponses.ok(conn)
  end
end
