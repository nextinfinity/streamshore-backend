defmodule StreamshoreWeb.UserController do
  use StreamshoreWeb, :controller
  alias Streamshore.Repo
  alias Streamshore.User
  
  def index(conn, _params) do
    users = Repo.all(User)
    render(conn, "index.html", users: users)
  end

  def create(conn, params) do
    successful =
    %Streamshore.User{}
    |> User.changeset(params)
    |> Repo.insert()

    case successful do
      {:ok, schema}->
        json(conn, %{success: true}) # Need to return the username

      {:error, changeset}->
        json(conn, %{success: false})
    end
  end

  def update(conn, params) do
    # TODO: profile edit action
  end

  def delete(conn, params) do
    # TODO: delete user
  end

end
