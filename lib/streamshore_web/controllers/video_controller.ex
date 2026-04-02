defmodule StreamshoreWeb.VideoController do
  use StreamshoreWeb, :controller

  alias Streamshore.Guardian
  alias Streamshore.PermissionLevel
  alias Streamshore.QueueManager
  alias Streamshore.Rooms
  alias StreamshoreWeb.ApiResponses

  def create(conn, params) do
    room = params["room_id"]

    case Guardian.get_user_and_permission(Guardian.token_from_conn(conn), room) do
      {:error, error} ->
        ApiResponses.error(conn, :unauthorized, error)

      {:ok, user, anon, perm} ->
        if perm >= Rooms.queue_perm(room) do
          if Rooms.anon_queue?(room) || !anon do
            case QueueManager.add_to_queue(room, params["id"], user) do
              :ok ->
                ApiResponses.ok(conn)

              {:error, :queue_limit, error} ->
                ApiResponses.error(conn, :conflict, error)

              {:error, :invalid_video, error} ->
                ApiResponses.error(conn, :unprocessable_entity, error)
            end
          else
            ApiResponses.error(conn, :forbidden, "You must be logged in to submit a video")
          end
        else
          ApiResponses.error(conn, :forbidden, "Insufficient permission")
        end
    end
  end

  def update(conn, params) do
    case Guardian.get_user_and_permission(Guardian.token_from_conn(conn), params["room_id"]) do
      {:error, error} ->
        ApiResponses.error(conn, :unauthorized, error)

      {:ok, _user, _anon, perm} ->
        if perm >= PermissionLevel.manager() do
          QueueManager.move_to_front(params["room_id"], params["id"])
          ApiResponses.ok(conn)
        else
          ApiResponses.error(conn, :forbidden, "Insufficient permission")
        end
    end
  end

  def delete(conn, params) do
    case Guardian.get_user_and_permission(Guardian.token_from_conn(conn), params["room_id"]) do
      {:error, error} ->
        ApiResponses.error(conn, :unauthorized, error)

      {:ok, _user, _anon, perm} ->
        if perm >= PermissionLevel.manager() do
          QueueManager.remove_from_queue(params["room_id"], params["id"])
          ApiResponses.ok(conn)
        else
          ApiResponses.error(conn, :forbidden, "Insufficient permission")
        end
    end
  end
end
