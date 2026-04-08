defmodule StreamshoreWeb.Plugs.LoadAuth do
  @moduledoc false

  import Plug.Conn

  alias Streamshore.Guardian

  def init(opts), do: opts

  def call(conn, _opts) do
    case Guardian.token_from_conn(conn) do
      nil ->
        assign_auth(conn, nil, nil, nil, "No valid token provided")

      token ->
        case Guardian.decode_and_verify(token) do
          {:ok, claims} ->
            assign_auth(conn, claims["sub"], claims["anon"], token, nil)

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
end
