defmodule StreamshoreWeb.PlaylistVideoController do
  use StreamshoreWeb, :controller

  alias Streamshore.Playlists
  alias StreamshoreWeb.ApiResponses

  plug StreamshoreWeb.Plugs.RequireAuth
  plug StreamshoreWeb.Plugs.RequireNonAnon
  plug StreamshoreWeb.Plugs.RequireCurrentUser, param: "user_id"

  def index(conn, params) do
    Playlists.list_playlist_videos(conn.assigns.current_user, params["playlist_id"])
    |> then(&ApiResponses.ok(conn, &1))
  end

  def create(conn, params) do
    case Playlists.add_playlist_video(
           conn.assigns.current_user,
           params["playlist_id"],
           params["video"]
         ) do
      {:ok, _schema} ->
        ApiResponses.ok(conn)

      {:error, :playlist_not_found} ->
        ApiResponses.error(conn, :not_found, "Playlist does not exist")

      {:error, :invalid_video} ->
        ApiResponses.error(conn, :unprocessable_entity, "Invalid video")

      {:error, changeset} ->
        ApiResponses.changeset_error(conn, changeset)
    end
  end

  def delete(conn, params) do
    case Playlists.delete_playlist_video(
           conn.assigns.current_user,
           params["playlist_id"],
           params["id"]
         ) do
      {:ok, _schema} ->
        ApiResponses.ok(conn)

      {:error, :not_found} ->
        ApiResponses.error(conn, :not_found, "Video does not exist in playlist")

      {:error, changeset} ->
        ApiResponses.changeset_error(conn, changeset)
    end
  end
end
