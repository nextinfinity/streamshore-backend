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
      {:ok, schema}->
        json(conn, %{success: true, username: username})

      {:error, changeset}->
        json(conn, %{success: false})
    end
  end

  def show(conn, _params) do
    # TODO: show user info
  end

  def update(conn, params) do
    # TODO: profile edit action
    username = params["username"]
    user = User |> Repo.get_by(username: username)
    password = params["password"]
    # Check to see if valid password

    password = Bcrypt.hash_pwd_salt(password)
    changeset = User.changeset(user, %{password: password})
    successful = Repo.update(changeset)
    case successful do
      {:ok, schema}->
        json(conn, %{success: true})

      {:error, changeset}->
        json(conn, %{success: false})
    end
  end

  def delete(conn, params) do
    # TODO: delete user
    username = params["username"]
    user = User |> Repo.get_by(username: username)
    successful = Repo.delete(user)
    case successful do
      {:ok, schema}->
        json(conn, %{success: true})

      {:error, changeset}->
        json(conn, %{success: false})
    end
  end

end
