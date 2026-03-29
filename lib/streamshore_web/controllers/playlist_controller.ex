defmodule StreamshoreWeb.PlaylistController do
  use StreamshoreWeb, :controller
  import Ecto.Query, only: [from: 2]
  alias Streamshore.Guardian
  alias Streamshore.Playlist
  alias Streamshore.PlaylistVideo
  alias Streamshore.Repo

  def index(conn, params) do
    user = params["user_id"]
    query = from p in Playlist, where: p.owner == ^user, select: %{name: p.name}
    list = Repo.all(query)
    json(conn, list)
  end

  def show(_conn, _params) do
    # TODO: show playlist info
  end

  def create(conn, params) do
    case Guardian.get_user(Guardian.token_from_conn(conn)) do
      {:error, error} ->
        json(conn, %{error: error})

      {:ok, user, anon} ->
        cond do
          anon ->
            json(conn, %{error: "You must be logged in to create a playlist"})

          user != params["user_id"] ->
            json(conn, %{error: "Insufficient permission"})

          Playlist |> Repo.get_by(name: params["name"], owner: params["user_id"]) ->
            json(conn, %{error: "Playlist already exists"})

          true ->
            changeset =
              Playlist.changeset(%Playlist{}, %{name: params["name"], owner: params["user_id"]})

            case Repo.insert(changeset) do
              {:ok, _schema} ->
                json(conn, %{})

              {:error, _changeset} ->
                json(conn, %{error: "Unable to create playlist in database"})
            end
        end
    end
  end

  def update(conn, params) do
    case Guardian.get_user(Guardian.token_from_conn(conn)) do
      {:error, error} ->
        json(conn, %{error: error})

      {:ok, user, anon} ->
        playlist = params["id"]
        owner = params["user_id"]

        cond do
          anon ->
            json(conn, %{error: "You must be logged in to update a playlist"})

          user != owner ->
            json(conn, %{error: "Insufficient permission"})

          true ->
            relation = Playlist |> Repo.get_by(name: playlist, owner: owner)

            if relation do
              changeset = Playlist.changeset(relation, %{name: params["name"], owner: owner})
              successful = Repo.update(changeset)

              from(v in PlaylistVideo,
                where: v.name == ^playlist,
                update: [set: [name: ^params["name"]]]
              )
              |> Repo.update_all([])

              case successful do
                {:ok, _schema} ->
                  json(conn, %{})

                {:error, _changeset} ->
                  json(conn, %{error: "Unable to update playlist in database"})
              end
            else
              json(conn, %{error: "Playlist doesn't exist"})
            end
        end
    end
  end

  def delete(conn, params) do
    case Guardian.get_user(Guardian.token_from_conn(conn)) do
      {:error, error} ->
        json(conn, %{error: error})

      {:ok, user, anon} ->
        playlist = params["id"]
        owner = params["user_id"]

        cond do
          anon ->
            json(conn, %{error: "You must be logged in to delete a playlist"})

          user != owner ->
            json(conn, %{error: "Insufficient permission"})

          true ->
            query = from(v in PlaylistVideo, where: v.owner == ^owner and v.name == ^playlist)
            Repo.delete_all(query)

            case Playlist |> Repo.get_by(name: playlist, owner: owner) do
              nil ->
                json(conn, %{error: "Playlist doesn't exist"})

              relation ->
                case Repo.delete(relation) do
                  {:ok, _schema} ->
                    json(conn, %{})

                  {:error, _changeset} ->
                    json(conn, %{error: "Unable to delete playlist from database"})
                end
            end
        end
    end
  end
end
