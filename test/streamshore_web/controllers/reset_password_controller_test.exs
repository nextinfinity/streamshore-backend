defmodule ResetPasswordControllerTest do
  use StreamshoreWeb.ConnCase

  alias Streamshore.Accounts
  alias Streamshore.Guardian

  defp unique_value(prefix), do: "#{prefix}-#{System.unique_integer([:positive])}"

  test "password reset request always gives 202", %{conn: conn} do
    conn =
      post(conn, Routes.reset_password_path(conn, :request_password_reset), %{
        identifier: "missing@example.com"
      })

    assert json_response(conn, 202) == %{}
  end

  test "reset tokens can be used to set a new password", %{conn: conn} do
    username = unique_value("reset-user")
    email = unique_value("reset") <> "@test.com"

    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: email,
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    assert {:ok, _updated_user, [{:send_password_reset_email, _event_user, token}]} =
             Accounts.request_password_reset(email)

    conn =
      post(conn, Routes.reset_password_path(conn, :reset_password), %{
        token: token,
        password: "$NewPass123"
      })

    assert json_response(conn, 200) == %{}
  end

  test "forged reset-subject tokens cannot be used to set a new password", %{conn: conn} do
    username = unique_value("reset-user")

    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: unique_value("reset") <> "@test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    {:ok, forged_token, _claims} = Guardian.encode_and_sign("Reset-" <> username, %{anon: false})

    conn =
      post(conn, Routes.reset_password_path(conn, :reset_password), %{
        token: forged_token,
        password: "$NewPass123"
      })

    assert json_response(conn, 401) == %{"error" => "Invalid token"}
  end
end
