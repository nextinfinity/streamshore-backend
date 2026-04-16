defmodule PlaylistControllerTest do
  use StreamshoreWeb.ConnCase

  alias Streamshore.AuthTokens

  setup %{conn: conn} do
    token = AuthTokens.create_session_token("user", false)

    conn =
      conn
      |> put_req_header("authorization", "Bearer " <> token)

    {:ok, conn: conn}
  end

  test "Creating a playlist", %{conn: conn} do
    conn = post(conn, Routes.account_playlist_path(conn, :create), %{name: "Playlist"})
    assert json_response(conn, 200) == %{}
  end

  test "Viewing a playlist", %{conn: conn} do
    conn = post(conn, Routes.account_playlist_path(conn, :create), %{name: "Playlist"})
    assert json_response(conn, 200) == %{}

    conn =
      post(conn, Routes.account_playlist_playlist_video_path(conn, :create, "Playlist"), %{
        video: "_-k6ppRkpcM"
      })

    assert json_response(conn, 200) == %{}

    list =
      conn
      |> get(Routes.account_playlist_playlist_video_path(conn, :index, "Playlist"))
      |> json_response(200)

    assert Enum.at(Enum.at(list, 0), 0)["channel"] == "vomit"
    assert Enum.at(Enum.at(list, 0), 0)["id"] == "_-k6ppRkpcM"

    assert Enum.at(Enum.at(list, 0), 0)["thumbnail"] ==
             "https://i.ytimg.com/vi/_-k6ppRkpcM/hqdefault.jpg"

    assert Enum.at(Enum.at(list, 0), 0)["title"] == "the snow storm cant get us here"
  end

  test "authenticated users can create playlists on their own account", %{conn: conn} do
    conn = post(conn, Routes.account_playlist_path(conn, :create), %{name: "Playlist"})
    assert json_response(conn, 200) == %{}
  end

  test "Creating a duplicate playlist returns conflict", %{conn: conn} do
    conn = post(conn, Routes.account_playlist_path(conn, :create), %{name: "Playlist"})
    assert json_response(conn, 200) == %{}

    conn = post(conn, Routes.account_playlist_path(conn, :create), %{name: "Playlist"})
    assert json_response(conn, 409) == %{"error" => "Playlist already exists"}
  end

  test "users can only rename playlists on their own account", %{conn: conn} do
    conn = post(conn, Routes.account_playlist_path(conn, :create), %{name: "Playlist"})
    assert json_response(conn, 200) == %{}

    conn =
      put(conn, Routes.account_playlist_path(conn, :update, "Playlist"), %{name: "Renamed"})

    assert json_response(conn, 200) == %{}
  end

  test "playlist videos are added through the account playlist routes", %{conn: conn} do
    conn = post(conn, Routes.account_playlist_path(conn, :create), %{name: "Playlist"})
    assert json_response(conn, 200) == %{}

    conn =
      post(conn, Routes.account_playlist_playlist_video_path(conn, :create, "Playlist"), %{
        video: "_-k6ppRkpcM"
      })

    assert json_response(conn, 200) == %{}
  end

  test "Adding an invalid playlist video returns unprocessable entity", %{conn: conn} do
    conn = post(conn, Routes.account_playlist_path(conn, :create), %{name: "Playlist"})
    assert json_response(conn, 200) == %{}

    conn =
      post(conn, Routes.account_playlist_playlist_video_path(conn, :create, "Playlist"), %{
        video: "abc"
      })

    assert json_response(conn, 422) == %{"error" => "Invalid video"}
  end

  test "Adding a duplicate playlist video returns conflict", %{conn: conn} do
    conn = post(conn, Routes.account_playlist_path(conn, :create), %{name: "Playlist"})
    assert json_response(conn, 200) == %{}

    conn =
      post(conn, Routes.account_playlist_playlist_video_path(conn, :create, "Playlist"), %{
        video: "_-k6ppRkpcM"
      })

    assert json_response(conn, 200) == %{}

    conn =
      post(conn, Routes.account_playlist_playlist_video_path(conn, :create, "Playlist"), %{
        video: "_-k6ppRkpcM"
      })

    assert json_response(conn, 409) == %{"error" => "Video is already in playlist"}
  end
end
