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
        {:ok, token, claims} = Guardian.encode_and_sign(user.username, %{anon: false, admin: false})
        json(conn, %{token: token, user: claims["sub"], anon: claims["anon"]})
      else
        json(conn, %{error: "Invalid credentials"})
      end
    else
      username = String.capitalize(String.trim(random_adjective(), "\r")) <>
                 String.capitalize(String.trim(random_adjective(), "\r")) <>
                 String.capitalize(String.trim(random_animal(), "\r"))
      {:ok, token, claims} = Guardian.encode_and_sign(username, %{anon: true, admin: false})
      json(conn, %{token: token, user: claims["sub"], anon: claims["anon"]})
    end
  end

  def delete(conn, params) do
    Guardian.revoke(params["id"])
    json(conn, %{})
  end

end

