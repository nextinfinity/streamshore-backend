defmodule StreamshoreWeb.VerifyEmailController do
  use StreamshoreWeb, :controller

  alias Streamshore.Accounts
  alias Streamshore.Events
  alias StreamshoreWeb.ApiResponses

  def resend_email_verification(conn, params) do
    case Accounts.resend_verification_email(params["identifier"]) do
      {:ok, _schema, events} ->
        Events.dispatch_all(events)
        ApiResponses.accepted(conn)

      {:error, _} ->
        # Also send "accepted" for an error to prevent account enumeration from "doesn't exist" or "already verified"
        ApiResponses.accepted(conn)
    end
  end

  def verify_email(conn, params) do
    case Accounts.submit_email_verification(params["token"]) do
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
end
