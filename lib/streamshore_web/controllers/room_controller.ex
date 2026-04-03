defmodule StreamshoreWeb.RoomController do
  use StreamshoreWeb, :controller

  alias Streamshore.Events
  alias Streamshore.Guardian
  alias Streamshore.PermissionLevel
  alias Streamshore.Rooms
  alias StreamshoreWeb.ApiResponses
  alias StreamshoreWeb.Presence

  def index(conn, params) do
    rooms =
      cond do
        params["search"] ->
          Rooms.search_rooms(params["search"])

        params["user"] ->
          Rooms.list_rooms_by_owner(params["user"])

        true ->
          Rooms.list_rooms()
      end

    ApiResponses.ok(conn, with_user_counts(rooms))
  end

  def show(conn, params) do
    case Rooms.get_room_name(params["id"]) do
      nil ->
        ApiResponses.error(conn, :not_found, "Room does not exist")

      name ->
        ApiResponses.ok(conn, %{name: name})
    end
  end

  def create(conn, params) do
    case Guardian.get_user(Guardian.token_from_conn(conn)) do
      {:error, error} ->
        ApiResponses.error(conn, :unauthorized, error)

      {:ok, user, anon} ->
        case anon do
          false ->
            case Rooms.create_room(user, params) do
              {:ok, room} ->
                ApiResponses.ok(conn, %{route: room.route})

              {:error, changeset} ->
                ApiResponses.changeset_error(conn, changeset)
            end

          true ->
            ApiResponses.error(conn, :forbidden, "You must be logged in to create a room")
        end
    end
  end

  def edit(conn, params) do
    case Guardian.get_user_and_permission(Guardian.token_from_conn(conn), params["id"]) do
      {:error, error} ->
        ApiResponses.error(conn, :unauthorized, error)

      {:ok, _user, _anon, permission} ->
        if permission >= PermissionLevel.manager() do
          case Rooms.settings(params["id"]) do
            nil -> ApiResponses.error(conn, :not_found, "Room does not exist")
            room -> ApiResponses.ok(conn, room)
          end
        else
          ApiResponses.error(conn, :forbidden, "Insufficient permission")
        end
    end
  end

  def update(conn, params) do
    case Guardian.get_user_and_permission(Guardian.token_from_conn(conn), params["id"]) do
      {:error, error} ->
        ApiResponses.error(conn, :unauthorized, error)

      {:ok, _user, _anon, permission} ->
        if permission >= PermissionLevel.manager() do
          room = params["id"]

          case Rooms.update_room(room, params) do
            {:error, :not_found} ->
              ApiResponses.error(conn, :not_found, "Room does not exist")

            {:ok, _room, events} ->
              Events.dispatch_all(events)
              ApiResponses.ok(conn)

            {:error, changeset} ->
              ApiResponses.changeset_error(conn, changeset)
          end
        else
          ApiResponses.error(conn, :forbidden, "Insufficient permission")
        end
    end
  end

  def delete(conn, params) do
    case Guardian.get_user(Guardian.token_from_conn(conn)) do
      {:error, error} ->
        ApiResponses.error(conn, :unauthorized, error)

      {:ok, user, _anon} ->
        room_name = params["id"]

        case Rooms.delete_owned_room(room_name, user) do
          {:error, :not_found} ->
            ApiResponses.error(conn, :not_found, "Room does not exist")

          {:error, :forbidden} ->
            ApiResponses.error(conn, :forbidden, "Insufficient permission")

          {:ok, _room, events} ->
            Events.dispatch_all(events)
            ApiResponses.ok(conn)

          {:error, changeset} ->
            ApiResponses.changeset_error(conn, changeset)
        end
    end
  end

  defp with_user_counts(rooms) do
    Enum.map(rooms, fn room ->
      Map.put(room, :users, Enum.count(Presence.list("room:" <> room[:route])))
    end)
  end
end
