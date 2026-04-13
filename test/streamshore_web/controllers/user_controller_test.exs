defmodule UserControllerTest do
  use StreamshoreWeb.ConnCase
  import Phoenix.ChannelTest

  @endpoint StreamshoreWeb.Endpoint

  alias Streamshore.Accounts
  alias Streamshore.Guardian

  setup %{conn: conn} do
    original_mailer_enabled = Application.get_env(:streamshore, :mailer_enabled)
    original_mailer_from_address = Application.get_env(:streamshore, :mailer_from_address)

    on_exit(fn ->
      Application.put_env(:streamshore, :mailer_enabled, original_mailer_enabled)
      Application.put_env(:streamshore, :mailer_from_address, original_mailer_from_address)
    end)

    {:ok, token, _claims} = Guardian.encode_and_sign("user", %{anon: false})

    conn =
      conn
      |> put_req_header("authorization", "Bearer " <> token)

    {:ok, conn: conn}
  end

  test "Registering an account", %{conn: conn} do
    username = "Test Account"

    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "Email@Test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}
  end

  test "Registering an account with invalid password", %{conn: conn} do
    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "Email@Test.com",
        username: "Test Account",
        password: "BadPass"
      })

    assert json_response(conn, 422) == %{"error" => "Password is invalid"}
  end

  test "Registering an account without password", %{conn: conn} do
    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "Email@Test.com",
        username: "Test Account"
      })

    assert json_response(conn, 422) == %{"error" => "Password can't be blank"}
  end

  test "Cannot register duplicate user", %{conn: conn} do
    username = "Test Account"

    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "Email@Test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "Email@Testing.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 409) == %{"error" => "Username has already been taken"}
  end

  test "Updating with valid password", %{conn: conn} do
    username = "user"

    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "Email@Test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    conn = put(conn, Routes.user_path(conn, :update, username), %{password: "$NewPass123"})
    assert json_response(conn, 200) == %{}
  end

  test "Updating with invalid password", %{conn: conn} do
    username = "user"

    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "Email@Test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}
    conn = put(conn, Routes.user_path(conn, :update, username), %{password: "BadPass"})
    assert json_response(conn, 422) == %{"error" => "Password is invalid"}
  end

  test "Updating without supported params returns bad request", %{conn: conn} do
    conn = put(conn, Routes.user_path(conn, :update, "user"), %{"ignored" => "value"})

    assert json_response(conn, 400) == %{"error" => "No valid options specified"}
  end

  test "Updating password without a token returns unauthorized", %{conn: _conn} do
    conn =
      put(build_conn(), Routes.user_path(build_conn(), :update, "user"), %{
        password: "$NewPass123"
      })

    assert json_response(conn, 401) == %{"error" => "No valid token provided"}
  end

  test "Anonymous users cannot update passwords", %{conn: conn} do
    username = "anon-reset-user"

    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "anon-reset@test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    {:ok, token, _claims} = Guardian.encode_and_sign("anon-user", %{anon: true})

    anon_conn =
      build_conn()
      |> put_req_header("authorization", "Bearer " <> token)

    anon_conn =
      put(anon_conn, Routes.user_path(anon_conn, :update, username), %{password: "$NewPass123"})

    assert json_response(anon_conn, 403) == %{"error" => "Insufficient permission"}
  end

  test "Resending verification for an unknown user returns not found", %{conn: conn} do
    conn =
      put(conn, Routes.user_path(conn, :update, "missing-user"), %{resend_verification: true})

    assert json_response(conn, 404) == %{"error" => "User not found"}
  end

  test "Verifying with an invalid token returns unauthorized", %{conn: conn} do
    Application.put_env(:streamshore, :mailer_enabled, true)
    Application.put_env(:streamshore, :mailer_from_address, "noreply@example.com")

    username = "verified-user"

    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "verify@test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    conn = put(conn, Routes.user_path(conn, :update, username), %{verify_token: "invalid-token"})

    assert json_response(conn, 401) == %{"error" => "Invalid token"}
  end

  test "Verifying an already verified user returns conflict", %{conn: conn} do
    Application.put_env(:streamshore, :mailer_enabled, true)
    Application.put_env(:streamshore, :mailer_from_address, "noreply@example.com")

    username = "verified-user"

    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "verify@test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    user = Accounts.get_by_email_or_username(username)

    conn =
      put(conn, Routes.user_path(conn, :update, username), %{verify_token: user.verify_token})

    assert json_response(conn, 200) == %{}

    conn =
      put(conn, Routes.user_path(conn, :update, username), %{verify_token: user.verify_token})

    assert json_response(conn, 409) == %{"error" => "Email already verified"}
  end

  test "Requesting a password reset for an unknown user returns not found", %{conn: conn} do
    conn =
      put(conn, Routes.user_path(conn, :update, "missing@example.com"), %{reset_password: true})

    assert json_response(conn, 404) == %{"error" => "User not found"}
  end

  test "Updating password with a stored reset token", %{conn: conn} do
    username = "reset-user"

    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "reset@test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    assert {:ok, _updated_user, [{:send_password_reset_email, _event_user, token}]} =
             Accounts.request_password_reset("reset@test.com")

    reset_conn =
      build_conn()
      |> put_req_header("authorization", "Bearer " <> token)

    reset_conn =
      put(reset_conn, Routes.user_path(reset_conn, :update, username), %{password: "$NewPass123"})

    assert json_response(reset_conn, 200) == %{}
  end

  test "Rejecting a forged reset-subject token during password update", %{conn: conn} do
    username = "reset-user"

    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "reset@test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    {:ok, forged_token, _claims} = Guardian.encode_and_sign("Reset-" <> username, %{anon: false})

    reset_conn =
      build_conn()
      |> put_req_header("authorization", "Bearer " <> forged_token)

    reset_conn =
      put(reset_conn, Routes.user_path(reset_conn, :update, username), %{password: "$NewPass123"})

    assert json_response(reset_conn, 403) == %{"error" => "Insufficient permission"}
  end

  test "Deleting account", %{conn: conn} do
    username = "user"

    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "Email@Test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}
    conn = delete(conn, Routes.user_path(conn, :delete, username))
    assert json_response(conn, 200) == %{}
  end

  test "Deleting account broadcasts room deletion for owned rooms", %{conn: conn} do
    username = "user"

    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "Email@Test.com",
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

    conn = delete(conn, Routes.user_path(conn, :delete, username))

    assert json_response(conn, 200) == %{}
    assert_broadcast "room-deleted", %{}
  end

  test "Deleting account with wrong credentials", %{conn: conn} do
    username = "Not User"

    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "Email@Test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}
    conn = delete(conn, Routes.user_path(conn, :delete, username))
    assert json_response(conn, 403) == %{"error" => "Insufficient permission"}
  end

  test "Getting list of all users as admin", %{conn: conn} do
    username = "Test Account"

    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "Email@Test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    assert {:ok, _user} = Accounts.set_admin("Test Account", 1)

    {:ok, token, _claims} = Guardian.encode_and_sign("Test Account", %{anon: false})

    conn2 =
      build_conn()
      |> put_req_header("authorization", "Bearer " <> token)

    conn2 = get(conn2, Routes.user_path(conn2, :index))

    assert json_response(conn2, 200) == [
             %{
               "email" => "Email@Test.com",
               "username" => "Test Account",
               "admin" => 1,
               "room" => nil,
               "verify_token" => nil
             }
           ]
  end

  test "Getting list of all users as non-admin", %{conn: conn} do
    conn = get(conn, Routes.user_path(conn, :index))
    assert json_response(conn, 403) == %{"error" => "Insufficient permission"}
  end

  test "Getting list of all users without a token returns unauthorized" do
    conn = get(build_conn(), Routes.user_path(build_conn(), :index))

    assert json_response(conn, 401) == %{"error" => "No valid token provided"}
  end
end
