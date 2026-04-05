defmodule Streamshore.Playlists do
  import Ecto.Query

  alias Ecto.Multi
  alias Streamshore.Playlist
  alias Streamshore.PlaylistVideo
  alias Streamshore.Repo
  alias Streamshore.VideoFetcher

  def list_playlists(owner) do
    Repo.all(from p in Playlist, where: p.owner == ^owner, select: %{name: p.name})
  end

  def create_playlist(owner, attrs) do
    %Playlist{}
    |> Playlist.changeset(%{name: attrs["name"], owner: owner})
    |> Repo.insert()
  end

  def update_playlist(owner, playlist_name, attrs) do
    case Repo.get_by(Playlist, name: playlist_name, owner: owner) do
      nil ->
        {:error, :not_found}

      playlist ->
        Multi.new()
        |> Multi.update(
          :playlist,
          Playlist.changeset(playlist, %{name: attrs["name"], owner: owner})
        )
        |> Multi.update_all(
          :playlist_videos,
          from(v in PlaylistVideo, where: v.owner == ^owner and v.name == ^playlist_name),
          set: [name: attrs["name"]]
        )
        |> Repo.transaction()
        |> case do
          {:ok, %{playlist: updated_playlist}} -> {:ok, updated_playlist}
          {:error, _step, changeset, _changes} -> {:error, changeset}
        end
    end
  end

  def delete_playlist(owner, playlist_name) do
    case Repo.get_by(Playlist, name: playlist_name, owner: owner) do
      nil ->
        {:error, :not_found}

      playlist ->
        Multi.new()
        |> Multi.delete_all(
          :playlist_videos,
          from(v in PlaylistVideo, where: v.owner == ^owner and v.name == ^playlist_name)
        )
        |> Multi.delete(:playlist, playlist)
        |> Repo.transaction()
        |> case do
          {:ok, %{playlist: deleted_playlist}} -> {:ok, deleted_playlist}
          {:error, _step, changeset, _changes} -> {:error, changeset}
        end
    end
  end

  def list_playlist_videos(owner, playlist_name) do
    Repo.all(
      from v in PlaylistVideo,
        where: v.owner == ^owner and v.name == ^playlist_name,
        select: v.video
    )
    |> Enum.map(&fetch_playlist_video/1)
    |> Enum.reject(&is_nil/1)
  end

  def add_playlist_video(owner, playlist_name, video_id) do
    case Repo.get_by(Playlist, name: playlist_name, owner: owner) do
      nil ->
        {:error, :playlist_not_found}

      %Playlist{} ->
        case VideoFetcher.fetch_video(video_id) do
          {:ok, _video} ->
            %PlaylistVideo{}
            |> PlaylistVideo.changeset(%{name: playlist_name, owner: owner, video: video_id})
            |> Repo.insert()

          {:error, _error} ->
            {:error, :invalid_video}
        end
    end
  end

  def delete_playlist_video(owner, playlist_name, video_id) do
    case Repo.delete_all(
           from v in PlaylistVideo,
             where: v.name == ^playlist_name and v.owner == ^owner and v.video == ^video_id
         ) do
      {0, _} -> {:error, :not_found}
      {_count, _} -> {:ok, :deleted}
    end
  end

  defp fetch_playlist_video(video_id) do
    case VideoFetcher.fetch_video(video_id) do
      {:ok, video} ->
        [Map.take(video, [:id, :title, :channel, :thumbnail])]

      {:error, _error} ->
        nil
    end
  end
end
