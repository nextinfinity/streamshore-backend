defmodule StreamshoreWeb.UserController do
  import Ecto.Query, only: [from: 2]
  use StreamshoreWeb, :controller
  alias Streamshore.Repo
  alias Streamshore.User
  alias Streamshore.Friends
  
  def index(conn, _params) do
    users = Repo.all(User)
    render(conn, "index.html", users: users)
  end

  def create(conn, params) do
    username = params["username"]
    password = params["password"]
    valid_pass = User.valid_password(password)
    if !valid_pass do
      json(conn, %{success: false, errors: "password: invalid password"})
    else 
      successful =
      %Streamshore.User{}
      |> User.changeset(params)
      |> Repo.insert()

      case successful do
        {:ok, schema}->
          json(conn, %{success: true, username: username})

        {:error, changeset}->
          errors = User.convert_changeset_errors(changeset)
          json(conn, %{success: false, errors: errors})
      end
    end
  end

  def show(conn, _params) do
    # TODO: show user info
  end

  def update(conn, params) do
    username = params["username"]
    user = User |> Repo.get_by(username: username)
    password = params["password"]
    valid_pass = User.valid_password(password)
    if !valid_pass do
      json(conn, %{success: false, error: "Invalid password"})
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

      {:error, changeset}->
        json(conn, %{success: false})
    end
  end

  def add_friend(conn, params) do
    friendee = params["freindee"]
    if User |> Repo.get_by(username: friendee) do 
      successful =
      %Streamshore.Friends{}
      |> Friend.changeset(params)
      |> Repo.insert()

      case successful do
        {:ok, schema}->
          json(conn, %{success: true})

        {:error, changeset}->
          json(conn, %{success: false})
      end
    else 
      json(conn, %{success: false, error: "User does not exist"})
    end
  end

  def remove_friend(conn, params) do
    friend = params["friend"]
    friendee = params["friendee"]
    relation1 = Friends |> Repo.get_by(friend: friend, friendee: friendee)
    relation2 = Friends |> Repo.get_by(friend: friendee, friendee: friend)
    Repo.delete(relation1)
    Repo.delete(relation2)
  end 

  def get_friends(conn, params) do
    friend = params["friend"]
    query = from f in "friends", where: f.friend == type(^friend, :string), select: f.friendee
    Repo.all(query)
  end

  def set_nickname(conn, params) do

  end
end
