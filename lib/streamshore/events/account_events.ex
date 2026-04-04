defmodule Streamshore.AccountEvents do
  alias Streamshore.Mailer

  def dispatch({:send_verification_email, user}) do
    Mailer.send_email(
      user.email,
      "Verify your email!",
      frontend_url("/verify", user: user.username, token: user.verify_token)
    )
  end

  def dispatch({:send_password_reset_email, user, token}) do
    Mailer.send_email(
      user.email,
      "Reset your password!",
      frontend_url("/reset", user: user.username, token: token)
    )
  end

  defp frontend_url(path, params) do
    Application.fetch_env!(:streamshore, :frontend_base_url)
    |> String.trim_trailing("/")
    |> Kernel.<>(path <> "?" <> URI.encode_query(params))
  end
end
