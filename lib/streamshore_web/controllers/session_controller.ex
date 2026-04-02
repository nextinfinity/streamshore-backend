defmodule StreamshoreWeb.SessionController do
  use StreamshoreWeb, :controller
  import Dictionary

  alias Streamshore.Accounts
  alias Streamshore.AuthTokens
  alias Streamshore.Guardian
  alias StreamshoreWeb.ApiResponses

  def create(conn, params) do
    if Enum.count(params) != 0 do
      user = Accounts.get_by_email_or_username(params["id"])

      if user && Pbkdf2.verify_pass(params["password"], user.password) do
        case user.verify_token do
          nil ->
            ApiResponses.ok(conn, %{
              token: AuthTokens.create_token(user.username, false),
              user: user.username,
              anon: false
            })

          _ ->
            ApiResponses.error(conn, :forbidden, "Email address not verified")
        end
      else
        ApiResponses.error(conn, :unauthorized, "Invalid credentials")
      end
    else
      username =
        String.capitalize(String.trim(random_adjective(), "\r")) <>
          String.capitalize(String.trim(random_adjective(), "\r")) <>
          String.capitalize(String.trim(random_animal(), "\r"))

      ApiResponses.ok(conn, %{token: AuthTokens.create_token(username, true), user: username, anon: true})
    end
  end

  def delete(conn, params) do
    Guardian.revoke(params["id"])
    ApiResponses.ok(conn)
  end
end
