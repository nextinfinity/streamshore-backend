defmodule UserControllerTest do
  use StreamshoreWeb.ConnCase
  import Phoenix.ChannelTest

  alias Streamshore.Accounts
  alias Streamshore.Guardian

  defp unique_value(prefix), do: "#{prefix}-#{System.unique_integer([:positive])}"

  setup %{conn: conn} do
    current_user = unique_value("user")

    original_mailer_enabled = Application.get_env(:streamshore, :mailer_enabled)
    original_mailer_from_address = Application.get_env(:streamshore, :mailer_from_address)

    on_exit(fn ->
      Application.put_env(:streamshore, :mailer_enabled, original_mailer_enabled)
      Application.put_env(:streamshore, :mailer_from_address, original_mailer_from_address)
    end)

    {:ok, token, _claims} = Guardian.encode_and_sign(current_user, %{anon: false})

    conn =
      conn
      |> put_req_header("authorization", "Bearer " <> token)

    {:ok, conn: conn, current_user: current_user}
  end

  test "registering a user account succeeds", %{conn: conn} do
    username = unique_value("test-account")

    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: unique_value("email") <> "@test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}
  end

  test "registering a user account validates password strength", %{conn: conn} do
    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: unique_value("email") <> "@test.com",
        username: unique_value("test-account"),
        password: "BadPass"
      })

    assert json_response(conn, 422) == %{"error" => "Password is invalid"}
  end

  test "registering a user account requires a password", %{conn: conn} do
    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: unique_value("email") <> "@test.com",
        username: unique_value("test-account")
      })

    assert json_response(conn, 422) == %{"error" => "Password can't be blank"}
  end

  test "registering a duplicate user returns conflict", %{conn: conn} do
    username = unique_value("test-account")
    email = unique_value("email") <> "@test.com"

    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: email,
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: unique_value("email") <> "@test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 409) == %{"error" => "Username has already been taken"}
  end

  test "deleting the current user account succeeds", %{conn: conn, current_user: username} do

    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: unique_value("email") <> "@test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}
    conn = delete(conn, Routes.account_path(conn, :delete))
    assert json_response(conn, 200) == %{}
  end

  test "deleting the current user account broadcasts room deletion for owned rooms", %{
    conn: conn,
    current_user: username
  } do

    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: unique_value("email") <> "@test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    conn =
      post(conn, Routes.room_path(conn, :create), %{
        name: "Owned Room",
        motd: "",
        privacy: 0
      })

    assert json_response(conn, 200) == %{"route" => "owned-room"}

    {:ok, _, _socket} =
      socket(StreamshoreWeb.UserSocket, "friend", %{user: "friend", anon: true})
      |> subscribe_and_join(StreamshoreWeb.RoomChannel, "room:owned-room")

    conn = delete(conn, Routes.account_path(conn, :delete))

    assert json_response(conn, 200) == %{}
    assert_broadcast "room-deleted", %{}
  end

  test "deleting the current account removes the authenticated user", %{conn: conn, current_user: username} do
    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: unique_value("email") <> "@test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}
    conn = delete(conn, Routes.account_path(conn, :delete))
    assert json_response(conn, 200) == %{}
  end

  test "admins can list all users", %{conn: conn} do
    username = unique_value("test-account")
    email = unique_value("email") <> "@test.com"

    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: email,
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    assert {:ok, _user} = Accounts.set_admin(username, 1)

    {:ok, token, _claims} = Guardian.encode_and_sign(username, %{anon: false})

    conn2 =
      build_conn()
      |> put_req_header("authorization", "Bearer " <> token)

    conn2 = get(conn2, Routes.user_path(conn2, :index))

    users = json_response(conn2, 200)

    assert Enum.any?(users, fn user ->
             user == %{
               "email" => email,
               "username" => username,
               "admin" => 1,
               "room" => nil,
               "verify_token" => nil
             }
           end)
  end

  test "non-admin users cannot list all users", %{conn: conn} do
    conn = get(conn, Routes.user_path(conn, :index))
    assert json_response(conn, 403) == %{"error" => "Insufficient permission"}
  end

  test "listing all users requires a token" do
    conn = get(build_conn(), Routes.user_path(build_conn(), :index))

    assert json_response(conn, 401) == %{"error" => "No valid token provided"}
  end
end
