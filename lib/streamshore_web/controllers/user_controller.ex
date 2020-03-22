defmodule StreamshoreWeb.UserController do
  use StreamshoreWeb, :controller
  alias Streamshore.Repo
  alias Streamshore.User
  
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
    successful =
    %Streamshore.User{}
    |> User.changeset(params)
    |> Repo.insert()

    case successful do
      {:ok, _schema}->
        json(conn, %{success: true, username: username})

      {:error, changeset}->
        errors = convert_changeset_errors(changeset)
        key = Enum.at(Map.keys(errors), 0)
        err = Atom.to_string(key) <> " " <> Enum.at(errors[key], 0)
        json(conn, %{success: false, error_msg: String.capitalize(err)})
    end
  end

  def show(_conn, _params) do
    # TODO: show user info
  end

  def update(conn, params) do
    id = params["id"]
    user = User |> Repo.get_by(id: id)
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
    end
  end
end
