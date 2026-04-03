defmodule StreamshoreWeb.FriendController do
  import Ecto.Query, only: [from: 2]
  use StreamshoreWeb, :controller

  alias Streamshore.Friends
  alias Streamshore.Guardian
  alias Streamshore.Repo
  alias Streamshore.User
  alias StreamshoreWeb.ApiResponses

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
    ApiResponses.ok(conn, map)
  end

  def create(conn, params) do
    case Guardian.get_user(Guardian.token_from_conn(conn)) do
      {:error, error} ->
        ApiResponses.error(conn, :unauthorized, error)

      {:ok, user, anon} ->
        friender = params["user_id"]
        friendee = params["friendee"]

        cond do
          anon ->
            ApiResponses.error(conn, :forbidden, "You must be logged in to add a friend")

          user != friender ->
            ApiResponses.error(conn, :forbidden, "Insufficient permission")

          !(User |> Repo.get_by(username: friendee)) ->
            ApiResponses.error(conn, :not_found, "User does not exist")

          Friends |> Repo.get_by(friender: friendee, friendee: friender) ||
              Friends |> Repo.get_by(friender: friender, friendee: friendee) ->
            ApiResponses.error(conn, :conflict, "Friend connection already exists")

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
                ApiResponses.ok(conn)

              {:error, changeset} ->
                ApiResponses.changeset_error(conn, changeset)
            end
        end
    end
  end

  def update(conn, params) do
    case Guardian.get_user(Guardian.token_from_conn(conn)) do
      {:error, error} ->
        ApiResponses.error(conn, :unauthorized, error)

      {:ok, user, anon} ->
        friender = params["user_id"]
        friendee = params["id"]
        relation = Friends |> Repo.get_by(friender: friender, friendee: friendee)

        cond do
          anon ->
            ApiResponses.error(conn, :forbidden, "You must be logged in to update a friendship")

          user != friender ->
            ApiResponses.error(conn, :forbidden, "Insufficient permission")

          !relation ->
            ApiResponses.error(conn, :not_found, "Friendship not found")

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
                  ApiResponses.ok(conn)

                {:error, changeset} ->
                  ApiResponses.changeset_error(conn, changeset)
              end
            else
              case Repo.delete(relation) do
                {:ok, _schema} ->
                  ApiResponses.ok(conn)

                {:error, changeset} ->
                  ApiResponses.changeset_error(conn, changeset)
              end
            end

          true ->
            case relation |> Friends.changeset(params) |> Repo.update() do
              {:ok, _schema} ->
                ApiResponses.ok(conn)

              {:error, changeset} ->
                ApiResponses.changeset_error(conn, changeset)
            end
        end
    end
  end

  def delete(conn, params) do
    case Guardian.get_user(Guardian.token_from_conn(conn)) do
      {:error, error} ->
        ApiResponses.error(conn, :unauthorized, error)

      {:ok, user, anon} ->
        friender = params["user_id"]
        friendee = params["id"]

        cond do
          anon ->
            ApiResponses.error(conn, :forbidden, "You must be logged in to delete a friendship")

          user != friender ->
            ApiResponses.error(conn, :forbidden, "Insufficient permission")

          true ->
            relation1 = Friends |> Repo.get_by(friender: friender, friendee: friendee)
            relation2 = Friends |> Repo.get_by(friender: friendee, friendee: friender)

            with {:ok, _schema} <- delete_if_present(relation1),
                 {:ok, _schema} <- delete_if_present(relation2) do
              ApiResponses.ok(conn)
            else
              {:error, changeset} ->
                ApiResponses.changeset_error(conn, changeset)
            end
        end
    end
  end

  defp delete_if_present(nil), do: {:ok, nil}
  defp delete_if_present(relation), do: Repo.delete(relation)
end
