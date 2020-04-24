defmodule StreamshoreWeb.VideoController do
  use StreamshoreWeb, :controller

  alias Streamshore.Guardian
  alias Streamshore.PermissionLevel
  alias Streamshore.QueueManager
  alias StreamshoreWeb.RoomController

  def create(conn, params) do
    room = params["room_id"]
    case Guardian.get_user_and_permission(Guardian.token_from_conn(conn), room) do
      {:error, error} -> json(conn, %{error: error})
      {:ok, user, anon, perm} ->
        if perm >= RoomController.queue_perm(room) do
          if RoomController.anon_queue?(room) || !anon do
            case QueueManager.add_to_queue(room, params["id"], user) do
              :ok -> json(conn, %{})
              {:error, error} -> json(conn, %{error: error})
            end
          else
            json(conn, %{error: "You must be logged in to submit a video"})
          end
        else
          json(conn, %{error: "Insufficient permission"})
        end
    end
  end

  def update(conn, params) do
    case Guardian.get_user_and_permission(Guardian.token_from_conn(conn), params["room_id"]) do
      {:error, error} -> json(conn, %{error: error})
      {:ok, _user, _anon, perm} ->
        if perm >= PermissionLevel.manager() do
          QueueManager.move_to_front(params["room_id"], params["id"])
          json(conn, %{})
        else
          json(conn, %{error: "Insufficient permission"})
        end
    end
  end

  def delete(conn, params) do
    case Guardian.get_user_and_permission(Guardian.token_from_conn(conn), params["room_id"]) do
      {:error, error} -> json(conn, %{error: error})
      {:ok, _user, _anon, perm} ->
        if perm >= PermissionLevel.manager() do
          QueueManager.remove_from_queue(params["room_id"], params["id"])
          json(conn, %{})
        else
          json(conn, %{error: "Insufficient permission"})
        end
    end
  end

end
