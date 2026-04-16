defmodule FavoritesControllerTest do
  use StreamshoreWeb.ConnCase

  alias Streamshore.AuthTokens

  defp unique_value(prefix), do: "#{prefix}-#{System.unique_integer([:positive])}"

  defp authorized_conn(username) do
    token = AuthTokens.create_session_token(username, false)

    build_conn()
    |> put_req_header("authorization", "Bearer " <> token)
  end

  setup %{conn: conn} do
    current_user = unique_value("user")
    token = AuthTokens.create_session_token(current_user, false)

    conn =
      conn
      |> put_req_header("authorization", "Bearer " <> token)

    {:ok, conn: conn, current_user: current_user}
  end

  test "Adding a room to your favorites list", %{conn: conn, current_user: username} do
    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: unique_value("email") <> "@test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}
    conn = post(conn, Routes.room_path(conn, :create), %{name: "Create", motd: "", privacy: 0})
    assert json_response(conn, 200) == %{"route" => "create"}
    conn = post(conn, Routes.account_favorite_path(conn, :create), %{room: "Create"})
    assert json_response(conn, 200) == %{}
  end

  test "Removing a room from your favorites list", %{conn: conn, current_user: username} do
    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: unique_value("email") <> "@test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}
    conn = post(conn, Routes.room_path(conn, :create), %{name: "Create", motd: "", privacy: 0})
    assert json_response(conn, 200) == %{"route" => "create"}
    conn = post(conn, Routes.account_favorite_path(conn, :create), %{room: "Create"})
    assert json_response(conn, 200) == %{}
    conn = delete(conn, Routes.account_favorite_path(conn, :delete, "Create"))
    assert json_response(conn, 200) == %{}
  end

  test "authenticated users can add favorites to their own account", %{conn: conn} do
    conn = post(conn, Routes.room_path(conn, :create), %{name: "Create", motd: "", privacy: 0})
    assert json_response(conn, 200) == %{"route" => "create"}

    conn = post(conn, Routes.account_favorite_path(conn, :create), %{room: "Create"})
    assert json_response(conn, 200) == %{}
  end

  test "Adding a favorite without a token returns unauthorized" do
    conn =
      post(build_conn(), Routes.account_favorite_path(build_conn(), :create), %{
        room: "Create"
      })

    assert json_response(conn, 401) == %{"error" => "No valid token provided"}
  end

  test "Anonymous users cannot add favorites", %{conn: conn} do
    conn = post(conn, Routes.room_path(conn, :create), %{name: "Create", motd: "", privacy: 0})
    assert json_response(conn, 200) == %{"route" => "create"}

    token = AuthTokens.create_session_token("anon-user", true)

    anon_conn =
      build_conn()
      |> put_req_header("authorization", "Bearer " <> token)

    anon_conn =
      post(anon_conn, Routes.account_favorite_path(anon_conn, :create), %{
        room: "Create"
      })

    assert json_response(anon_conn, 403) ==
             %{"error" => "Insufficient permission"}
  end

  test "Adding a duplicate favorite returns conflict", %{conn: conn, current_user: username} do
    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: unique_value("email") <> "@test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}
    conn = post(conn, Routes.room_path(conn, :create), %{name: "Create", motd: "", privacy: 0})
    assert json_response(conn, 200) == %{"route" => "create"}
    conn = post(conn, Routes.account_favorite_path(conn, :create), %{room: "Create"})
    assert json_response(conn, 200) == %{}

    conn = post(conn, Routes.account_favorite_path(conn, :create), %{room: "Create"})
    assert json_response(conn, 409) == %{"error" => "Room is already a favorite room"}
  end

  test "Users cannot delete favorites for another user", %{conn: conn, current_user: username} do
    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: unique_value("email") <> "@test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}
    conn = post(conn, Routes.room_path(conn, :create), %{name: "Create", motd: "", privacy: 0})
    assert json_response(conn, 200) == %{"route" => "create"}
    conn = post(conn, Routes.account_favorite_path(conn, :create), %{room: "Create"})
    assert json_response(conn, 200) == %{}

    conn2 = authorized_conn("other-user")
    conn2 = delete(conn2, Routes.account_favorite_path(conn2, :delete, "Create"))
    assert json_response(conn2, 404) == %{"error" => "Favorite does not exist"}
  end
end
