defmodule Streamshore.Guardian do
  use Guardian, otp_app: :streamshore

  def subject_for_token(user, _claims) do
    sub = to_string(user)
    {:ok, sub}
  end

#  def subject_for_token(_, _) do
#    {:error, :reason_for_error}
#  end

  def resource_from_claims(claims) do
    user = claims["sub"]
    anon = claims["anon"]
    resource = %{user: user, anon: anon}
    {:ok,  resource}
  end

  def token_from_conn(conn) do
    {_, "Bearer " <> token} = Enum.find(conn.req_headers, fn {key, value} -> key == "authorization" end)
    token
  end

#  def resource_from_claims(_claims) do
#    {:error, :reason_for_error}
#  end
end
