defmodule StreamshoreWeb.Plugs.RequireAuth do
  @moduledoc false

  import Plug.Conn

  alias StreamshoreWeb.ApiResponses

  def init(opts), do: opts

  def call(%Plug.Conn{assigns: %{current_user: user}} = conn, _opts) when not is_nil(user), do: conn

  def call(conn, _opts) do
    conn
    |> ApiResponses.error(:unauthorized, conn.assigns[:auth_error] || "No valid token provided")
    |> halt()
  end
end
