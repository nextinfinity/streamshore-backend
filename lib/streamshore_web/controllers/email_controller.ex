defmodule StreamshoreWeb.EmailController do
  use StreamshoreWeb, :controller

  alias Streamshore.Guardian

  def create(conn, params) do
    case Guardian.get_user_and_admin(Guardian.token_from_conn(conn)) do
      {:error, error} -> json(conn, %{error: error})
      {:ok, _user, _anon, admin} ->
        case admin do
          true ->
            send_email(params["to"], params["subject"], params["message"])
            json(conn, %{})
          false -> json(conn, %{error: "Insufficient permission"})
        end
    end
  end

  def send_email(to, subject, text) do
    SendGrid.Email.build()
    |> SendGrid.Email.add_to(to)
    |> SendGrid.Email.put_from("admin@streamshore.tv", "Streamshore")
    |> SendGrid.Email.put_subject("Streamshore | " <> subject)
    |> SendGrid.Email.put_text(text)
    |> SendGrid.Mail.send()
  end

end
