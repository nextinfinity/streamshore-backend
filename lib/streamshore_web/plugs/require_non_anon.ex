defmodule StreamshoreWeb.Plugs.RequireNonAnon do
  @moduledoc false

  import Plug.Conn

  alias StreamshoreWeb.ApiResponses

  def init(opts), do: opts

  def call(%Plug.Conn{assigns: %{current_user: nil}} = conn, _opts) do
    conn
    |> ApiResponses.error(:unauthorized, conn.assigns[:auth_error] || "No valid token provided")
    |> halt()
  end

  def call(%Plug.Conn{assigns: %{current_anon: false}} = conn, _opts), do: conn

  def call(conn, _opts) do
    conn
    |> ApiResponses.error(:forbidden, "Insufficient permission")
    |> halt()
  end
end
