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

      {:ok, user, anon} ->
        friender = params["user_id"]
        friendee = params["friendee"]

        cond do
          anon ->
            json(conn, %{error: "You must be logged in to add a friend"})

          user != friender ->
            json(conn, %{error: "Insufficient permission"})

          !(User |> Repo.get_by(username: friendee)) ->
            json(conn, %{error: "User does not exist"})

          Friends |> Repo.get_by(friender: friendee, friendee: friender) ||
              Friends |> Repo.get_by(friender: friender, friendee: friendee) ->
            json(conn, %{error: "Friend connection already exists"})

          true ->
            changeset =
              Friends.changeset(%Friends{}, %{
                friender: friendee,
                friendee: friender,
                nickname: nil,
                accepted: 0
              })

            case Repo.insert(changeset) do
              {:ok, _schema} ->
                json(conn, %{})

              {:error, _changeset} ->
                json(conn, %{error: "Unable to create friend request in database"})
            end
        end
    end
  end

  def update(conn, params) do
    case Guardian.get_user(Guardian.token_from_conn(conn)) do
      {:error, error} ->
        json(conn, %{error: error})

      {:ok, user, anon} ->
        friender = params["user_id"]
        friendee = params["id"]
        relation = Friends |> Repo.get_by(friender: friender, friendee: friendee)

        cond do
          anon ->
            json(conn, %{error: "You must be logged in to update a friendship"})

          user != friender ->
            json(conn, %{error: "Insufficient permission"})

          !relation ->
            json(conn, %{error: "Friendship not found"})

          params["accepted"] ->
            if params["accepted"] == "1" do
              _successful = relation |> Friends.changeset(params) |> Repo.update()

              changeset =
                Friends.changeset(%Friends{}, %{
                  friender: friendee,
                  friendee: friender,
                  nickname: nil,
                  accepted: 1
                })

              case Repo.insert(changeset) do
                {:ok, _schema} ->
                  json(conn, %{})

                {:error, _changeset} ->
                  json(conn, %{error: "Unable to create friendship in database"})
              end
            else
              case Repo.delete(relation) do
                {:ok, _schema} ->
                  json(conn, %{})

                {:error, _changeset} ->
                  json(conn, %{error: "Unable to delete friendship from database"})
              end
            end

          true ->
            case relation |> Friends.changeset(params) |> Repo.update() do
              {:ok, _schema} ->
                json(conn, %{})

              {:error, _changeset} ->
                json(conn, %{error: "Unable to update friendship in database"})
            end
        end
    end
  end

  def delete(conn, params) do
    case Guardian.get_user(Guardian.token_from_conn(conn)) do
      {:error, error} ->
        json(conn, %{error: error})

      {:ok, user, anon} ->
        friender = params["user_id"]
        friendee = params["id"]

        cond do
          anon ->
            json(conn, %{error: "You must be logged in to delete a friendship"})

          user != friender ->
            json(conn, %{error: "Insufficient permission"})

          true ->
            relation1 = Friends |> Repo.get_by(friender: friender, friendee: friendee)
            relation2 = Friends |> Repo.get_by(friender: friendee, friendee: friender)

            with {:ok, _schema} <- delete_if_present(relation1),
                 {:ok, _schema} <- delete_if_present(relation2) do
              json(conn, %{})
            else
              {:error, _changeset} ->
                json(conn, %{error: "Unable to delete friendship from database"})
            end
        end
    end
  end

  defp delete_if_present(nil), do: {:ok, nil}
  defp delete_if_present(relation), do: Repo.delete(relation)
end
