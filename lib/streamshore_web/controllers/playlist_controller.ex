defmodule StreamshoreWeb.PlaylistController do
  use StreamshoreWeb, :controller
  import Ecto.Query, only: [from: 2]
  alias Streamshore.Guardian
  alias Streamshore.Playlist
  alias Streamshore.PlaylistVideo
  alias Streamshore.Repo
  alias StreamshoreWeb.ApiResponses

  def index(conn, params) do
    user = params["user_id"]
    query = from p in Playlist, where: p.owner == ^user, select: %{name: p.name}
    list = Repo.all(query)
    ApiResponses.ok(conn, list)
  end

  def show(_conn, _params) do
    # TODO: show playlist info
  end

  def create(conn, params) do
    case Guardian.get_user(Guardian.token_from_conn(conn)) do
      {:error, error} ->
        ApiResponses.error(conn, :unauthorized, error)

      {:ok, user, anon} ->
        cond do
          anon ->
            ApiResponses.error(conn, :forbidden, "You must be logged in to create a playlist")

          user != params["user_id"] ->
            ApiResponses.error(conn, :forbidden, "Insufficient permission")

          true ->
            changeset =
              Playlist.changeset(%Playlist{}, %{name: params["name"], owner: params["user_id"]})

            case Repo.insert(changeset) do
              {:ok, _schema} ->
                ApiResponses.ok(conn)

              {:error, changeset} ->
                ApiResponses.changeset_error(conn, changeset)
            end
        end
    end
  end

  def update(conn, params) do
    case Guardian.get_user(Guardian.token_from_conn(conn)) do
      {:error, error} ->
        ApiResponses.error(conn, :unauthorized, error)

      {:ok, user, anon} ->
        playlist = params["id"]
        owner = params["user_id"]

        cond do
          anon ->
            ApiResponses.error(conn, :forbidden, "You must be logged in to update a playlist")

          user != owner ->
            ApiResponses.error(conn, :forbidden, "Insufficient permission")

          true ->
            relation = Playlist |> Repo.get_by(name: playlist, owner: owner)

            if relation do
              changeset = Playlist.changeset(relation, %{name: params["name"], owner: owner})

              case Repo.update(changeset) do
                {:ok, _schema} ->
                  from(v in PlaylistVideo,
                    where: v.name == ^playlist,
                    update: [set: [name: ^params["name"]]]
                  )
                  |> Repo.update_all([])

                  ApiResponses.ok(conn)

                {:error, changeset} ->
                  ApiResponses.changeset_error(conn, changeset)
              end
            else
              ApiResponses.error(conn, :not_found, "Playlist doesn't exist")
            end
        end
    end
  end

  def delete(conn, params) do
    case Guardian.get_user(Guardian.token_from_conn(conn)) do
      {:error, error} ->
        ApiResponses.error(conn, :unauthorized, error)

      {:ok, user, anon} ->
        playlist = params["id"]
        owner = params["user_id"]

        cond do
          anon ->
            ApiResponses.error(conn, :forbidden, "You must be logged in to delete a playlist")

          user != owner ->
            ApiResponses.error(conn, :forbidden, "Insufficient permission")

          true ->
            query = from(v in PlaylistVideo, where: v.owner == ^owner and v.name == ^playlist)
            Repo.delete_all(query)

            case Playlist |> Repo.get_by(name: playlist, owner: owner) do
              nil ->
                ApiResponses.error(conn, :not_found, "Playlist doesn't exist")

              relation ->
                case Repo.delete(relation) do
                  {:ok, _schema} ->
                    ApiResponses.ok(conn)

                  {:error, changeset} ->
                    ApiResponses.changeset_error(conn, changeset)
                end
            end
        end
    end
  end
end
