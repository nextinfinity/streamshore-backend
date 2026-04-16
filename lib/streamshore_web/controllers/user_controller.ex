defmodule StreamshoreWeb.UserController do
  use StreamshoreWeb, :controller

  alias Streamshore.Accounts
  alias StreamshoreWeb.ApiResponses

  plug StreamshoreWeb.Plugs.RequireAuth
  plug StreamshoreWeb.Plugs.RequireNonAnon when action in [:index]
  plug StreamshoreWeb.Plugs.RequireAdmin when action in [:index]

  def index(conn, _params) do
    ApiResponses.ok(conn, Accounts.list_users())
  end

  def show(conn, params) do
    case Accounts.get_public_user(params["id"]) do
      nil ->
        ApiResponses.error(conn, :not_found, "User not found")

      user ->
        ApiResponses.ok(conn, Map.put(user, :online, user[:room] != nil))
    end
  end
end
