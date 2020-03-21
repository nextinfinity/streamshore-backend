defmodule StreamshoreWeb.UserController do
  use StreamshoreWeb, :controller
  alias Streamshore.Repo
  alias Streamshore.User

  def index(conn, _params) do
    users = Repo.all(User)
    render(conn, "index.html", users: users)
  end

  def create(conn, params) do
    username = params["username"]
    successful =
    %Streamshore.User{}
    |> User.changeset(params)
    |> Repo.insert()

    case successful do
      {:ok, _schema}->
        json(conn, %{success: true, username: username})

      {:error, _changeset}->
        json(conn, %{success: false})
    end
  end

  def show(_conn, _params) do
    # TODO: show user info
  end

  def update(_conn, _params) do
    # TODO: profile edit action
  end

  def delete(_conn, _params) do
    # TODO: delete user
  end

end
