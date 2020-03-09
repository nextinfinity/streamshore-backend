defmodule StreamshoreWeb.SessionController do
  use StreamshoreWeb, :controller
  alias Streamshore.Repo
  import Dictionary

  def show(_conn, _params) do
    # TODO: show session info
  end

  @spec create(Plug.Conn.t(), any) :: Plug.Conn.t()
  def create(conn, params) do
    if (Enum.count(params) != 0) do
      # TODO: create session (login)
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

  def process_login(conn, params) do
    if is_nil(do_login(params["email"], params["password"])) do
      conn
      |> put_flash(:redir, params["redir"])
      |> put_flash(:error, "Login failed") |> redirect(to: "/users/login") |> halt
    else
      conn = put_session(conn, :user, params["email"])
      conn
        |> put_flash(:info, "Thanks for logging in!")
        |> redirect(to: params["redir"] || "/")
    end
  end

  def do_login(email, password) do
    user = Repo.get_by(User, [email: email, password: password])
    if user do
      if Comeonin.Bcrypt.checkpw(password, User["password"]) do
        user
      else
        nil
      end
    else
      nil
    end
  end

  def delete(_conn, _params) do
    # TODO: delete session (logout)
  end

end

