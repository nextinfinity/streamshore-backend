defmodule StreamshoreWeb.PlaylistVideoController do
  use StreamshoreWeb, :controller
  import Ecto.Query, only: [from: 2]
  alias Streamshore.Repo
  alias Streamshore.Playlist
  alias Streamshore.PlaylistVideo
  alias Streamshore.Guardian

  def index(conn, params) do
    # TODO: Add fix for youtube video being valid (i.e. if video was valid but removed from youtube)
    user = params["user_id"]
    playlist = params["playlist_id"]

    query =
      from v in PlaylistVideo,
        where: v.owner == ^user and v.name == ^playlist,
        select: %{video: v.video}

    list = Repo.all(query)
    _video_list = %{videos: []}
    video_ids = list |> Enum.map(fn a -> a.video end)

    video_list =
      Enum.map(video_ids, fn item ->
        id = item

        data =
          HTTPoison.get!(
            "https://www.googleapis.com/youtube/v3/videos?id=" <>
              id <> "&key=AIzaSyBWO0zsG8H5Uf4PTXMVPvTNNUxp__cTMO0&part=snippet,contentDetails"
          )

        body = Enum.at(Poison.decode!(data.body)["items"], 0)

        if body do
          title = body["snippet"]["title"]
          channel = body["snippet"]["channelTitle"]
          thumbnail = body["snippet"]["thumbnails"]["high"]["url"]
          _video = [%{id: id, title: title, channel: channel, thumbnail: thumbnail}]
        end
      end)

    json(conn, video_list)
  end

  def show(_conn, _params) do
    # TODO: show video info
  end

  def create(conn, params) do
    case Guardian.get_user(Guardian.token_from_conn(conn)) do
      {:error, error} ->
        json(conn, %{error: error})

      {:ok, _user, anon} ->
        case anon do
          false ->
            video = params["video"]
            playlist = params["playlist_id"]
            owner = params["user_id"]
            relation = Playlist |> Repo.get_by(name: playlist, owner: owner)

            if relation do
              relation2 = PlaylistVideo |> Repo.get_by(name: playlist, owner: owner, video: video)

              if !relation2 do
                data =
                  HTTPoison.get!(
                    "https://www.googleapis.com/youtube/v3/videos?id=" <>
                      video <>
                      "&key=AIzaSyBWO0zsG8H5Uf4PTXMVPvTNNUxp__cTMO0&part=snippet,contentDetails"
                  )

                body = Enum.at(Poison.decode!(data.body)["items"], 0)

                if body do
                  changeset =
                    PlaylistVideo.changeset(%PlaylistVideo{}, %{
                      name: playlist,
                      owner: owner,
                      video: video
                    })

                  successful = Repo.insert(changeset)

                  case successful do
                    {:ok, _schema} ->
                      json(conn, %{})

                    {:error, _changeset} ->
                      # TODO: error msg
                      json(conn, %{error: ""})
                  end
                else
                  json(conn, %{error: "Invalid youtube video"})
                end
              else
                json(conn, %{error: "Video is already in playlist"})
              end
            else
              json(conn, %{error: "Playlist doesn't exists"})
            end

          true ->
            json(conn, %{error: "You must be logged in to add a video to a playlist"})
        end
    end
  end

  def update(_conn, _params) do
    # TODO: video edit action
  end

  def delete(conn, params) do
    video = params["id"]
    playlist = params["playlist_id"]
    owner = params["user_id"]
    relation = PlaylistVideo |> Repo.get_by(name: playlist, owner: owner, video: video)
    successful = Repo.delete(relation)

    case successful do
      {:ok, _schema} ->
        json(conn, %{})

      {:error, _changeset} ->
        # TODO: error msg
        json(conn, %{error: ""})
    end
  end
end
