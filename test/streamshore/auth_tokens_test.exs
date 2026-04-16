defmodule Streamshore.AuthTokensTest do
  use ExUnit.Case, async: true

  alias Streamshore.AuthTokens

  test "verify_email_username decodes verification tokens" do
    token = AuthTokens.create_verify_email_token("verify-user")

    assert {:ok, "verify-user"} = AuthTokens.verify_email_username(token)
  end

  test "session_resource decodes session tokens" do
    token = AuthTokens.create_session_token("session-user", true)

    assert {:ok, %{user: "session-user", anon: true}} = AuthTokens.session_resource(token)
  end

  test "session_resource rejects verification tokens" do
    token = AuthTokens.create_verify_email_token("session-user")

    assert {:error, :invalid_token} = AuthTokens.session_resource(token)
  end

  test "verify_email_username rejects password reset tokens" do
    token = AuthTokens.create_password_reset_token("verify-user")

    assert {:error, :invalid_token} = AuthTokens.verify_email_username(token)
  end

  test "password_reset_username decodes password reset tokens" do
    token = AuthTokens.create_password_reset_token("reset-user")

    assert {:ok, "reset-user"} = AuthTokens.password_reset_username(token)
  end

  test "password_reset_username rejects session tokens" do
    token = AuthTokens.create_session_token("reset-user", false)

    assert {:error, :invalid_token} = AuthTokens.password_reset_username(token)
  end
end
