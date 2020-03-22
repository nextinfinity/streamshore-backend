defmodule StreamshoreWeb.FriendController do
  use StreamshoreWeb, :controller
  alias Streamshore.Repo
  alias Streamshore.User
  alias Streamshore.Friends

  def index(_conn, _params) do
    # friend = params["friend"]
    # query = from f in "friends", where: f.friend == type(^friend, :string), select: f.friendee
    # Repo.all(query)
  end

  def create(conn, params) do
    friender = params["user_id"]
    friendee = params["friendee"]
    nickname = params["nickname"]
    if User |> Repo.get_by(username: friendee) do 
      changeset1 = Friends.changeset(%Friends{}, %{friender: friender, friendee: friendee, nickname: nickname})
      changeset2 = Friends.changeset(%Friends{}, %{friender: friendee, friendee: friender, nickname: nickname})
      successful1 = Repo.insert(changeset1)
      successful2 = Repo.insert(changeset2)

      case successful1 && successful2 do
        {:ok, schema}->
          json(conn, %{success: true})

        {:error, changeset}->
          json(conn, %{success: false})
      end
    else 
      json(conn, %{success: false, error: "User does not exist"})
    end
  end

  def delete(conn, params) do
    friender = params["id"]
    friendee = params["friendee"]
    relation1 = Friends |> Repo.get_by(friender: friender, friendee: friendee)
    successful1 = Repo.delete(relation1)
    relation2 = Friends |> Repo.get_by(friender: friendee, friendee: friender)
    successful2 = Repo.delete(relation2)
    case successful1 && successful2 do
      {:ok, schema}->
        json(conn, %{success: true})
    end
  end
end