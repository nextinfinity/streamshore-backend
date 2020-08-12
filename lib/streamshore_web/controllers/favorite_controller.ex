defmodule StreamshoreWeb.FavoriteController do
  import Ecto.Query, only: [from: 2]
  use StreamshoreWeb, :controller
  alias Streamshore.Favorites
  alias Streamshore.Guardian
  alias StreamshoreWeb.Presence
  alias Streamshore.Repo
  alias Streamshore.Room

  def index(conn, params) do
    user = params["user_id"]
    query = from f in Favorites, where: f.user == ^user, select: %{room: f.room}
    list = Repo.all(query)
    favorites = list |> Enum.map(fn a -> a.room end)

    query =
      from r in Room,
        where: r.route in ^favorites,
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

    json(conn, rooms)
  end

  def show(conn, params) do
    user = params["user_id"]
    room = params["id"]

    if Favorites |> Repo.get_by(user: user, room: room) do
      json(conn, true)
    else
      json(conn, false)
    end
  end

  def create(conn, params) do
    case Guardian.get_user(Guardian.token_from_conn(conn)) do
      {:error, error} ->
        json(conn, %{error: error})

      {:ok, _user, anon} ->
        case anon do
          false ->
            room = params["room"]
            user = params["user_id"]

            if Room |> Repo.get_by(route: room) do
              if !(Favorites |> Repo.get_by(user: user, room: room)) do
                changeset = Favorites.changeset(%Favorites{}, %{user: user, room: room})
                successful = Repo.insert(changeset)

                case successful do
                  {:ok, _schema} ->
                    json(conn, %{})

                  {:error, _changeset} ->
                    # TODO: error msg
                    json(conn, %{error: ""})
                end
              else
                json(conn, %{error: "Room is already a favorite room"})
              end
            else
              json(conn, %{error: "Room does not exist"})
            end

          true ->
            json(conn, %{error: "You must be logged in to add a room to favorites"})
        end
    end
  end

  def delete(conn, params) do
    room = params["id"]
    user = params["user_id"]
    relation = Favorites |> Repo.get_by(user: user, room: room)
    successful = Repo.delete(relation)

    case successful do
      {:ok, _schema} ->
        json(conn, %{})

      {:error, _changeset} ->
        # TODO: error msg
        json(conn, %{error: ""})
    end
  end
end
