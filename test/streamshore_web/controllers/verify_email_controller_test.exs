defmodule VerifyEmailControllerTest do
  use StreamshoreWeb.ConnCase

  alias Streamshore.AuthTokens
  alias Streamshore.Repo
  alias Streamshore.User

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

  test "resending verification always returns 202", %{conn: conn} do
    conn =
      post(conn, Routes.verify_email_path(conn, :resend_email_verification), %{
        identifier: "missing@example.com"
      })

    assert json_response(conn, 202) == %{}
  end

  test "email verification rejects an invalid token", %{conn: conn} do
    conn =
      post(conn, Routes.verify_email_path(conn, :verify_email), %{
        token: "invalid-token"
      })

    assert json_response(conn, 401) == %{"error" => "Invalid token"}
  end

  test "email verification returns conflict for an already verified user", %{
    conn: conn,
    current_user: username
  } do
    Application.put_env(:streamshore, :mailer_enabled, true)
    Application.put_env(:streamshore, :mailer_from_address, "noreply@example.com")

    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: unique_value("verify") <> "@test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    user = Repo.get_by!(User, username: username)

    conn =
      post(conn, Routes.verify_email_path(conn, :verify_email), %{
        token: user.verify_token
      })

    assert json_response(conn, 200) == %{}

    conn =
      post(conn, Routes.verify_email_path(conn, :verify_email), %{
        token: user.verify_token
      })

    assert json_response(conn, 409) == %{"error" => "Email already verified"}
  end
end
