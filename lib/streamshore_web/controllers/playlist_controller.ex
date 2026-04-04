defmodule StreamshoreWeb.PlaylistController do
  use StreamshoreWeb, :controller

  alias Streamshore.Guardian
  alias Streamshore.Playlists
  alias StreamshoreWeb.ApiResponses

  def index(conn, params) do
    params["user_id"]
    |> Playlists.list_playlists()
    |> then(&ApiResponses.ok(conn, &1))
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
            case Playlists.create_playlist(params["user_id"], params) do
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
            case Playlists.update_playlist(owner, playlist, params) do
              {:ok, _schema} ->
                ApiResponses.ok(conn)

              {:error, :not_found} ->
                ApiResponses.error(conn, :not_found, "Playlist doesn't exist")

              {:error, changeset} ->
                ApiResponses.changeset_error(conn, changeset)
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
            case Playlists.delete_playlist(owner, playlist) do
              {:error, :not_found} ->
                ApiResponses.error(conn, :not_found, "Playlist doesn't exist")

              {:ok, _schema} ->
                ApiResponses.ok(conn)

              {:error, changeset} ->
                ApiResponses.changeset_error(conn, changeset)
            end
        end
    end
  end
end
