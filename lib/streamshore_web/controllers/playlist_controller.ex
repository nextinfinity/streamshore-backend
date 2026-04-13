defmodule StreamshoreWeb.PlaylistController do
  use StreamshoreWeb, :controller

  alias Streamshore.Playlists
  alias StreamshoreWeb.ApiResponses

  plug StreamshoreWeb.Plugs.RequireAuth
  plug StreamshoreWeb.Plugs.RequireNonAnon
  plug StreamshoreWeb.Plugs.RequireCurrentUser, param: "user_id"

  def index(conn, _params) do
    conn.assigns.current_user
    |> Playlists.list_playlists()
    |> then(&ApiResponses.ok(conn, &1))
  end

  def create(conn, params) do
    case Playlists.create_playlist(conn.assigns.current_user, params) do
      {:ok, _schema} ->
        ApiResponses.ok(conn)

      {:error, changeset} ->
        ApiResponses.changeset_error(conn, changeset)
    end
  end

  def update(conn, params) do
    case Playlists.update_playlist(conn.assigns.current_user, params["id"], params) do
      {:ok, _schema} ->
        ApiResponses.ok(conn)

      {:error, :not_found} ->
        ApiResponses.error(conn, :not_found, "Playlist does not exist")

      {:error, changeset} ->
        ApiResponses.changeset_error(conn, changeset)
    end
  end

  def delete(conn, params) do
    case Playlists.delete_playlist(conn.assigns.current_user, params["id"]) do
      {:ok, _schema} ->
        ApiResponses.ok(conn)

      {:error, :not_found} ->
        ApiResponses.error(conn, :not_found, "Playlist does not exist")

      {:error, changeset} ->
        ApiResponses.changeset_error(conn, changeset)
    end
  end
end
