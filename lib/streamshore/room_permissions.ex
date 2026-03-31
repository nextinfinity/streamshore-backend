defmodule Streamshore.RoomPermissions do
  import Ecto.Query

  alias Streamshore.Permission
  alias Streamshore.PermissionLevel
  alias Streamshore.Repo

  def list(room) do
    query =
      from p in Permission,
        where: [room: ^room],
        select: %{user: p.username, permission: p.permission}

    Repo.all(query)
  end

  def get_perm(room, user) do
    case Repo.get_by(Permission, room: room, username: user) do
      nil -> PermissionLevel.user()
      perm -> perm.permission
    end
  end

  def update_perm(room, user, perm) do
    case Repo.get_by(Permission, room: room, username: user) do
      nil -> %Permission{room: room, username: user}
      permission -> permission
    end
    |> Permission.changeset(%{permission: perm})
    |> Repo.insert_or_update()
  end
end
