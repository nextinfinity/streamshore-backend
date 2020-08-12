defmodule StreamshoreWeb.FriendController do
  import Ecto.Query, only: [from: 2]
  use StreamshoreWeb, :controller

  alias Streamshore.Friends
  alias Streamshore.Guardian
  alias Streamshore.Repo
  alias Streamshore.User

  def index(conn, params) do
    friender = params["user_id"]

    query =
      from f in Friends,
        where: f.friender == ^friender and f.accepted == 1,
        select: %{friendee: f.friendee, nickname: f.nickname}

    friends = Repo.all(query)

    query =
      from f in Friends,
        where: f.friender == ^friender and f.accepted == 0,
        select: %{friendee: f.friendee, nickname: f.nickname}

    requests = Repo.all(query)
    map = %{friends: friends, requests: requests}
    json(conn, map)
  end

  def create(conn, params) do
    case Guardian.get_user(Guardian.token_from_conn(conn)) do
      {:error, error} ->
        json(conn, %{error: error})

      {:ok, _user, anon} ->
        case anon do
          false ->
            friender = params["user_id"]
            friendee = params["friendee"]
            nickname = nil
            accepted = 0

            if User |> Repo.get_by(username: friendee) do
              if Friends |> Repo.get_by(friender: friendee, friendee: friender) ||
                   Friends |> Repo.get_by(friender: friender, friendee: friendee) do
                json(conn, %{error: "Friend connection already exists"})
              else
                changeset =
                  Friends.changeset(%Friends{}, %{
                    friender: friendee,
                    friendee: friender,
                    nickname: nickname,
                    accepted: accepted
                  })

                successful = Repo.insert(changeset)

                case successful do
                  {:ok, _schema} ->
                    json(conn, %{})

                  {:error, _changeset} ->
                    json(conn, %{error: "Unable to create friend request in database"})
                end
              end
            else
              json(conn, %{error: "User does not exist"})
            end

          true ->
            json(conn, %{error: "You must be logged in to add a friend"})
        end
    end
  end

  def update(conn, params) do
    friender = params["user_id"]
    friendee = params["id"]
    relation = Friends |> Repo.get_by(friender: friender, friendee: friendee)
    if !relation do
      json(conn, %{error: "Friendship not found"})
    else
      if params["accepted"] do
        if params["accepted"] == "1" do
          # change accepted to 1 for one user and insert the other user+
          changeset = Friends.changeset(relation, params)
          _successful = Repo.update(changeset)

          changeset =
            Friends.changeset(%Friends{}, %{
              friender: friendee,
              friendee: friender,
              nickname: nil,
              accepted: 1
            })

          successful = Repo.insert(changeset)

          case successful do
            {:ok, _schema} ->
              json(conn, %{})

            {:error, _changeset} ->
              json(conn, %{error: "Unable to create friendship in database"})
          end
        else
          # delete the input
          successful = Repo.delete(relation)

          case successful do
            {:ok, _schema} ->
              json(conn, %{})

            {:error, _changeset} ->
              json(conn, %{error: "Unable to delete friendship from database"})
          end
        end
      else
        # update nickname
        changeset = Friends.changeset(relation, params)
        successful = Repo.update(changeset)

        case successful do
          {:ok, _schema} ->
            json(conn, %{})

          {:error, _changeset} ->
            json(conn, %{error: "Unable to update friendship in database"})
        end
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
      {:ok, _schema} ->
        json(conn, %{})

      {:error, _changeset} ->
        json(conn, %{error: "Unable to delete friendship from database"})
    end
  end
end
