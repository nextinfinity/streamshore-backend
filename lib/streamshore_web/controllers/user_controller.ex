defmodule StreamshoreWeb.UserController do
  use StreamshoreWeb, :controller
  import Dictionary

  def get_anonymous_name() do
    # TODO: check for existing anon users

    String.capitalize(String.trim(random_adjective(), "\r")) <>
    String.capitalize(String.trim(random_adjective(), "\r")) <>
    String.capitalize(String.trim(random_animal(), "\r"))
  end

  def get_anon(conn, _params) do
    # TODO: user account logic
    username = get_anonymous_name()
    json(conn, %{name: username})
  end
end
