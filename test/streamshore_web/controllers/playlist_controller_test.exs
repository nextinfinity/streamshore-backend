defmodule PlaylistControllerTest do
  use StreamshoreWeb.ConnCase

  alias Streamshore.Guardian

  setup %{conn: conn} do
    {:ok, token, _claims} = Guardian.encode_and_sign("user", %{anon: false, admin: false})

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

    assert Enum.at(Enum.at(list, 0), 0)["channel"] == "VVitch"
    assert Enum.at(Enum.at(list, 0), 0)["id"] == "_-k6ppRkpcM"

    assert Enum.at(Enum.at(list, 0), 0)["thumbnail"] ==
             "https://i.ytimg.com/vi/_-k6ppRkpcM/hqdefault.jpg"

    assert Enum.at(Enum.at(list, 0), 0)["title"] == "the snow storm cant get us here"
  end
end
