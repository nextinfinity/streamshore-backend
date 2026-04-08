defmodule Streamshore.Guardian do
  use Guardian, otp_app: :streamshore

  def subject_for_token(user, _claims) do
    sub = to_string(user)
    {:ok, sub}
  end

  def resource_from_claims(claims) do
    user = claims["sub"]
    anon = claims["anon"]
    resource = %{user: user, anon: anon}
    {:ok, resource}
  end

  def token_from_conn(conn) do
    case Enum.find(conn.req_headers, fn {key, _value} ->
           String.downcase(key) == "authorization"
         end) do
      {_, "Bearer " <> token} -> token
      _ -> nil
    end
  end
end
