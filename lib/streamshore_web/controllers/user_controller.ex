defmodule StreamshoreWeb.UserController do
  use StreamshoreWeb, :controller

  alias Streamshore.Accounts
  alias Streamshore.Events
  alias StreamshoreWeb.ApiResponses

  plug StreamshoreWeb.Plugs.RequireAuth when action in [:index, :show, :update, :delete]
  plug StreamshoreWeb.Plugs.RequireNonAnon when action in [:index, :update, :delete]
  plug StreamshoreWeb.Plugs.RequireAdmin when action in [:index]
  plug StreamshoreWeb.Plugs.RequireCurrentUser, [param: "id"] when action in [:delete]

  def index(conn, _params) do
    ApiResponses.ok(conn, Accounts.list_users())
  end

  def create(conn, params) do
    case Accounts.create_user(params) do
      {:ok, _user, events} ->
        Events.dispatch_all(events)
        ApiResponses.ok(conn)

      {:error, changeset} ->
        ApiResponses.changeset_error(conn, changeset)
    end
  end

  def show(conn, params) do
    case Accounts.get_public_user(params["id"]) do
      nil ->
        ApiResponses.error(conn, :not_found, "User not found")

      user ->
        ApiResponses.ok(conn, Map.put(user, :online, user[:room] != nil))
    end
  end

  def update(conn, params) do
    cond do
      params["resend_verification"] ->
        handle_resend_verification(conn, params)

      params["reset_password"] ->
        handle_password_reset_request(conn, params)

      params["verify_token"] ->
        handle_verify_email(conn, params)

      params["password"] ->
        handle_password_update(conn, params)

      true ->
        ApiResponses.error(conn, :bad_request, "No valid options specified")
    end
  end

  def delete(conn, params) do
    username = params["id"]

    case Accounts.delete_user(username) do
      {:ok, _schema, events} ->
        Events.dispatch_all(events)
        ApiResponses.ok(conn)

      {:error, :not_found} ->
        ApiResponses.error(conn, :not_found, "User not found")

      {:error, changeset} ->
        ApiResponses.changeset_error(conn, changeset)
    end
  end

  defp handle_resend_verification(conn, params) do
    case Accounts.resend_verification_email(params["id"]) do
      {:ok, _schema, events} ->
        Events.dispatch_all(events)
        ApiResponses.ok(conn)

      {:error, :not_found} ->
        ApiResponses.error(conn, :not_found, "User not found")

      {:error, :already_verified} ->
        ApiResponses.error(conn, :conflict, "Email already verified")
    end
  end

  defp handle_password_reset_request(conn, params) do
    case Accounts.request_password_reset(params["id"]) do
      {:ok, _schema, events} ->
        Events.dispatch_all(events)
        ApiResponses.ok(conn)

      {:error, :not_found} ->
        ApiResponses.error(conn, :not_found, "User not found")

      {:error, changeset} ->
        ApiResponses.changeset_error(conn, changeset)
    end
  end

  defp handle_verify_email(conn, params) do
    case Accounts.verify_email(params["id"], params["verify_token"]) do
      {:ok, _schema} ->
        ApiResponses.ok(conn)

      {:error, :not_found} ->
        ApiResponses.error(conn, :not_found, "User not found")

      {:error, :already_verified} ->
        ApiResponses.error(conn, :conflict, "Email already verified")

      {:error, :invalid_token} ->
        ApiResponses.error(conn, :unauthorized, "Invalid token")

      {:error, changeset} ->
        ApiResponses.changeset_error(conn, changeset)
    end
  end

  defp handle_password_update(conn, params) do
    username = params["id"]

    result =
      if username == conn.assigns.current_user do
        Accounts.update_password(username, params["password"])
      else
        Accounts.reset_password(username, conn.assigns.current_token, params["password"])
      end

    case result do
      {:ok, _schema} ->
        ApiResponses.ok(conn)

      {:error, :not_found} ->
        ApiResponses.error(conn, :not_found, "User not found")

      {:error, :invalid_token} ->
        ApiResponses.error(conn, :forbidden, "Insufficient permission")

      {:error, changeset} ->
        ApiResponses.changeset_error(conn, changeset)
    end
  end
end
