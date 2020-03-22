defmodule StreamshoreWeb.UserController do
  import Ecto.Query, only: [from: 2]
  use StreamshoreWeb, :controller
  alias Streamshore.Repo
  alias Streamshore.User
<<<<<<< HEAD
  alias Streamshore.Friends
  
=======

>>>>>>> master
  def index(conn, _params) do
    users = Repo.all(User)
    render(conn, "index.html", users: users)
  end

  def convert_changeset_errors(changeset) do
    out =  Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    out
  end

  def create(conn, params) do
    username = params["username"]
    password = params["password"]
    valid_pass = User.valid_password(password)
    if !valid_pass do
      json(conn, %{success: false, errors: "password: password is invalid"})
    else 
      successful =
      %Streamshore.User{}
      |> User.changeset(params)
      |> Repo.insert()

<<<<<<< HEAD
      case successful do
        {:ok, schema}->
          json(conn, %{success: true, username: username})

        {:error, changeset}->
          errors = User.convert_changeset_errors(changeset)
          json(conn, %{success: false, errors: errors})
      end
=======
    case successful do
      {:ok, _schema}->
        json(conn, %{success: true, username: username})

      {:error, changeset}->
        errors = convert_changeset_errors(changeset)
        key = Enum.at(Map.keys(errors), 0)
        err = Atom.to_string(key) <> " " <> Enum.at(errors[key], 0)
        json(conn, %{success: false, error_msg: String.capitalize(err)})
>>>>>>> master
    end
  end

  def show(_conn, _params) do
    # TODO: show user info
  end

<<<<<<< HEAD
  def update(conn, params) do
    username = params["username"]
    user = User |> Repo.get_by(username: username)
    password = params["password"]
    valid_pass = User.valid_password(password)
    if !valid_pass do
      json(conn, %{success: false, error: "password: password is invalid"})
    else
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
  end

  def delete(conn, params) do
    username = params["username"]
    user = User |> Repo.get_by(username: username)
    successful = Repo.delete(user)
    case successful do
      {:ok, schema}->
        json(conn, %{success: true})
=======
  def update(_conn, _params) do
    # TODO: profile edit action
  end

  def delete(_conn, _params) do
    # TODO: delete user
  end
>>>>>>> master

      {:error, changeset}->
        json(conn, %{success: false})
    end
  end
end
