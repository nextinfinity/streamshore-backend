defmodule StreamshoreWeb.Plugs.RequireAdmin do
  @moduledoc false

  import Plug.Conn

  alias Streamshore.Accounts
  alias StreamshoreWeb.ApiResponses

  def init(opts), do: opts

  def call(%Plug.Conn{assigns: %{current_user: nil}} = conn, _opts) do
    conn
    |> ApiResponses.error(:unauthorized, conn.assigns[:auth_error] || "No valid token provided")
    |> halt()
  end

  def call(conn, _opts) do
    if Accounts.admin?(conn.assigns.current_user) do
      assign(conn, :current_admin, true)
    else
      conn
      |> ApiResponses.error(:forbidden, "Insufficient permission")
      |> halt()
    end
  end
end
