defmodule StreamshoreWeb.PermissionController do
  use StreamshoreWeb, :controller

  alias Streamshore.Guardian
  alias Streamshore.Permission
  alias Streamshore.PermissionLevel
  alias Streamshore.Repo
  alias Streamshore.Util
  import Ecto.Query

  def index(conn, params) do
    room = params["room_id"]
    query = from p in Permission, where: [room: ^room], select: %{user: p.username, permission: p.permission}
    perms = Repo.all(query)
    json(conn, perms)
  end

  def show(conn, params) do
    perm = get_perm(params["room_id"], params["id"])
    json(conn, perm)
  end

  def update(conn, params) do
    room = params["room_id"]
    user = params["id"]
    perm = params["permission"]
    case Guardian.get_user_and_permission(Guardian.token_from_conn(conn), params["room_id"]) do
      {:error, error} -> json(conn, %{error: error})
      {:ok, _user, _anon, permission} ->
        if permission > perm && permission >= PermissionLevel.manager() do
          case update_perm(room, user, perm) do
            {:ok, _schema}->
              StreamshoreWeb.Endpoint.broadcast("room:" <> room, "permission", %{user: user, permission: perm})
              json(conn, %{})

            {:error, changeset}->
              errors = Util.convert_changeset_errors(changeset)
              key = Enum.at(Map.keys(errors), 0)
              err = Atom.to_string(key) <> " " <> Enum.at(errors[key], 0)
              json(conn, %{error: String.capitalize(err)})
          end
        else
          json(conn, %{error: "Insufficient permission"})
        end
    end
  end

  def get_perm(room, user) do
    perm = Repo.get_by(Permission, %{room: room, username: user})
    if perm do
      perm.permission
    else
      PermissionLevel.user()
    end
  end

  def update_perm(room, user, perm) do
    case Repo.get_by(Permission, %{room: room, username: user}) do
      nil  -> %Permission{room: room, username: user}
      perm -> perm
    end
    |> Permission.changeset(%{permission: perm})
    |> Repo.insert_or_update
  end

end
