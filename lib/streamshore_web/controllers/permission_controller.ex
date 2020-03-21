defmodule StreamshoreWeb.PermissionController do
  use StreamshoreWeb, :controller
  alias Streamshore.Repo
  alias Streamshore.Permission
  import Ecto.Query

  def index(conn, params) do
    room = params["room_id"]
    query = from p in Permission, where: [room: room], select: %{user: p.username, permission: p.permission}
    perms = Repo.all(query)
    json(conn, perms)
  end

  def show(conn, _params) do
    # TODO: show permission info
  end

  def update(conn, _params) do
    # TODO: edit permission
  end

end
