defmodule StreamshoreWeb.FriendController do
  import Ecto.Query, only: [from: 2]
  use StreamshoreWeb, :controller
  alias Streamshore.Repo
  alias Streamshore.User
  alias Streamshore.Friends

  def index(conn, params) do
    friender = params["user_id"]
    query = from f in Friends, where: f.friender == ^friender and f.accepted == 1, select: %{friendee: f.friendee, nickname: f.nickname}
    friends = Repo.all(query)
    query = from f in Friends, where: f.friender == ^friender and f.accepted == 0, select: %{friendee: f.friendee, nickname: f.nickname}
    requests = Repo.all(query)
    map = %{friends: friends, requests: requests}
    json(conn, map)
  end

  def create(conn, params) do
    friender = params["user_id"]
    friendee = params["friendee"]
    nickname = nil
    accepted = 0
    if User |> Repo.get_by(username: friendee) do 
      if !(Friends |> Repo.get_by(friender: friendee, friendee: friender)) do
        changeset = Friends.changeset(%Friends{}, %{friender: friendee, friendee: friender, nickname: nickname, accepted: accepted})
        successful = Repo.insert(changeset)

        case successful do
          {:ok, _schema}->
            json(conn, %{success: true})

          {:error, _changeset}->
            json(conn, %{success: false})
        end
      else
        json(conn, %{success: false, error: "Friend connection already exists"})
      end
    else 
      json(conn, %{success: false, error: "User does not exist"})
    end
  end

  def update(conn, params) do
    friender = params["user_id"]
    friendee = params["id"]
    if params["accepted"] do
      accepted = params["accepted"]
      if accepted == "1" do
        # change accepted to 1 for one user and insert the other user
        relation = Friends |> Repo.get_by(friender: friender, friendee: friendee)
        if relation do
          changeset = Friends.changeset(relation, params)
          _successful = Repo.update(changeset)
          changeset = Friends.changeset(%Friends{}, %{friender: friendee, friendee: friender, nickname: nil, accepted: accepted})
          successful = Repo.insert(changeset)
          case successful do
            {:ok, _schema}->
              json(conn, %{success: true})

            {:error, _changeset}->
              json(conn, %{success: false})
          end
        else
          json(conn, %{success: false})
        end
      else 
        # delete the input
        relation = Friends |> Repo.get_by(friender: friender, friendee: friendee)
        successful = Repo.delete(relation)
        case successful do
          {:ok, _schema}->
            json(conn, %{success: true})

          {:error, _changeset}->
            json(conn, %{success: false})
         end
      end
    else
      # update nickname
      relation = Friends |> Repo.get_by(friender: friender, friendee: friendee)
      if relation do
        changeset = Friends.changeset(relation, params)
        successful = Repo.update(changeset)
        case successful do
          {:ok, _schema}->
            json(conn, %{success: true})

          {:error, _changeset}->
            json(conn, %{success: false})
        end
      else
        json(conn, %{success: false})
      end
    end
  end

  def delete(conn, params) do
    friender = params["user_id"]
    friendee = params["id"]
    relation1 = Friends |> Repo.get_by(friender: friender, friendee: friendee)
    successful1 = Repo.delete(relation1)
    relation2 = Friends |> Repo.get_by(friender: friendee, friendee: friender)
    successful2 = Repo.delete(relation2)
    case successful1 && successful2 do
      {:ok, _schema}->
        json(conn, %{success: true})

      {:error, _changeset}->
        json(conn, %{success: false})
    end
  end
end