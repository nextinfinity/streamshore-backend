defmodule StreamshoreWeb.UserController do
  use StreamshoreWeb, :controller

  alias Streamshore.Guardian
  alias Streamshore.Repo
  alias Streamshore.User
  alias Streamshore.Util
  alias Streamshore.Permission
  alias Streamshore.Favorites
  alias Streamshore.Friends
  alias Streamshore.Playlist
  alias Streamshore.PlaylistVideo
  alias Streamshore.Room
  import Ecto.Query

  def index(conn, _params) do
    case Guardian.get_user_and_admin(Guardian.token_from_conn(conn)) do
      {:error, error} -> json(conn, %{error: error})
      {:ok, _user, _anon, admin} ->
        IO.puts admin
        if admin do
          query = from u in User, select: %{username: u.username, email: u.email}
          users = Repo.all(query)
          json(conn, users)
        else 
          json(conn, %{error: "Insufficient permission"})
        end
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
      {:ok, user, anon} ->
        username = params["id"]
        if user == username && !anon do
          query = from(f in Favorites, where: f.user == ^user)
          successful1 = Repo.delete_all(query)
          query = from(p in Permission, where: p.username == ^user)
          successful2 = Repo.delete_all(query)
          query = from r in Room, where: r.owner == ^user, select: %{name: r.name}
          list = Repo.all(query)
          rooms = list |> Enum.map(fn a-> a.name end)
          query = from(f in Favorites, where: f.room in ^rooms)
          successful7 = Repo.delete_all(query)
          query = from(r in Room, where: r.owner == ^user)
          successful3 = Repo.delete_all(query)
          query = from(f in Friends, where: f.friendee == ^user or f.friender == ^user)
          successful4 = Repo.delete_all(query)
          query = from(v in PlaylistVideo, where: v.owner == ^user)
          successful5 = Repo.delete_all(query)
          query = from(p in Playlist, where: p.owner == ^user)
          successful6 = Repo.delete_all(query)
          user_entry = User |> Repo.get_by(username: username)
          successful8 = Repo.delete(user_entry)
          case successful1 && successful2 && successful3 && successful4 && successful5 && successful6 && successful7 && successful8 do
            {:ok, _schema}->
              json(conn, %{})

            {:error, _changeset}->
              json(conn, %{error: "Unable to delete user"})
          end
        else
          json(conn, %{error: "Insufficient permission"})
        end

        {:error, error} -> json(conn, %{error: error})
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

  def get_admin(user) do
    query = from u in User, where: u.username == ^user, select: u.admin
    admin = Repo.one(query)
    if admin == 1 do
      true
    else
      false
    end
  end
end
