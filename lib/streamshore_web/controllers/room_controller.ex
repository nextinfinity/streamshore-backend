defmodule StreamshoreWeb.RoomController do
  use StreamshoreWeb, :controller
  alias Streamshore.Guardian
  alias StreamshoreWeb.PermissionController
  alias Streamshore.PermissionLevel
  alias StreamshoreWeb.Presence
  alias Streamshore.Permission
  alias Streamshore.Favorites
  alias Streamshore.Repo
  alias Streamshore.Room
  alias Streamshore.Util
  import Ecto.Query

  def index(conn, params) do
    if (Enum.count(params) != 0) do
      route = String.downcase(String.replace(params["search"], " ", "-"))
      route = Regex.replace(~r/[^A-Za-z0-9\-]/, route, "")
      route = "%" <> route <> "%"
      query = from r in Room, where: like(r.route, ^route), select: %{name: r.name, owner: r.owner, route: r.route, thumbnail: r.thumbnail, privacy: r.privacy}
      rooms = Repo.all(query)
      rooms = Enum.map(rooms, fn room -> Map.put(room, :users, Enum.count(Presence.list("room:" <> room[:route]))) end)
      json(conn, rooms)
    else
      query = from r in Room, select: %{name: r.name, owner: r.owner, route: r.route, thumbnail: r.thumbnail, privacy: r.privacy}
      rooms = Repo.all(query)
      rooms = Enum.map(rooms, fn room -> Map.put(room, :users, Enum.count(Presence.list("room:" <> room[:route]))) end)
      json(conn, rooms)
    end
  end

  def show(conn, params) do
    room = Repo.get_by(Room, route: params["id"])
    if room do
      json(conn, %{name: room.name})
    else
      json(conn, %{error: "Room does not exist"})
    end
  end

  def create(conn, params) do
    case Guardian.get_user(Guardian.token_from_conn(conn)) do
      {:error, error} -> json(conn, %{error: error})
      {:ok, user, anon} ->
        case anon do
          false ->
            route = String.downcase(String.replace(params["name"], " ", "-"))
            route = Regex.replace(~r/[^A-Za-z0-9\-]/, route, "")
            params = params
                     |> Map.put("route", route)
                     |> Map.put("owner", user)
            success = %Streamshore.Room{}
                      |> Room.changeset(params)
                      |> Repo.insert()

            case success do
              {:ok, _schema}->
                PermissionController.update_perm(params["route"], user, PermissionLevel.owner())
                json(conn, %{route: route})

              {:error, changeset}->
                errors = Util.convert_changeset_errors(changeset)
                key = Enum.at(Map.keys(errors), 0)
                err = "Room " <> Atom.to_string(key) <> " " <> Enum.at(errors[key], 0)
                json(conn, %{error: err})
            end
          true -> json(conn, %{error: "You must be logged in to create a room"})
        end
    end
  end

  def update(conn, params) do
    case Guardian.get_user_and_permission(Guardian.token_from_conn(conn), params["id"]) do
      {:error, error} -> json(conn, %{error: error})
      {:ok, _user, _anon, permission} ->
        if permission >= PermissionLevel.manager() do
          case Repo.get_by(Room, %{route: params["id"]}) do
            nil -> nil
            schema -> schema
                      |> Room.changeset(params)
                      |> Repo.update
          end
          json(conn, %{})
        end
    end

  end

  def delete(conn, params) do
    case Guardian.get_user(Guardian.token_from_conn(conn)) do
      {:error, error} -> json(conn, %{error: error})
      {:ok, user, anon} ->
        room_name = params["id"]
        query = from r in Room, where: r.name == ^room_name, select: %{owner: r.owner}
        list = Repo.all(query)
        room = list |> Enum.map(fn a-> a.owner end)
        owner = to_string(room)
        if to_string(user) == to_string(room) do
          query = from(f in Favorites, where: f.room == ^room_name)
          successful1 = Repo.delete_all(query)
          query = from(p in Permission, where: p.room == ^room_name)
          successful2 = Repo.delete_all(query)
          relation = Room |> Repo.get_by(name: room_name)
          successful3 = Repo.delete(relation)
          case successful1 && successful2 && successful3 do
              {:ok, _schema}->
                json(conn, %{})

              {:error, _changeset}->
                # TODO: error msg
                json(conn, %{error: ""})
          end
        else
          json(conn, %{error: "Insufficient permission"})
        end
    end
  end

  def filter_enabled?(room) do
    room = Repo.get_by(Room, route: room)
    if room do
      room.chat_filter == 1
    else
      false
    end
  end

  def queue_perm(room) do
    case Repo.get_by(Room, route: room) do
      nil -> PermissionLevel.user()
      room -> room.queue_level
    end
  end

  def anon_queue?(room) do
    case Repo.get_by(Room, route: room) do
      nil -> ""
      room -> room.anon_queue == 1
    end
  end

  def chat_perm(room) do
    case Repo.get_by(Room, route: room) do
      nil -> PermissionLevel.user()
      room -> room.chat_level
    end
  end

  def anon_chat?(room) do
    case Repo.get_by(Room, route: room) do
      nil -> ""
      room -> room.anon_chat == 1
    end
  end

  def get_motd(room) do
    case Repo.get_by(Room, route: room) do
      nil -> ""
      room -> room.motd
    end
  end

end