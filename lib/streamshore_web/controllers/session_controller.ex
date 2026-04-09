defmodule StreamshoreWeb.SessionController do
  use StreamshoreWeb, :controller

  alias Streamshore.Accounts
  alias Streamshore.Guardian
  alias StreamshoreWeb.ApiResponses

  def create(conn, params) do
    case map_size(params) do
      0 ->
        case Accounts.create_anonymous_session() do
          {:ok, session} ->
            ApiResponses.ok(conn, session)
        end

      _ ->
        case Accounts.create_authenticated_session(params["id"], params["password"]) do
          {:ok, session} ->
            ApiResponses.ok(conn, session)

          {:error, :invalid_credentials} ->
            ApiResponses.error(conn, :unauthorized, "Invalid credentials")

          {:error, :email_not_verified} ->
            ApiResponses.error(conn, :forbidden, "Email address not verified")
        end
    end
  end

  def delete(conn, _params) do
    Guardian.revoke(conn.assigns.current_token)
    ApiResponses.ok(conn)
  end
end
