defmodule StreamshoreWeb.FavoriteController do
  import Ecto.Query, only: [from: 2]
  use StreamshoreWeb, :controller
  alias Streamshore.Favorites
  alias Streamshore.Guardian
  alias Streamshore.Repo
  alias Streamshore.Room

  def index(conn, params) do
    user = params["user_id"]
    query = from f in Favorites, where: f.user == ^user, select: %{room: f.romm}
    list = Repo.all(query)
    json(conn, list)
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
      {:error, error} -> json(conn, %{error: error})
      {:ok, _user, anon} ->
        case anon do
          false ->
            room = params["room"]
            user = params["user_id"]
            if Room |> Repo.get_by(name: room) do
                if !(Favorites |> Repo.get_by(user: user, room: room)) do 
                    changeset = Favorites.changeset(%Favorites{}, %{user: user, room: room})
                    successful = Repo.insert(changeset)

                    case successful do
                        {:ok, _schema}->
                        json(conn, %{})

                        {:error, _changeset}->
                        # TODO: error msg
                        json(conn, %{error: ""})
                    end
                else 
                    json(conn, %{error: "Room is already a favorite room"})
                end
            else 
                json(conn, %{error: "Room does not exist"})
            end
          true -> json(conn, %{error: "You must be logged in to add a room to favorites"})
        end
    end
  end

  def delete(conn, params) do
    room = params["id"]
    user = params["user_id"]
    relation = Favorites |> Repo.get_by(user: user, room: room)
    successful = Repo.delete(relation)
    case successful do
      {:ok, _schema}->
        json(conn, %{})

      {:error, _changeset}->
        # TODO: error msg
        json(conn, %{error: ""})
    end
  end
end