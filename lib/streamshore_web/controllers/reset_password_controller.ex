defmodule StreamshoreWeb.ResetPasswordController do
  use StreamshoreWeb, :controller

  alias Streamshore.Auth
  alias Streamshore.Events
  alias StreamshoreWeb.ApiResponses

  def request_password_reset(conn, params) do
    case Auth.request_password_reset(params["identifier"]) do
      {:ok, _schema, events} ->
        Events.dispatch_all(events)
        ApiResponses.accepted(conn)

      {:error, :not_found} ->
        # Also send "accepted" for an error to prevent account enumeration from "doesn't exist"
        ApiResponses.accepted(conn)

      {:error, changeset} ->
        ApiResponses.changeset_error(conn, changeset)
    end
  end

  def reset_password(conn, params) do
    case Auth.reset_password_from_token(params["token"], params["password"]) do
      {:ok, _schema} ->
        ApiResponses.ok(conn)

      {:error, :not_found} ->
        ApiResponses.error(conn, :not_found, "User not found")

      {:error, :invalid_token} ->
        ApiResponses.error(conn, :unauthorized, "Invalid token")

      {:error, changeset} ->
        ApiResponses.changeset_error(conn, changeset)
    end
  end
end
