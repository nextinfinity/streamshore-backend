defmodule StreamshoreWeb.UserController do
  use StreamshoreWeb, :controller
  alias Streamshore.Repo
  alias Streamshore.User
  alias Streamshore.Util
  import Ecto.Query

  def index(conn, _params) do
    users = Repo.all(User)
    render(conn, "index.html", users: users)
  end

  def create(conn, params) do
    username = params["username"]
    password = params["password"]
    valid_pass = User.valid_password(password)
    if !valid_pass do
      json(conn, %{success: false, error: "password: password is invalid"})
    else
      successful =
      %Streamshore.User{}
      |> User.changeset(params)
      |> Repo.insert()

      case successful do
        {:ok, _schema}->
          json(conn, %{success: true, username: username})

      {:error, changeset}->
        errors = Util.convert_changeset_errors(changeset)
        key = Enum.at(Map.keys(errors), 0)
        err = Atom.to_string(key) <> " " <> Enum.at(errors[key], 0)
        json(conn, %{success: false, error_msg: String.capitalize(err)})
      end
    end
  end

  def show(conn, params) do
    user = Repo.one(from(u in User, where: [username: ^params["id"]], select: %{username: u.username, room: u.room}))
    user = Map.put(user, :online, user[:room] != nil)
    json(conn, user)
  end

  def update(conn, params) do
    username = params["id"]
    user = User |> Repo.get_by(username: username)
    password = params["password"]
    valid_pass = User.valid_password(password)
    if !valid_pass do
      json(conn, %{success: false, error: "password: password is invalid"})
    else
      changeset = User.changeset(user, %{password: password})
      successful = Repo.update(changeset)
      case successful do
        {:ok, schema}->
          json(conn, %{success: true})

        {:error, changeset}->
          json(conn, %{success: false})
      end
    end
  end

  def delete(conn, params) do
    username = params["username"]
    user = User |> Repo.get_by(username: username)
    successful = Repo.delete(user)
    case successful do
      {:ok, schema}->
        json(conn, %{success: true})
    end
  end
end
