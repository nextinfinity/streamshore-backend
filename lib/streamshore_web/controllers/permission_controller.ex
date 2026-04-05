defmodule StreamshoreWeb.PermissionController do
  use StreamshoreWeb, :controller

  alias Streamshore.Guardian
  alias Streamshore.PermissionLevel
  alias Streamshore.Rooms
  alias StreamshoreWeb.ApiResponses

  def index(conn, params) do
    room = params["room_id"]
    perms = Rooms.list_permissions(room)
    ApiResponses.ok(conn, perms)
  end

  def show(conn, params) do
    perm = Rooms.get_permission(params["room_id"], params["id"])
    ApiResponses.ok(conn, perm)
  end

  def update(conn, params) do
    room = params["room_id"]
    user = params["id"]
    perm = params["permission"]

    case Guardian.get_user_and_permission(Guardian.token_from_conn(conn), params["room_id"]) do
      {:error, error} ->
        ApiResponses.error(conn, :unauthorized, error)

      {:ok, _user, _anon, permission} ->
        if permission > perm && permission >= PermissionLevel.manager() do
          case Rooms.update_permission(room, user, perm) do
            {:ok, _schema} ->
              StreamshoreWeb.Endpoint.broadcast("room:" <> room, "permission", %{
                user: user,
                permission: perm
              })

              ApiResponses.ok(conn)

            {:error, changeset} ->
              ApiResponses.changeset_error(conn, changeset)
          end
        else
          ApiResponses.error(conn, :forbidden, "Insufficient permission")
        end
    end
  end
end
