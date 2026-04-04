defmodule StreamshoreWeb.PlaylistVideoController do
  use StreamshoreWeb, :controller

  alias Streamshore.Guardian
  alias Streamshore.Playlists
  alias StreamshoreWeb.ApiResponses

  def index(conn, params) do
    video_list = Playlists.list_playlist_videos(params["user_id"], params["playlist_id"])
    ApiResponses.ok(conn, video_list)
  end

  def show(_conn, _params) do
    # TODO: show video info
  end

  def create(conn, params) do
    case Guardian.get_user(Guardian.token_from_conn(conn)) do
      {:error, error} ->
        ApiResponses.error(conn, :unauthorized, error)

      {:ok, user, anon} ->
        video = params["video"]
        playlist = params["playlist_id"]
        owner = params["user_id"]

        cond do
          anon ->
            ApiResponses.error(
              conn,
              :forbidden,
              "You must be logged in to add a video to a playlist"
            )

          user != owner ->
            ApiResponses.error(conn, :forbidden, "Insufficient permission")

          true ->
            case Playlists.add_playlist_video(owner, playlist, video) do
              {:ok, _schema} ->
                ApiResponses.ok(conn)

              {:error, :playlist_not_found} ->
                ApiResponses.error(conn, :not_found, "Playlist doesn't exists")

              {:error, :invalid_video} ->
                ApiResponses.error(conn, :unprocessable_entity, "Invalid video")

              {:error, changeset} ->
                ApiResponses.changeset_error(conn, changeset)
            end
        end
    end
  end

  def update(_conn, _params) do
    # TODO: video edit action
  end

  def delete(conn, params) do
    case Guardian.get_user(Guardian.token_from_conn(conn)) do
      {:error, error} ->
        ApiResponses.error(conn, :unauthorized, error)

      {:ok, user, anon} ->
        video = params["id"]
        playlist = params["playlist_id"]
        owner = params["user_id"]

        cond do
          anon ->
            ApiResponses.error(
              conn,
              :forbidden,
              "You must be logged in to delete a video from a playlist"
            )

          user != owner ->
            ApiResponses.error(conn, :forbidden, "Insufficient permission")

          true ->
            case Playlists.delete_playlist_video(owner, playlist, video) do
              {:error, :not_found} ->
                ApiResponses.error(conn, :not_found, "Video doesn't exist in playlist")

              {:ok, _schema} ->
                ApiResponses.ok(conn)

              {:error, changeset} ->
                ApiResponses.changeset_error(conn, changeset)
            end
        end
    end
  end
end
