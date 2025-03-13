defmodule FavoritesControllerTest do
  use StreamshoreWeb.ConnCase

  alias Streamshore.Guardian

  setup %{conn: conn} do
    {:ok, token, _claims} = Guardian.encode_and_sign("user", %{anon: false})

    conn =
      conn
      |> put_req_header("authorization", "Bearer " <> token)

    {:ok, conn: conn}
  end

  test "Adding a room to your favorites list", %{conn: conn} do
    username = "user"

    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "Email@Test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}
    conn = post(conn, Routes.room_path(conn, :create), %{name: "Create", motd: "", privacy: 0})
    assert json_response(conn, 200) == %{"route" => "create"}
    conn = post(conn, Routes.user_favorite_path(conn, :create, username), %{room: "Create"})
    assert json_response(conn, 200) == %{}
  end

  test "Removing a room from your favorites list", %{conn: conn} do
    username = "user"

    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "Email@Test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}
    conn = post(conn, Routes.room_path(conn, :create), %{name: "Create", motd: "", privacy: 0})
    assert json_response(conn, 200) == %{"route" => "create"}
    conn = post(conn, Routes.user_favorite_path(conn, :create, username), %{room: "Create"})
    assert json_response(conn, 200) == %{}
    conn = delete(conn, Routes.user_favorite_path(conn, :delete, username, "Create"))
    assert json_response(conn, 200) == %{}
  end
end
