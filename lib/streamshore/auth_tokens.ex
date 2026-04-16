defmodule Streamshore.AuthTokens do
  alias Streamshore.Guardian

  @session_purpose "session"
  @verify_email_purpose "verify_email"
  @password_reset_purpose "password_reset"

  def create_session_token(username, anonymous?) do
    encode_token(username, %{anon: anonymous?, purpose: @session_purpose})
  end

  def session_resource(token) do
    with {:ok, claims} <- decode_claims_for_purpose(token, @session_purpose),
         username when is_binary(username) <- claims["sub"],
         anonymous? when is_boolean(anonymous?) <- claims["anon"] do
      {:ok, %{user: username, anon: anonymous?}}
    else
      _ -> {:error, :invalid_token}
    end
  end

  def create_verify_email_token(username) do
    encode_token(username, %{anon: false, purpose: @verify_email_purpose})
  end

  def verify_email_username(token) do
    decode_username_for_purpose(token, @verify_email_purpose)
  end

  def create_password_reset_token(username) do
    encode_token(username, %{anon: false, purpose: @password_reset_purpose})
  end

  def password_reset_username(token) do
    decode_username_for_purpose(token, @password_reset_purpose)
  end

  defp encode_token(username, claims) do
    {:ok, token, _claims} = Guardian.encode_and_sign(username, claims)
    token
  end

  defp decode_username_for_purpose(token, purpose) do
    with {:ok, claims} <- decode_claims_for_purpose(token, purpose),
         username when is_binary(username) <- claims["sub"] do
      {:ok, username}
    else
      _ -> {:error, :invalid_token}
    end
  end

  defp decode_claims_for_purpose(token, purpose) do
    with {:ok, claims} <- Guardian.decode_and_verify(token),
         ^purpose <- claims["purpose"] do
      {:ok, claims}
    else
      _ -> {:error, :invalid_token}
    end
  end
end
