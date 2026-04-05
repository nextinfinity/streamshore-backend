defmodule StreamshoreWeb.FavoriteController do
  use StreamshoreWeb, :controller

  alias Streamshore.Accounts
  alias Streamshore.Guardian
  alias StreamshoreWeb.ApiResponses
  alias StreamshoreWeb.Presence

  def index(conn, params) do
    params["user_id"]
    |> Accounts.list_favorite_rooms()
    |> with_user_counts()
    |> then(&ApiResponses.ok(conn, &1))
  end

  def show(conn, params) do
    favorite = Accounts.favorite?(params["user_id"], params["id"])
    ApiResponses.ok(conn, favorite)
  end

  def create(conn, params) do
    case Guardian.get_user(Guardian.token_from_conn(conn)) do
      {:error, error} ->
        ApiResponses.error(conn, :unauthorized, error)

      {:ok, current_user, anon} ->
        room = params["room"]
        user = params["user_id"]

        cond do
          anon ->
            ApiResponses.error(
              conn,
              :forbidden,
              "You must be logged in to add a room to favorites"
            )

          current_user != user ->
            ApiResponses.error(conn, :forbidden, "Insufficient permission")

          true ->
            case Accounts.create_favorite(user, room) do
              {:ok, _schema} ->
                ApiResponses.ok(conn)

              {:error, :room_not_found} ->
                ApiResponses.error(conn, :not_found, "Room does not exist")

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

      {:ok, current_user, anon} ->
        room = params["id"]
        user = params["user_id"]

        cond do
          anon ->
            ApiResponses.error(
              conn,
              :forbidden,
              "You must be logged in to remove a room from favorites"
            )

          current_user != user ->
            ApiResponses.error(conn, :forbidden, "Insufficient permission")

          true ->
            case Accounts.delete_favorite(user, room) do
              {:error, :not_found} ->
                ApiResponses.error(conn, :not_found, "Favorite does not exist")

              {:ok, _schema} ->
                ApiResponses.ok(conn)

              {:error, changeset} ->
                ApiResponses.changeset_error(conn, changeset)
            end
        end
    end
  end

  defp with_user_counts(rooms) do
    Enum.map(rooms, fn room ->
      Map.put(room, :users, Enum.count(Presence.list("room:" <> room[:route])))
    end)
  end
end
