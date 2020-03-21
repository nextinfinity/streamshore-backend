defmodule StreamshoreWeb.RoomController do
  use StreamshoreWeb, :controller
  alias StreamshoreWeb.PermissionController
  alias Streamshore.PermissionLevel
  alias Streamshore.Repo
  alias Streamshore.Room
  alias Streamshore.Util
  import Ecto.Query

  def index(conn, _params) do
    query = from r in Room, select: %{name: r.name, owner: r.owner, route: r.route, thumbnail: r.thumbnail}
    rooms = Repo.all(query)
    json(conn, rooms)
  end

  def show(conn, params) do
    room = Repo.get_by(Room, route: params["id"])
    success = if room do
      true
    else
      false
    end
    json(conn, %{success: success})
  end

  def create(conn, params) do
    route = String.downcase(String.replace(params["name"], " ", "-"))
    route = Regex.replace(~r/[^A-Za-z0-9\-]/, route, "")
    params = Map.put(params, "route", route)
    success = %Streamshore.Room{}
    |> Room.changeset(params)
    |> Repo.insert()

    case success do
      {:ok, _schema}->
        PermissionController.update_perm(params["route"], params["owner"], PermissionLevel.owner())
        json(conn, %{success: true, route: route})

      {:error, changeset}->
        errors = Util.convert_changeset_errors(changeset)
        key = Enum.at(Map.keys(errors), 0)
        err = Atom.to_string(key) <> " " <> Enum.at(errors[key], 0)
        json(conn, %{success: false, error_msg: String.capitalize(err)})
    end
  end

  def update(_conn, _params) do
    # TODO: room edit action
  end

  def delete(_conn, _params) do
    # TODO: delete room
  end

end