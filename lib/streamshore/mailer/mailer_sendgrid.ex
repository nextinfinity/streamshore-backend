defmodule Streamshore.Mailer.SendGrid do
  @behaviour Streamshore.Mailer

  def send_email(to, subject, text) do
    if System.get_env("EMAIL_KEY") && System.get_env("EMAIL_ADDRESS") do
      SendGrid.Email.build()
      |> SendGrid.Email.add_to(to)
      |> SendGrid.Email.put_from(System.get_env("EMAIL_ADDRESS"), "Streamshore")
      |> SendGrid.Email.put_subject("Streamshore | " <> subject)
      |> SendGrid.Email.put_text(text)
      |> SendGrid.Mail.send()
    end
  end
end
