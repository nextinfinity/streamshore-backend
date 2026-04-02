defmodule StreamshoreWeb.PlaylistVideoController do
  use StreamshoreWeb, :controller
  import Ecto.Query, only: [from: 2]
  alias Streamshore.Guardian
  alias Streamshore.Playlist
  alias Streamshore.PlaylistVideo
  alias Streamshore.Repo
  alias Streamshore.YouTube
  alias StreamshoreWeb.ApiResponses

  def index(conn, params) do
    user = params["user_id"]
    playlist = params["playlist_id"]

    query =
      from v in PlaylistVideo,
        where: v.owner == ^user and v.name == ^playlist,
        select: %{video: v.video}

    list = Repo.all(query)
    video_ids = list |> Enum.map(fn a -> a.video end)

    video_list =
      Enum.map(video_ids, fn item ->
        case YouTube.fetch_video(item) do
          {:ok, video} ->
            [Map.take(video, [:id, :title, :channel, :thumbnail])]

          {:error, _error} ->
            nil
        end
      end)
      |> Enum.reject(&is_nil/1)

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
            ApiResponses.error(conn, :forbidden, "You must be logged in to add a video to a playlist")

          user != owner ->
            ApiResponses.error(conn, :forbidden, "Insufficient permission")

          !(Playlist |> Repo.get_by(name: playlist, owner: owner)) ->
            ApiResponses.error(conn, :not_found, "Playlist doesn't exists")

          true ->
            case YouTube.fetch_video(video) do
              {:ok, _video} ->
                changeset =
                  PlaylistVideo.changeset(%PlaylistVideo{}, %{
                    name: playlist,
                    owner: owner,
                    video: video
                  })

                case Repo.insert(changeset) do
                  {:ok, _schema} ->
                    ApiResponses.ok(conn)

                  {:error, changeset} ->
                    ApiResponses.changeset_error(conn, changeset)
                end

              {:error, _error} ->
                ApiResponses.error(conn, :unprocessable_entity, "Invalid youtube video")
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
            ApiResponses.error(conn, :forbidden, "You must be logged in to delete a video from a playlist")

          user != owner ->
            ApiResponses.error(conn, :forbidden, "Insufficient permission")

          true ->
            case PlaylistVideo |> Repo.get_by(name: playlist, owner: owner, video: video) do
              nil ->
                ApiResponses.error(conn, :not_found, "Video doesn't exist in playlist")

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
