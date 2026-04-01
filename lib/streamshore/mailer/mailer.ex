defmodule Streamshore.Mailer do
  @callback send_email(String.t(), String.t(), String.t()) :: any()

  def send_email(to, subject, text) do
    impl().send_email(to, subject, text)
  end

  def enabled? do
    Application.get_env(:streamshore, :mailer_enabled, false)
  end

  def from_address do
    Application.get_env(:streamshore, :mailer_from_address)
  end

  defp impl, do: Application.get_env(:streamshore, :mailer, Streamshore.Mailer.SendGrid)
end
