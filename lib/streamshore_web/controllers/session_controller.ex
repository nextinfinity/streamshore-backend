defmodule StreamshoreWeb.SessionController do
  use StreamshoreWeb, :controller
  import Dictionary

  alias Streamshore.Guardian
  alias Streamshore.Repo
  alias Streamshore.User

  def create(conn, params) do
    if (Enum.count(params) != 0) do
      user = Repo.get_by(User, email: params["email"])
      if user && Bcrypt.verify_pass(params["password"], user.password) do
        {:ok, token, claims} = Guardian.encode_and_sign(user.username, %{anon: false, admin: false})
        json(conn, %{token: token, user: claims["sub"], anon: claims["anon"]})
      else
        json(conn, %{})
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
    json(conn, %{success: true})
  end

end

