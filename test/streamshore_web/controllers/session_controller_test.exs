defmodule SessionControllerTest do
  use StreamshoreWeb.ConnCase

  alias Streamshore.Accounts
  alias Streamshore.Repo
  alias Streamshore.User

  defp unique_value(prefix), do: "#{prefix}-#{System.unique_integer([:positive])}"

  setup do
    original_mailer_enabled = Application.get_env(:streamshore, :mailer_enabled)
    original_mailer_from_address = Application.get_env(:streamshore, :mailer_from_address)

    on_exit(fn ->
      Application.put_env(:streamshore, :mailer_enabled, original_mailer_enabled)
      Application.put_env(:streamshore, :mailer_from_address, original_mailer_from_address)
    end)

    :ok
  end

  test "Getting an anonymous username", %{conn: conn} do
    session =
      conn
      |> post(Routes.session_path(conn, :create))
      |> json_response(200)

    assert session["user"]
  end

  test "Anonymous usernames are different", %{conn: conn} do
    session =
      conn
      |> post(Routes.session_path(conn, :create))
      |> json_response(200)

    assert session["user"]

    second_session =
      conn
      |> post(Routes.session_path(conn, :create))
      |> json_response(200)

    assert second_session["user"]
    assert session["user"] != second_session["user"]
  end

  test "Username validation", %{conn: conn} do
    username = unique_value("test-account")

    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: unique_value("email") <> "@test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}
    conn = post(conn, Routes.session_path(conn, :create), %{id: "bad", password: "$Test123"})
    assert json_response(conn, 401) == %{"error" => "Invalid credentials"}
  end

  test "Password validation", %{conn: conn} do
    username = unique_value("test-account")

    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: unique_value("email") <> "@test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    conn =
      post(conn, Routes.session_path(conn, :create), %{id: username, password: "bad"})

    assert json_response(conn, 401) == %{"error" => "Invalid credentials"}
  end

  test "Logging in via username", %{conn: conn} do
    username = unique_value("test-account")

    Application.put_env(:streamshore, :mailer_enabled, true)
    Application.put_env(:streamshore, :mailer_from_address, "noreply@example.com")

    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: unique_value("email") <> "@test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    user = Repo.get_by!(User, username: username)
    assert {:ok, _verified_user} = Accounts.verify_email(username, user.verify_token)

    conn =
      post(conn, Routes.session_path(conn, :create), %{id: username, password: "$Test123"})

    assert json_response(conn, 200)["user"] == username
  end

  test "Logging in before email verification is forbidden", %{conn: conn} do
    username = unique_value("test-account")
    Application.put_env(:streamshore, :mailer_enabled, true)
    Application.put_env(:streamshore, :mailer_from_address, "noreply@example.com")

    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: unique_value("email") <> "@test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    conn =
      post(conn, Routes.session_path(conn, :create), %{id: username, password: "$Test123"})

    assert json_response(conn, 403) == %{"error" => "Email address not verified"}
  end

  test "Attempting to log in with bad username", %{conn: conn} do
    username = unique_value("test-account")

    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: unique_value("email") <> "@test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    conn =
      post(conn, Routes.session_path(conn, :create), %{id: "Wrong Username", password: "$Test123"})

    assert json_response(conn, 401) == %{"error" => "Invalid credentials"}
  end
end
