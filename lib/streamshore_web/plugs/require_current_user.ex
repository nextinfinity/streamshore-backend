defmodule StreamshoreWeb.Plugs.RequireCurrentUser do
  @moduledoc false

  import Plug.Conn

  alias StreamshoreWeb.ApiResponses

  def init(opts), do: opts

  def call(%Plug.Conn{assigns: %{current_user: nil}} = conn, _opts) do
    conn
    |> ApiResponses.error(:unauthorized, conn.assigns[:auth_error] || "No valid token provided")
    |> halt()
  end

  def call(conn, opts) do
    param = Keyword.get(opts, :param, "user_id")

    if conn.assigns.current_user == conn.params[param] do
      conn
    else
      conn
      |> ApiResponses.error(:forbidden, "Insufficient permission")
      |> halt()
    end
  end
end
