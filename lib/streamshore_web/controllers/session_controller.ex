defmodule StreamshoreWeb.SessionController do
  use StreamshoreWeb, :controller
  import Dictionary

  alias Streamshore.Guardian
  alias Streamshore.Repo
  alias Streamshore.User

  def create(conn, params) do
    if (Enum.count(params) != 0) do
      user = case Repo.get_by(User, email: params["id"]) do
        nil -> Repo.get_by(User, username: params["id"])
        user -> user
      end
      if user && Bcrypt.verify_pass(params["password"], user.password) do
        case user.verify_token do
          nil -> json(conn, %{token: create_token(user.username, false), user: user.username, anon: false})
          _ -> json(conn, %{error: "Email address not verified"})
        end

      else
        json(conn, %{error: "Invalid credentials"})
      end
    else
      username = String.capitalize(String.trim(random_adjective(), "\r")) <>
                 String.capitalize(String.trim(random_adjective(), "\r")) <>
                 String.capitalize(String.trim(random_animal(), "\r"))
      json(conn, %{token: create_token(username, true), user: username, anon: true})
    end
  end

  def delete(conn, params) do
    Guardian.revoke(params["id"])
    json(conn, %{})
  end

  def create_token(user, anon) do
    {:ok, token, _claims} = Guardian.encode_and_sign(user, %{anon: anon})
    token
  end

end

