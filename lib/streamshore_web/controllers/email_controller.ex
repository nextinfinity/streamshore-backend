defmodule StreamshoreWeb.EmailController do
  use StreamshoreWeb, :controller

  alias Streamshore.Guardian
  alias StreamshoreWeb.UserController

  def create(conn, params) do
    case Guardian.get_user_and_admin(Guardian.token_from_conn(conn)) do
      {:error, error} -> json(conn, %{error: error})
      {:ok, _user, _anon, admin} ->
        case admin do
          true ->
            UserController.emails() |> Enum.each(fn email -> send_email(email, params["subject"], params["message"]) end)
            json(conn, %{})
          false -> json(conn, %{error: "Insufficient permission"})
        end
    end
  end

  def send_email(to, subject, text) do
    if System.get_env("EMAIL_KEY") do
      SendGrid.Email.build()
      |> SendGrid.Email.add_to(to)
      |> SendGrid.Email.put_from("admin@streamshore.tv", "Streamshore")
      |> SendGrid.Email.put_subject("Streamshore | " <> subject)
      |> SendGrid.Email.put_text(text)
      |> SendGrid.Mail.send()
    end
  end

end
