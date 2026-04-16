defmodule StreamshoreWeb.Plugs.LoadAuth do
  @moduledoc false

  import Plug.Conn

  alias Streamshore.AuthTokens

  def init(opts), do: opts

  def call(conn, _opts) do
    case token_from_conn(conn) do
      nil ->
        assign_auth(conn, nil, nil, nil, "No valid token provided")

      token ->
        case AuthTokens.session_resource(token) do
          {:ok, %{user: user, anon: anon}} ->
            assign_auth(conn, user, anon, token, nil)

          {:error, _reason} ->
            assign_auth(conn, nil, nil, nil, "Invalid token")
        end
    end
  end

  defp assign_auth(conn, user, anon, token, error) do
    conn
    |> assign(:current_user, user)
    |> assign(:current_anon, anon)
    |> assign(:current_token, token)
    |> assign(:auth_error, error)
  end

  defp token_from_conn(conn) do
    case Enum.find(conn.req_headers, fn {key, _value} ->
           String.downcase(key) == "authorization"
         end) do
      {_, "Bearer " <> token} -> token
      _ -> nil
    end
  end
end
