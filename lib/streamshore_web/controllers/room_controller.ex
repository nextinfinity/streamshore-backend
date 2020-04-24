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
      if params["search"] do 
        route = String.downcase(String.replace(params["search"], " ", "-"))
        route = Regex.replace(~r/[^A-Za-z0-9\-]/, route, "")
        route = "%" <> route <> "%"
        query = from r in Room, where: like(r.route, ^route), select: %{name: r.name, owner: r.owner, route: r.route, thumbnail: r.thumbnail, privacy: r.privacy}
        rooms = Repo.all(query)
        rooms = Enum.map(rooms, fn room -> Map.put(room, :users, Enum.count(Presence.list("room:" <> room[:route]))) end)
        json(conn, rooms)
      else 
        user = params["user"]
        query = from r in Room, where: r.owner == ^user, select: %{name: r.name, owner: r.owner, route: r.route, thumbnail: r.thumbnail, privacy: r.privacy}
        rooms = Repo.all(query)
        rooms = Enum.map(rooms, fn room -> Map.put(room, :users, Enum.count(Presence.list("room:" <> room[:route]))) end)
        json(conn, rooms)
      end
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

  def edit(conn, params) do
    case Guardian.get_user_and_permission(Guardian.token_from_conn(conn), params["id"]) do
      {:error, error} -> json(conn, %{error: error})
      {:ok, _user, _anon, permission} ->
        if permission >= PermissionLevel.manager() do
          query = from r in Room, where: r.route == ^params["id"], select: %{motd: r.motd, privacy: r.privacy,
            queue_level: r.queue_level, anon_queue: r.anon_queue, queue_limit: r.queue_limit, chat_level: r.chat_level,
            anon_chat: r.anon_chat, chat_filter: r.chat_filter, vote_enable: r.vote_enable, vote_threshold: r.vote_threshold}
          room = Repo.one(query)
          json(conn, room)
        end
    end
  end

  def update(conn, params) do
    case Guardian.get_user_and_permission(Guardian.token_from_conn(conn), params["id"]) do
      {:error, error} -> json(conn, %{error: error})
      {:ok, _user, _anon, permission} ->
        if permission >= PermissionLevel.manager() do
          room = params["id"]
          case Repo.get_by(Room, %{route: room}) do
            nil -> nil
            schema -> params = params |> Map.delete("id")
                      schema
                      |> Room.changeset(params)
                      |> Repo.update
                      params = params |> Map.take([:motd, :queue_level, :anon_queue, :queue_limit, :chat_level, :anon_chat, :vote_enable])
                      StreamshoreWeb.Endpoint.broadcast("room:" <> room, "update", params)
          end
          json(conn, %{})
        end
    end

  end

  def delete(conn, params) do
    case Guardian.get_user(Guardian.token_from_conn(conn)) do
      {:error, error} -> json(conn, %{error: error})
      {:ok, user, _anon} ->
        room_name = params["id"]
        query = from r in Room, where: r.route == ^room_name, select: r.owner
        owner = Repo.one(query)
        if user == owner do
          favorites = from(f in Favorites, where: f.room == ^room_name)
          Repo.delete_all(favorites)
          permissions = from(p in Permission, where: p.room == ^room_name)
          Repo.delete_all(permissions)
          room = Room |> Repo.get_by(route: room_name)
          case Repo.delete(room) do
            {:ok, _schema}->
              StreamshoreWeb.Endpoint.broadcast("room:" <> room_name, "room-deleted", %{})
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

  def get_room(room) do
    query = from r in Room, where: r.route == ^room, select: %{name: r.name, motd: r.motd, owner: r.owner,
      route: r.route, queue_level: r.queue_level, anon_queue: r.anon_queue, chat_level: r.chat_level,
      anon_chat: r.anon_chat, queue_limit: r.queue_limit, vote_enable: r.vote_enable}
    Repo.one(query)
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