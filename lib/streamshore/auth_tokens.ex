defmodule Streamshore.AuthTokens do
  alias Streamshore.Guardian

  def create_token(user, anon, claims \\ %{}) do
    {:ok, token, _claims} = Guardian.encode_and_sign(user, Map.put(claims, :anon, anon))
    token
  end

  def decode_token_for_purpose(token, purpose) do
    with {:ok, claims} <- Guardian.decode_and_verify(token),
         ^purpose <- claims["purpose"],
         user when is_binary(user) <- claims["sub"] do
      {:ok, user}
    else
      _ -> {:error, :invalid_token}
    end
  end
end
