defmodule StreamshoreWeb.VideoController do
  use StreamshoreWeb, :controller

  alias Streamshore.Guardian
  alias Streamshore.PermissionLevel
  alias Streamshore.QueueManager

  def create(conn, params) do
    case Guardian.get_user_and_permission(Guardian.token_from_conn(conn), params["room_id"]) do
      {:error, error} -> json(conn, %{error: error})
      {:ok, user, anon, perm} ->
        case anon do
          false ->
            if perm >= PermissionLevel.user do
              case QueueManager.add_to_queue(params["room_id"], params["id"], user) do
                :ok -> json(conn, %{})
                :error -> json(conn, %{error: "Invalid video"})
              end
            else
              json(conn, %{error: "Insufficient permission"})
            end
          true -> json(conn, %{error: "You must be logged in to submit a video"})
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
