defmodule Streamshore.AuthTest do
  use Streamshore.DataCase, async: false

  alias Streamshore.Accounts
  alias Streamshore.Auth
  alias Streamshore.AuthTokens
  alias Streamshore.Repo
  alias Streamshore.User

  setup do
    original_mailer_enabled = Application.get_env(:streamshore, :mailer_enabled)
    original_mailer_from_address = Application.get_env(:streamshore, :mailer_from_address)

    on_exit(fn ->
      Application.put_env(:streamshore, :mailer_enabled, original_mailer_enabled)
      Application.put_env(:streamshore, :mailer_from_address, original_mailer_from_address)
    end)

    :ok
  end

  test "log_in_with_password returns a session payload for a verified user" do
    Application.put_env(:streamshore, :mailer_enabled, true)
    Application.put_env(:streamshore, :mailer_from_address, "noreply@example.com")

    assert {:ok, _user, _events} =
             Accounts.create_user(%{
               "email" => "session@test.com",
               "username" => "session-user",
               "password" => "$Test123"
             })

    user = Repo.get_by!(User, username: "session-user")
    assert {:ok, _verified_user} = Auth.verify_email_from_token(user.verify_token)

    assert {:ok, session} = Auth.log_in_with_password("session-user", "$Test123")

    assert session.user == "session-user"
    assert session.anon == false
    assert is_binary(session.token)
  end

  test "log_in_with_password rejects invalid credentials" do
    assert {:error, :invalid_credentials} = Auth.log_in_with_password("missing-user", "$Test123")
  end

  test "log_in_with_password rejects unverified users" do
    Application.put_env(:streamshore, :mailer_enabled, true)
    Application.put_env(:streamshore, :mailer_from_address, "noreply@example.com")

    assert {:ok, _user, _events} =
             Accounts.create_user(%{
               "email" => "unverified@test.com",
               "username" => "unverified-user",
               "password" => "$Test123"
             })

    assert {:error, :email_not_verified} =
             Auth.log_in_with_password("unverified-user", "$Test123")
  end

  test "create_anonymous_session returns an anonymous session payload" do
    assert {:ok, session} = Auth.create_anonymous_session()

    assert session.user
    assert session.anon == true
    assert is_binary(session.token)
  end

  test "verify_email_from_token clears the stored verification token" do
    Application.put_env(:streamshore, :mailer_enabled, true)
    Application.put_env(:streamshore, :mailer_from_address, "noreply@example.com")

    assert {:ok, _user, _events} =
             Accounts.create_user(%{
               "email" => "verify@test.com",
               "username" => "verified-user",
               "password" => "$Test123"
             })

    user = Repo.get_by!(User, username: "verified-user")

    assert {:ok, verified_user} = Auth.verify_email_from_token(user.verify_token)
    assert verified_user.verify_token == nil
    assert Repo.get_by!(User, username: "verified-user").verify_token == nil
  end

  test "resend_verification returns ok for unverified user" do
    Application.put_env(:streamshore, :mailer_enabled, true)
    Application.put_env(:streamshore, :mailer_from_address, "noreply@example.com")

    assert {:ok, _user, _events} =
             Accounts.create_user(%{
               "email" => "verify@test.com",
               "username" => "verified-user",
               "password" => "$Test123"
             })

    original_token = Repo.get_by!(User, username: "verified-user").verify_token

    assert {:ok, resent_user, [{:send_verification_email, event_user}]} =
             Auth.resend_verification("verified-user")

    assert resent_user.verify_token != nil
    refute resent_user.verify_token == original_token
    assert Repo.get_by!(User, username: "verified-user").verify_token == resent_user.verify_token
    assert event_user.username == resent_user.username
  end

  test "resend_verification invalidates the previous verification token" do
    Application.put_env(:streamshore, :mailer_enabled, true)
    Application.put_env(:streamshore, :mailer_from_address, "noreply@example.com")

    assert {:ok, _user, _events} =
             Accounts.create_user(%{
               "email" => "rotated-verify@test.com",
               "username" => "rotated-verify-user",
               "password" => "$Test123"
             })

    original_token = Repo.get_by!(User, username: "rotated-verify-user").verify_token

    assert {:ok, resent_user, [{:send_verification_email, _event_user}]} =
             Auth.resend_verification("rotated-verify-user")

    refute resent_user.verify_token == original_token
    assert {:error, :invalid_token} = Auth.verify_email_from_token(original_token)
    assert {:ok, verified_user} = Auth.verify_email_from_token(resent_user.verify_token)
    assert verified_user.verify_token == nil
  end

  test "resend_verification returns already_verified for verified user" do
    assert {:ok, _user, _events} =
             Accounts.create_user(%{
               "email" => "verified@test.com",
               "username" => "already-verified",
               "password" => "$Test123"
             })

    assert {:error, :already_verified} = Auth.resend_verification("already-verified")
  end

  test "request_password_reset saves a reset token for the user" do
    assert {:ok, _user, _events} =
             Accounts.create_user(%{
               "email" => "reset@test.com",
               "username" => "reset-user",
               "password" => "$Test123"
             })

    assert {:ok, updated_user, [{:send_password_reset_email, event_user, token}]} =
             Auth.request_password_reset("reset@test.com")

    assert updated_user.reset_token != nil
    assert Repo.get_by!(User, username: "reset-user").reset_token != nil
    assert event_user.username == updated_user.username
    assert token == updated_user.reset_token
  end

  test "request_password_reset accepts a username identifier" do
    assert {:ok, _user, _events} =
             Accounts.create_user(%{
               "email" => "username-reset@test.com",
               "username" => "username-reset-user",
               "password" => "$Test123"
             })

    assert {:ok, updated_user, [{:send_password_reset_email, _event_user, token}]} =
             Auth.request_password_reset("username-reset-user")

    assert updated_user.username == "username-reset-user"
    assert token == updated_user.reset_token
  end

  test "update_password hashes the new password and clears reset token" do
    assert {:ok, _user, _events} =
             Accounts.create_user(%{
               "email" => "password@test.com",
               "username" => "password-user",
               "password" => "$Test123"
             })

    assert {:ok, _user, _events} = Auth.request_password_reset("password@test.com")
    assert {:ok, updated_user} = Auth.update_password("password-user", "$NewPass123")

    assert updated_user.password != "$NewPass123"
    assert updated_user.reset_token == nil
    assert Repo.get_by!(User, username: "password-user").reset_token == nil
  end

  test "reset_password_from_token updates the password with a stored reset token" do
    assert {:ok, _user, _events} =
             Accounts.create_user(%{
               "email" => "reset-flow@test.com",
               "username" => "reset-flow-user",
               "password" => "$Test123"
             })

    assert {:ok, _user, [{:send_password_reset_email, _event_user, token}]} =
             Auth.request_password_reset("reset-flow@test.com")

    assert {:ok, updated_user} = Auth.reset_password_from_token(token, "$NewPass123")

    assert updated_user.password != "$NewPass123"
    assert updated_user.reset_token == nil
    assert Repo.get_by!(User, username: "reset-flow-user").reset_token == nil
  end

  test "reset_password_from_token rejects an invalid stored reset token" do
    assert {:ok, _user, _events} =
             Accounts.create_user(%{
               "email" => "invalid-reset@test.com",
               "username" => "invalid-reset-user",
               "password" => "$Test123"
             })

    assert {:ok, _user, _events} = Auth.request_password_reset("invalid-reset@test.com")

    assert {:error, :invalid_token} =
             Auth.reset_password_from_token(
               AuthTokens.create_password_reset_token("invalid-reset-user"),
               "$NewPass123"
             )
  end

  test "reset_password_from_token consumes the stored reset token after use" do
    assert {:ok, _user, _events} =
             Accounts.create_user(%{
               "email" => "single-use-reset@test.com",
               "username" => "single-use-reset-user",
               "password" => "$Test123"
             })

    assert {:ok, _user, [{:send_password_reset_email, _event_user, token}]} =
             Auth.request_password_reset("single-use-reset@test.com")

    assert {:ok, _updated_user} = Auth.reset_password_from_token(token, "$NewPass123")
    assert {:error, :invalid_token} = Auth.reset_password_from_token(token, "$AnotherPass123")
  end
end
