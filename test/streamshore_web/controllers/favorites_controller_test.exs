defmodule FavoritesControllerTest do
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

  test "Users cannot add favorites for another user", %{conn: conn} do
    conn = post(conn, Routes.room_path(conn, :create), %{name: "Create", motd: "", privacy: 0})
    assert json_response(conn, 200) == %{"route" => "create"}

    conn = post(conn, Routes.user_favorite_path(conn, :create, "other-user"), %{room: "Create"})
    assert json_response(conn, 200) == %{"error" => "Insufficient permission"}
  end

  test "Users cannot delete favorites for another user", %{conn: conn} do
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

    conn2 = authorized_conn("other-user")
    conn2 = delete(conn2, Routes.user_favorite_path(conn2, :delete, username, "Create"))
    assert json_response(conn2, 200) == %{"error" => "Insufficient permission"}
  end
end
