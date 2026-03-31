defmodule StreamshoreWeb.FavoriteController do
  import Ecto.Query, only: [from: 2]
  use StreamshoreWeb, :controller
  alias Streamshore.Favorites
  alias Streamshore.Guardian
  alias StreamshoreWeb.Presence
  alias Streamshore.Repo
  alias Streamshore.Room
  alias StreamshoreWeb.ApiResponses

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

    ApiResponses.ok(conn, rooms)
  end

  def show(conn, params) do
    user = params["user_id"]
    room = params["id"]

    if Favorites |> Repo.get_by(user: user, room: room) do
      ApiResponses.ok(conn, true)
    else
      ApiResponses.ok(conn, false)
    end
  end

  def create(conn, params) do
    case Guardian.get_user(Guardian.token_from_conn(conn)) do
      {:error, error} ->
        ApiResponses.error(conn, :unauthorized, error)

      {:ok, current_user, anon} ->
        room = params["room"]
        user = params["user_id"]

        cond do
          anon ->
            ApiResponses.error(conn, :forbidden, "You must be logged in to add a room to favorites")

          current_user != user ->
            ApiResponses.error(conn, :forbidden, "Insufficient permission")

          !(Room |> Repo.get_by(route: room)) ->
            ApiResponses.error(conn, :not_found, "Room does not exist")

          Favorites |> Repo.get_by(user: user, room: room) ->
            ApiResponses.error(conn, :unprocessable_entity, "Room is already a favorite room")

          true ->
            changeset = Favorites.changeset(%Favorites{}, %{user: user, room: room})

            case Repo.insert(changeset) do
              {:ok, _schema} ->
                ApiResponses.ok(conn)

              {:error, _changeset} ->
                ApiResponses.error(conn, :unprocessable_entity, "Unable to create favorite in database")
            end
        end
    end
  end

  def delete(conn, params) do
    case Guardian.get_user(Guardian.token_from_conn(conn)) do
      {:error, error} ->
        ApiResponses.error(conn, :unauthorized, error)

      {:ok, current_user, anon} ->
        room = params["id"]
        user = params["user_id"]

        cond do
          anon ->
            ApiResponses.error(conn, :forbidden, "You must be logged in to remove a room from favorites")

          current_user != user ->
            ApiResponses.error(conn, :forbidden, "Insufficient permission")

          true ->
            case Favorites |> Repo.get_by(user: user, room: room) do
              nil ->
                ApiResponses.error(conn, :not_found, "Favorite does not exist")

              relation ->
                case Repo.delete(relation) do
                  {:ok, _schema} ->
                    ApiResponses.ok(conn)

                  {:error, _changeset} ->
                    ApiResponses.error(conn, :unprocessable_entity, "Unable to delete favorite from database")
                end
            end
        end
    end
  end
end
