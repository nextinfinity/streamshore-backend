defmodule Streamshore.Mailer.SendGrid do
  @behaviour Streamshore.Mailer

  def send_email(to, subject, text) do
    if Streamshore.Mailer.enabled?() do
      SendGrid.Email.build()
      |> SendGrid.Email.add_to(to)
      |> SendGrid.Email.put_from(Streamshore.Mailer.from_address(), "Streamshore")
      |> SendGrid.Email.put_subject("Streamshore | " <> subject)
      |> SendGrid.Email.put_text(text)
      |> SendGrid.Mail.send()
    end
  end
end
