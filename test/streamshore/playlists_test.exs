defmodule Streamshore.PlaylistsTest do
  use Streamshore.DataCase, async: false

  alias Streamshore.Playlist
  alias Streamshore.PlaylistVideo
  alias Streamshore.Playlists
  alias Streamshore.Repo

  test "create_playlist inserts a playlist for the owner" do
    assert {:ok, playlist} = Playlists.create_playlist("user-one", %{"name" => "Favorites"})

    assert playlist.name == "Favorites"
    assert Repo.get_by(Playlist, owner: "user-one", name: "Favorites") != nil
  end

  test "update_playlist renames the playlist and its videos" do
    Repo.insert!(Playlist.changeset(%Playlist{}, %{owner: "user-one", name: "Favorites"}))

    Repo.insert!(
      PlaylistVideo.changeset(%PlaylistVideo{}, %{
        owner: "user-one",
        name: "Favorites",
        video: "_-k6ppRkpcM"
      })
    )

    assert {:ok, playlist} =
             Playlists.update_playlist("user-one", "Favorites", %{"name" => "Renamed"})

    assert playlist.name == "Renamed"

    assert Repo.get_by(PlaylistVideo, owner: "user-one", name: "Renamed", video: "_-k6ppRkpcM") !=
             nil
  end

  test "delete_playlist removes the playlist and its videos" do
    Repo.insert!(Playlist.changeset(%Playlist{}, %{owner: "user-one", name: "Favorites"}))

    Repo.insert!(
      PlaylistVideo.changeset(%PlaylistVideo{}, %{
        owner: "user-one",
        name: "Favorites",
        video: "_-k6ppRkpcM"
      })
    )

    assert {:ok, _playlist} = Playlists.delete_playlist("user-one", "Favorites")
    assert Repo.get_by(Playlist, owner: "user-one", name: "Favorites") == nil

    assert Repo.get_by(PlaylistVideo, owner: "user-one", name: "Favorites", video: "_-k6ppRkpcM") ==
             nil
  end

  test "add_playlist_video validates the playlist and stores the video" do
    Repo.insert!(Playlist.changeset(%Playlist{}, %{owner: "user-one", name: "Favorites"}))

    assert {:ok, playlist_video} =
             Playlists.add_playlist_video("user-one", "Favorites", "_-k6ppRkpcM")

    assert playlist_video.video == "_-k6ppRkpcM"

    assert Repo.get_by(PlaylistVideo, owner: "user-one", name: "Favorites", video: "_-k6ppRkpcM") !=
             nil
  end

  test "add_playlist_video returns invalid_video for unknown videos" do
    Repo.insert!(Playlist.changeset(%Playlist{}, %{owner: "user-one", name: "Favorites"}))

    assert {:error, :invalid_video} =
             Playlists.add_playlist_video("user-one", "Favorites", "not-a-real-video")
  end

  test "delete_playlist_video removes the stored relation" do
    Repo.insert!(Playlist.changeset(%Playlist{}, %{owner: "user-one", name: "Favorites"}))

    Repo.insert!(
      PlaylistVideo.changeset(%PlaylistVideo{}, %{
        owner: "user-one",
        name: "Favorites",
        video: "_-k6ppRkpcM"
      })
    )

    assert {:ok, _playlist_video} =
             Playlists.delete_playlist_video("user-one", "Favorites", "_-k6ppRkpcM")

    assert Repo.get_by(PlaylistVideo, owner: "user-one", name: "Favorites", video: "_-k6ppRkpcM") ==
             nil
  end

  test "delete_playlist_video returns not_found when the relation is missing" do
    assert {:error, :not_found} =
             Playlists.delete_playlist_video("user-one", "Favorites", "_-k6ppRkpcM")
  end
end
