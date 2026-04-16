defmodule StreamshoreWeb.AccountController do
  use StreamshoreWeb, :controller

  alias Streamshore.Accounts
  alias Streamshore.Auth
  alias Streamshore.Events
  alias StreamshoreWeb.ApiResponses

  plug StreamshoreWeb.Plugs.RequireAuth when action in [:update_password, :delete]
  plug StreamshoreWeb.Plugs.RequireNonAnon when action in [:update_password, :delete]

  def create(conn, params) do
    case Accounts.create_user(params) do
      {:ok, _user, events} ->
        Events.dispatch_all(events)
        ApiResponses.ok(conn)

      {:error, changeset} ->
        ApiResponses.changeset_error(conn, changeset)
    end
  end

  def update_password(conn, params) do
    case Auth.update_password(conn.assigns.current_user, params["password"]) do
      {:ok, _schema} ->
        ApiResponses.ok(conn)

      {:error, :not_found} ->
        ApiResponses.error(conn, :not_found, "User not found")

      {:error, changeset} ->
        ApiResponses.changeset_error(conn, changeset)
    end
  end

  def delete(conn, _params) do
    case Accounts.delete_user(conn.assigns.current_user) do
      {:ok, _schema, events} ->
        Events.dispatch_all(events)
        ApiResponses.ok(conn)

      {:error, :not_found} ->
        ApiResponses.error(conn, :not_found, "User not found")

      {:error, changeset} ->
        ApiResponses.changeset_error(conn, changeset)
    end
  end
end
