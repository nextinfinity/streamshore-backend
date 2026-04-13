defmodule StreamshoreWeb.RoomController do
  use StreamshoreWeb, :controller

  alias Streamshore.Events
  alias Streamshore.PermissionLevel
  alias Streamshore.Rooms
  alias StreamshoreWeb.ApiResponses
  alias StreamshoreWeb.Presence

  plug StreamshoreWeb.Plugs.RequireAuth
  plug StreamshoreWeb.Plugs.RequireNonAnon when action in [:create, :edit, :update, :delete]

  plug StreamshoreWeb.Plugs.LoadRoomPermission,
       [param: "id"] when action in [:edit, :update, :delete]

  plug StreamshoreWeb.Plugs.RequireRoomPermission,
       [min: PermissionLevel.manager()] when action in [:edit, :update]

  plug StreamshoreWeb.Plugs.RequireRoomPermission,
       [min: PermissionLevel.owner()] when action in [:delete]

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
    case Rooms.create_room(conn.assigns.current_user, params) do
      {:ok, room} ->
        ApiResponses.ok(conn, %{route: room.route})

      {:error, changeset} ->
        ApiResponses.changeset_error(conn, changeset)
    end
  end

  def edit(conn, params) do
    case Rooms.settings(params["id"]) do
      nil -> ApiResponses.error(conn, :not_found, "Room does not exist")
      room -> ApiResponses.ok(conn, room)
    end
  end

  def update(conn, params) do
    case Rooms.update_room(params["id"], params) do
      {:ok, _room, events} ->
        Events.dispatch_all(events)
        ApiResponses.ok(conn)

      {:error, :not_found} ->
        ApiResponses.error(conn, :not_found, "Room does not exist")

      {:error, changeset} ->
        ApiResponses.changeset_error(conn, changeset)
    end
  end

  def delete(conn, params) do
    case Rooms.delete_room(params["id"]) do
      {:ok, _room, events} ->
        Events.dispatch_all(events)
        ApiResponses.ok(conn)

      {:error, :not_found} ->
        ApiResponses.error(conn, :not_found, "Room does not exist")

      {:error, changeset} ->
        ApiResponses.changeset_error(conn, changeset)
    end
  end

  defp with_user_counts(rooms) do
    Enum.map(rooms, fn room ->
      Map.put(room, :users, Enum.count(Presence.list("room:" <> room[:route])))
    end)
  end
end
