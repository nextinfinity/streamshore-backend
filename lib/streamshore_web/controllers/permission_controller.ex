defmodule StreamshoreWeb.PermissionController do
  use StreamshoreWeb, :controller

  alias Streamshore.Guardian
  alias Streamshore.PermissionLevel
  alias Streamshore.RoomPermissions
  alias Streamshore.Util
  alias StreamshoreWeb.ApiResponses

  def index(conn, params) do
    room = params["room_id"]
    perms = RoomPermissions.list(room)
    ApiResponses.ok(conn, perms)
  end

  def show(conn, params) do
    perm = RoomPermissions.get_perm(params["room_id"], params["id"])
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
          case RoomPermissions.update_perm(room, user, perm) do
            {:ok, _schema} ->
              StreamshoreWeb.Endpoint.broadcast("room:" <> room, "permission", %{
                user: user,
                permission: perm
              })

              ApiResponses.ok(conn)

            {:error, changeset} ->
              errors = Util.convert_changeset_errors(changeset)
              key = Enum.at(Map.keys(errors), 0)
              err = Atom.to_string(key) <> " " <> Enum.at(errors[key], 0)
              ApiResponses.error(conn, :unprocessable_entity, String.capitalize(err))
          end
        else
          ApiResponses.error(conn, :forbidden, "Insufficient permission")
        end
    end
  end
end
