defmodule StreamshoreWeb.FriendController do
  use StreamshoreWeb, :controller

  alias Streamshore.Accounts
  alias Streamshore.Guardian
  alias StreamshoreWeb.ApiResponses

  def index(conn, params) do
    params["user_id"]
    |> Accounts.list_friendships()
    |> then(&ApiResponses.ok(conn, &1))
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

          true ->
            case Accounts.create_friend_request(friender, friendee) do
              {:ok, _schema} ->
                ApiResponses.ok(conn)

              {:error, :user_not_found} ->
                ApiResponses.error(conn, :not_found, "User does not exist")

              {:error, :already_exists} ->
                ApiResponses.error(conn, :conflict, "Friend connection already exists")

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

        cond do
          anon ->
            ApiResponses.error(conn, :forbidden, "You must be logged in to update a friendship")

          user != friender ->
            ApiResponses.error(conn, :forbidden, "Insufficient permission")

          true ->
            case Accounts.update_friendship(friender, friendee, params) do
              {:ok, _schema} ->
                ApiResponses.ok(conn)

              {:error, :not_found} ->
                ApiResponses.error(conn, :not_found, "Friendship not found")

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
            case Accounts.delete_friendship(friender, friendee) do
              :ok ->
                ApiResponses.ok(conn)

              {:error, changeset} ->
                ApiResponses.changeset_error(conn, changeset)
            end
        end
    end
  end
end
