defmodule PlaylistControllerTest do
  use StreamshoreWeb.ConnCase

  alias Streamshore.Guardian

  defp authorized_conn(username) do
    {:ok, token, _claims} = Guardian.encode_and_sign(username, %{anon: false})

    build_conn()
    |> put_req_header("authorization", "Bearer " <> token)
  end

  setup %{conn: conn} do
    {:ok, token, _claims} = Guardian.encode_and_sign("user", %{anon: false})

    conn =
      conn
      |> put_req_header("authorization", "Bearer " <> token)

    {:ok, conn: conn}
  end

  test "Creating a playlist", %{conn: conn} do
    conn = post(conn, Routes.user_playlist_path(conn, :create, "user"), %{name: "Playlist"})
    assert json_response(conn, 200) == %{}
  end

  test "Viewing a playlist", %{conn: conn} do
    conn = post(conn, Routes.user_playlist_path(conn, :create, "user"), %{name: "Playlist"})
    assert json_response(conn, 200) == %{}

    conn =
      post(conn, Routes.user_playlist_playlist_video_path(conn, :create, "user", "Playlist"), %{
        video: "_-k6ppRkpcM"
      })

    assert json_response(conn, 200) == %{}

    list =
      conn
      |> get(Routes.user_playlist_playlist_video_path(conn, :index, "user", "Playlist"))
      |> json_response(200)

    assert Enum.at(Enum.at(list, 0), 0)["channel"] == "vomit"
    assert Enum.at(Enum.at(list, 0), 0)["id"] == "_-k6ppRkpcM"

    assert Enum.at(Enum.at(list, 0), 0)["thumbnail"] ==
             "https://i.ytimg.com/vi/_-k6ppRkpcM/hqdefault.jpg"

    assert Enum.at(Enum.at(list, 0), 0)["title"] == "the snow storm cant get us here"
  end

  test "Users cannot create playlists for another user", %{conn: conn} do
    conn = post(conn, Routes.user_playlist_path(conn, :create, "other-user"), %{name: "Playlist"})
    assert json_response(conn, 403) == %{"error" => "Insufficient permission"}
  end

  test "Users cannot rename playlists they do not own", %{conn: conn} do
    conn = post(conn, Routes.user_playlist_path(conn, :create, "user"), %{name: "Playlist"})
    assert json_response(conn, 200) == %{}

    conn2 = authorized_conn("other-user")

    conn2 =
      put(conn2, Routes.user_playlist_path(conn2, :update, "user", "Playlist"), %{name: "Renamed"})

    assert json_response(conn2, 403) == %{"error" => "Insufficient permission"}
  end

  test "Users cannot add playlist videos for another user", %{conn: conn} do
    conn = post(conn, Routes.user_playlist_path(conn, :create, "user"), %{name: "Playlist"})
    assert json_response(conn, 200) == %{}

    conn2 = authorized_conn("other-user")

    conn2 =
      post(conn2, Routes.user_playlist_playlist_video_path(conn2, :create, "user", "Playlist"), %{
        video: "_-k6ppRkpcM"
      })

    assert json_response(conn2, 403) == %{"error" => "Insufficient permission"}
  end

  test "Adding an invalid playlist video returns unprocessable entity", %{conn: conn} do
    conn = post(conn, Routes.user_playlist_path(conn, :create, "user"), %{name: "Playlist"})
    assert json_response(conn, 200) == %{}

    conn =
      post(conn, Routes.user_playlist_playlist_video_path(conn, :create, "user", "Playlist"), %{
        video: "abc"
      })

    assert json_response(conn, 422) == %{"error" => "Invalid youtube video"}
  end
end
