defmodule Streamshore.AccountEvents do
  alias Streamshore.Mailer

  def dispatch({:send_verification_email, user}) do
    Mailer.send_email(
      user.email,
      "Verify your email!",
      "https://streamshore.tv/verify?user=" <> user.username <> "&token=" <> user.verify_token
    )
  end

  def dispatch({:send_password_reset_email, user, token}) do
    Mailer.send_email(
      user.email,
      "Reset your password!",
      "https://streamshore.tv/reset?user=" <> user.username <> "&token=" <> token
    )
  end
end
