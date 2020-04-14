defmodule StreamshoreWeb.UserController do
  use StreamshoreWeb, :controller

  alias Streamshore.Guardian
  alias Streamshore.Repo
  alias Streamshore.User
  alias Streamshore.Util
  import Ecto.Query

  def index(conn, _params) do
    case Guardian.get_user(Guardian.token_from_conn(conn)) do
      {:error, error} -> json(conn, %{error: error})
      {:ok, _user, _anon} ->
        # TODO: check if user is admin
        query = from u in User, select: %{username: u.username, email: u.email}
        users = Repo.all(query)
        json(conn, users)
    end

  end

  def create(conn, params) do
    password = params["password"]
    valid_pass = User.valid_password(password)
    if !valid_pass do
      json(conn, %{error: "password: password is invalid"})
    else
      successful =
      %Streamshore.User{}
      |> User.changeset(params)
      |> Repo.insert()

      case successful do
        {:ok, _schema}->
          json(conn, %{})

      {:error, changeset}->
        errors = Util.convert_changeset_errors(changeset)
        key = Enum.at(Map.keys(errors), 0)
        err = Atom.to_string(key) <> " " <> Enum.at(errors[key], 0)
        json(conn, %{error: String.capitalize(err)})
      end
    end
  end

  def show(conn, params) do
    user = Repo.one(from(u in User, where: [username: ^params["id"]], select: %{username: u.username, room: u.room}))
    user = Map.put(user, :online, user[:room] != nil)
    json(conn, user)
  end

  def update(conn, params) do
    case Guardian.get_user(Guardian.token_from_conn(conn)) do
      {:error, error} -> json(conn, %{error: error})
      {:ok, user, anon} ->
        username = params["id"]
        if user == username && !anon do
          user_entry = User |> Repo.get_by(username: username)
          password = params["password"]
          valid_pass = User.valid_password(password)
          if !valid_pass do
            json(conn, %{error: "password: password is invalid"})
          else
            changeset = User.changeset(user_entry, %{password: password})
            successful = Repo.update(changeset)
            case successful do
              {:ok, _schema}->
                json(conn, %{})

              {:error, _changeset}->
                # TODO: error msg
                json(conn, %{error: ""})
            end
          end
        else
          json(conn, %{error: "Insufficient permission"})
        end
    end
  end

  def delete(conn, params) do
    case Guardian.get_user(Guardian.token_from_conn(conn)) do
      {:error, error} -> json(conn, %{error: error})
      {:ok, user, anon} ->
        username = params["id"]
        if user == username && !anon do
          user_entry = User |> Repo.get_by(username: username)
          case Repo.delete(user_entry) do
            {:error, _changeset}->
              json(conn, %{error: "Unable to delete user"})
            {:ok, _schema}->
              json(conn, %{})
          end
        else
          json(conn, %{error: "Insufficient permission"})
        end
    end
  end

  def set_room(user, room) do
    case Repo.get_by(User, %{username: user}) do
      nil -> nil
      schema -> schema
                |> User.changeset(%{room: room})
                |> Repo.update()
    end
  end
end
