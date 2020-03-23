defmodule StreamshoreWeb.PermissionController do
  use StreamshoreWeb, :controller
  alias Streamshore.Repo
  alias Streamshore.Permission
  alias Streamshore.PermissionLevel
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
    success = update_perm(params["room_id"], params["id"], params["permission"])

    case success do
      {:ok, _schema}->
        json(conn, %{success: true})

      {:error, changeset}->
        errors = Util.convert_changeset_errors(changeset)
        key = Enum.at(Map.keys(errors), 0)
        err = Atom.to_string(key) <> " " <> Enum.at(errors[key], 0)
        json(conn, %{success: false, error_msg: String.capitalize(err)})
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
