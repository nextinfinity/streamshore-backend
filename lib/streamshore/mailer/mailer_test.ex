defmodule Streamshore.Mailer.Test do
  @behaviour Streamshore.Mailer

  def send_email(_to, _subject, _text), do: :ok
end
