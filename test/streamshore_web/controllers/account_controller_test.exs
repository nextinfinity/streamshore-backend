defmodule AccountControllerTest do
  use StreamshoreWeb.ConnCase

  alias Streamshore.AuthTokens

  defp unique_value(prefix), do: "#{prefix}-#{System.unique_integer([:positive])}"

  setup %{conn: conn} do
    current_user = unique_value("user")

    original_mailer_enabled = Application.get_env(:streamshore, :mailer_enabled)
    original_mailer_from_address = Application.get_env(:streamshore, :mailer_from_address)

    on_exit(fn ->
      Application.put_env(:streamshore, :mailer_enabled, original_mailer_enabled)
      Application.put_env(:streamshore, :mailer_from_address, original_mailer_from_address)
    end)

    token = AuthTokens.create_session_token(current_user, false)

    conn =
      conn
      |> put_req_header("authorization", "Bearer " <> token)

    {:ok, conn: conn, current_user: current_user}
  end

  test "authenticated users can change their password", %{conn: conn, current_user: username} do
    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: unique_value("email") <> "@test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    conn =
      put(conn, Routes.account_update_password_path(conn, :update_password), %{
        password: "$NewPass123"
      })

    assert json_response(conn, 200) == %{}
  end

  test "password changes validate the new password", %{conn: conn, current_user: username} do
    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: unique_value("email") <> "@test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    conn =
      put(conn, Routes.account_update_password_path(conn, :update_password), %{
        password: "BadPass"
      })

    assert json_response(conn, 422) == %{"error" => "Password is invalid"}
  end

  test "password changes require a token", %{conn: _conn} do
    conn = build_conn()

    conn =
      put(conn, Routes.account_update_password_path(conn, :update_password), %{
        password: "$NewPass123"
      })

    assert json_response(conn, 401) == %{"error" => "No valid token provided"}
  end

  test "password reset tokens cannot be used as session tokens", %{conn: conn} do
    reset_token = AuthTokens.create_password_reset_token("user-from-reset-token")

    conn =
      build_conn()
      |> put_req_header("authorization", "Bearer " <> reset_token)
      |> put(Routes.account_update_password_path(conn, :update_password), %{
        password: "$NewPass123"
      })

    assert json_response(conn, 401) == %{"error" => "Invalid token"}
  end

  test "anonymous users cannot change passwords", %{conn: conn} do
    username = unique_value("anon-reset-user")

    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: unique_value("anon-reset") <> "@test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    token = AuthTokens.create_session_token("anon-user", true)

    anon_conn =
      build_conn()
      |> put_req_header("authorization", "Bearer " <> token)

    anon_conn =
      put(anon_conn, Routes.account_update_password_path(conn, :update_password), %{
        password: "$NewPass123"
      })

    assert json_response(anon_conn, 403) == %{"error" => "Insufficient permission"}
  end
end
