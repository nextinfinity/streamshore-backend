defmodule StreamshoreWeb.FavoriteController do
  use StreamshoreWeb, :controller

  alias Streamshore.Accounts
  alias StreamshoreWeb.ApiResponses
  alias StreamshoreWeb.Presence

  plug StreamshoreWeb.Plugs.RequireAuth
  plug StreamshoreWeb.Plugs.RequireNonAnon

  def index(conn, _params) do
    conn.assigns.current_user
    |> Accounts.list_favorite_rooms()
    |> with_user_counts()
    |> then(&ApiResponses.ok(conn, &1))
  end

  def show(conn, params) do
    favorite = Accounts.favorite?(conn.assigns.current_user, params["id"])
    ApiResponses.ok(conn, favorite)
  end

  def create(conn, params) do
    case Accounts.create_favorite(conn.assigns.current_user, params["room"]) do
      {:ok, _schema} ->
        ApiResponses.ok(conn)

      {:error, :room_not_found} ->
        ApiResponses.error(conn, :not_found, "Room does not exist")

      {:error, changeset} ->
        ApiResponses.changeset_error(conn, changeset)
    end
  end

  def delete(conn, params) do
    case Accounts.delete_favorite(conn.assigns.current_user, params["id"]) do
      {:ok, _schema} ->
        ApiResponses.ok(conn)

      {:error, :not_found} ->
        ApiResponses.error(conn, :not_found, "Favorite does not exist")

      {:error, changeset} ->
        ApiResponses.changeset_error(conn, changeset)
    end
  end

  defp with_user_counts(rooms) do
    Enum.map(rooms, fn room ->
      Map.put(room, :users, Enum.count(Presence.list("room:" <> room[:route])))
    end)
  end
end
