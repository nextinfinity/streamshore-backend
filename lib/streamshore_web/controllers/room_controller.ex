defmodule StreamshoreWeb.RoomController do
  use StreamshoreWeb, :controller
  alias Streamshore.Guardian
  alias Streamshore.RoomPermissions
  alias Streamshore.PermissionLevel
  alias StreamshoreWeb.Presence
  alias Streamshore.Permission
  alias Streamshore.Favorites
  alias Streamshore.Repo
  alias Streamshore.Room
  alias Streamshore.Rooms
  alias Streamshore.Util
  alias StreamshoreWeb.ApiResponses
  import Ecto.Query

  def index(conn, params) do
    if Enum.count(params) != 0 do
      if params["search"] do
        route = String.downcase(String.replace(params["search"], " ", "-"))
        route = Regex.replace(~r/[^A-Za-z0-9\-]/, route, "")
        route = "%" <> route <> "%"

        query =
          from r in Room,
            where: like(r.route, ^route),
            select: %{
              name: r.name,
              owner: r.owner,
              route: r.route,
              thumbnail: r.thumbnail,
              privacy: r.privacy
            }

        rooms = Repo.all(query)

        rooms =
          Enum.map(rooms, fn room ->
            Map.put(room, :users, Enum.count(Presence.list("room:" <> room[:route])))
          end)

        ApiResponses.ok(conn, rooms)
      else
        user = params["user"]

        query =
          from r in Room,
            where: r.owner == ^user,
            select: %{
              name: r.name,
              owner: r.owner,
              route: r.route,
              thumbnail: r.thumbnail,
              privacy: r.privacy
            }

        rooms = Repo.all(query)

        rooms =
          Enum.map(rooms, fn room ->
            Map.put(room, :users, Enum.count(Presence.list("room:" <> room[:route])))
          end)

        ApiResponses.ok(conn, rooms)
      end
    else
      query =
        from r in Room,
          select: %{
            name: r.name,
            owner: r.owner,
            route: r.route,
            thumbnail: r.thumbnail,
            privacy: r.privacy
          }

      rooms = Repo.all(query)

      rooms =
        Enum.map(rooms, fn room ->
          Map.put(room, :users, Enum.count(Presence.list("room:" <> room[:route])))
        end)

      ApiResponses.ok(conn, rooms)
    end
  end

  def show(conn, params) do
    room = Repo.get_by(Room, route: params["id"])

    if room do
      ApiResponses.ok(conn, %{name: room.name})
    else
      ApiResponses.error(conn, :not_found, "Room does not exist")
    end
  end

  def create(conn, params) do
    case Guardian.get_user(Guardian.token_from_conn(conn)) do
      {:error, error} ->
        ApiResponses.error(conn, :unauthorized, error)

      {:ok, user, anon} ->
        case anon do
          false ->
            route = Rooms.sanitize_route(params["name"])

            params =
              params
              |> Map.put("route", route)
              |> Map.put("owner", user)

            success =
              %Streamshore.Room{}
              |> Room.changeset(params)
              |> Repo.insert()

            case success do
              {:ok, _schema} ->
                RoomPermissions.update_perm(params["route"], user, PermissionLevel.owner())
                ApiResponses.ok(conn, %{route: route})

              {:error, changeset} ->
                errors = Util.convert_changeset_errors(changeset)
                key = Enum.at(Map.keys(errors), 0)
                err = "Room " <> Atom.to_string(key) <> " " <> Enum.at(errors[key], 0)
                ApiResponses.error(conn, :unprocessable_entity, err)
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

          case Repo.get_by(Room, %{route: room}) do
            nil ->
              ApiResponses.error(conn, :not_found, "Room does not exist")

            schema ->
              params = params |> Map.delete("id")

              case schema |> Room.changeset(params) |> Repo.update() do
                {:ok, _schema} ->
                  params =
                    params
                    |> Map.take([
                      "motd",
                      "queue_level",
                      "anon_queue",
                      "queue_limit",
                      "chat_level",
                      "anon_chat",
                      "vote_enable"
                    ])

                  StreamshoreWeb.Endpoint.broadcast("room:" <> room, "update", params)
                  ApiResponses.ok(conn)

                {:error, changeset} ->
                  errors = Util.convert_changeset_errors(changeset)
                  key = Enum.at(Map.keys(errors), 0)
                  err = "Room " <> Atom.to_string(key) <> " " <> Enum.at(errors[key], 0)
                  ApiResponses.error(conn, :unprocessable_entity, err)
              end
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
        owner = Rooms.owner(room_name)

        cond do
          is_nil(owner) ->
            ApiResponses.error(conn, :not_found, "Room does not exist")

          owner != user ->
            ApiResponses.error(conn, :forbidden, "Insufficient permission")

          true ->
            favorites = from(f in Favorites, where: f.room == ^room_name)
            Repo.delete_all(favorites)
            permissions = from(p in Permission, where: p.room == ^room_name)
            Repo.delete_all(permissions)
            room = Room |> Repo.get_by(route: room_name)

            case Repo.delete(room) do
              {:ok, _schema} ->
                StreamshoreWeb.Endpoint.broadcast("room:" <> room_name, "room-deleted", %{})
                ApiResponses.ok(conn)

              {:error, _changeset} ->
                ApiResponses.error(conn, :unprocessable_entity, "Unable to delete room from database")
            end
        end
    end
  end
end
