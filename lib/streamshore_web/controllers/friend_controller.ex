defmodule StreamshoreWeb.FriendController do
  use StreamshoreWeb, :controller

  alias Streamshore.Accounts
  alias StreamshoreWeb.ApiResponses

  plug StreamshoreWeb.Plugs.RequireAuth
  plug StreamshoreWeb.Plugs.RequireNonAnon

  def index(conn, _params) do
    conn.assigns.current_user
    |> Accounts.list_friendships()
    |> then(&ApiResponses.ok(conn, &1))
  end

  def create(conn, params) do
    case Accounts.create_friend_request(conn.assigns.current_user, params["friendee"]) do
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

  def update(conn, params) do
    case Accounts.update_friendship(conn.assigns.current_user, params["id"], params) do
      {:ok, _schema} ->
        ApiResponses.ok(conn)

      {:error, :not_found} ->
        ApiResponses.error(conn, :not_found, "Friendship not found")

      {:error, changeset} ->
        ApiResponses.changeset_error(conn, changeset)
    end
  end

  def delete(conn, params) do
    case Accounts.delete_friendship(conn.assigns.current_user, params["id"]) do
      :ok ->
        ApiResponses.ok(conn)

      {:error, changeset} ->
        ApiResponses.changeset_error(conn, changeset)
    end
  end
end
