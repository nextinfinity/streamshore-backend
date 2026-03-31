defmodule Streamshore.AuthTokens do
  alias Streamshore.Guardian

  def create_token(user, anon) do
    {:ok, token, _claims} = Guardian.encode_and_sign(user, %{anon: anon})
    token
  end
end
