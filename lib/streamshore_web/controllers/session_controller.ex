defmodule StreamshoreWeb.SessionController do
  use StreamshoreWeb, :controller
  import Dictionary

  def new(conn, _params) do
    # TODO: new session (precursor to create)
  end

  def show(conn, _params) do
    # TODO: show session info
  end

  def create(conn, params) do
    if (Enum.count(params) != 0) do
      # # TODO: create session (login)
      # successful = Repo.get_by(User, [email: email, password: password])

      # case successful do
      #   {:ok, %Streamshore.User{}} ->
      #     json(conn, %{success: true, username: username})

      #   {:error, changeset} ->
      #     json(conn, %{success: false})
      # end
    end
    # TODO: user account logic (create session)
    # TODO: check for existing anon users
    username = String.capitalize(String.trim(random_adjective(), "\r")) <>
               String.capitalize(String.trim(random_adjective(), "\r")) <>
               String.capitalize(String.trim(random_animal(), "\r"))
    json(conn, %{name: username})
  end

  def delete(conn, _params) do
    # TODO: delete session (logout)
  end

end
