defmodule StreamshoreWeb.PlaylistVideoController do
  use StreamshoreWeb, :controller
  import Ecto.Query, only: [from: 2]
  alias Streamshore.Guardian
  alias Streamshore.Playlist
  alias Streamshore.PlaylistVideo
  alias Streamshore.Repo
  alias Streamshore.YouTube

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

    json(conn, video_list)
  end

  def show(_conn, _params) do
    # TODO: show video info
  end

  def create(conn, params) do
    case Guardian.get_user(Guardian.token_from_conn(conn)) do
      {:error, error} ->
        json(conn, %{error: error})

      {:ok, user, anon} ->
        video = params["video"]
        playlist = params["playlist_id"]
        owner = params["user_id"]

        cond do
          anon ->
            json(conn, %{error: "You must be logged in to add a video to a playlist"})

          user != owner ->
            json(conn, %{error: "Insufficient permission"})

          !(Playlist |> Repo.get_by(name: playlist, owner: owner)) ->
            json(conn, %{error: "Playlist doesn't exists"})

          PlaylistVideo |> Repo.get_by(name: playlist, owner: owner, video: video) ->
            json(conn, %{error: "Video is already in playlist"})

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
                    json(conn, %{})

                  {:error, _changeset} ->
                    json(conn, %{error: "Unable to create video in database"})
                end

              {:error, _error} ->
                json(conn, %{error: "Invalid youtube video"})
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
        json(conn, %{error: error})

      {:ok, user, anon} ->
        video = params["id"]
        playlist = params["playlist_id"]
        owner = params["user_id"]

        cond do
          anon ->
            json(conn, %{error: "You must be logged in to delete a video from a playlist"})

          user != owner ->
            json(conn, %{error: "Insufficient permission"})

          true ->
            case PlaylistVideo |> Repo.get_by(name: playlist, owner: owner, video: video) do
              nil ->
                json(conn, %{error: "Video doesn't exist in playlist"})

              relation ->
                case Repo.delete(relation) do
                  {:ok, _schema} ->
                    json(conn, %{})

                  {:error, _changeset} ->
                    json(conn, %{error: "Unable to delete video from database"})
                end
            end
        end
    end
  end
end
