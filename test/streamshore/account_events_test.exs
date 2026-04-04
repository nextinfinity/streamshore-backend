defmodule Streamshore.AccountEventsTest do
  use ExUnit.Case, async: false

  alias Streamshore.AccountEvents

  defmodule MailerSpy do
    @behaviour Streamshore.Mailer

    def send_email(to, subject, text) do
      send(self(), {:sent_email, to, subject, text})
      :ok
    end
  end

  setup do
    original_mailer = Application.get_env(:streamshore, :mailer)
    original_frontend_base_url = Application.get_env(:streamshore, :frontend_base_url)

    Application.put_env(:streamshore, :mailer, MailerSpy)

    on_exit(fn ->
      Application.put_env(:streamshore, :mailer, original_mailer)
      Application.put_env(:streamshore, :frontend_base_url, original_frontend_base_url)
    end)

    :ok
  end

  test "verification emails use configured frontend base url and encode params" do
    Application.put_env(:streamshore, :frontend_base_url, "https://stage.streamshore.tv/")

    user = %{email: "verify@test.com", username: "Test Account", verify_token: "abc+123"}

    assert :ok = AccountEvents.dispatch({:send_verification_email, user})

    assert_received {:sent_email, "verify@test.com", "Verify your email!",
                     "https://stage.streamshore.tv/verify?user=Test+Account&token=abc%2B123"}
  end

  test "password reset emails use configured frontend base url and encode params" do
    Application.put_env(:streamshore, :frontend_base_url, "https://dev.streamshore.tv")

    user = %{email: "reset@test.com", username: "Test Account"}

    assert :ok = AccountEvents.dispatch({:send_password_reset_email, user, "reset token"})

    assert_received {:sent_email, "reset@test.com", "Reset your password!",
                     "https://dev.streamshore.tv/reset?user=Test+Account&token=reset+token"}
  end
end
