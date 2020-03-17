defmodule StreamshoreWeb.RoomController do
  use StreamshoreWeb, :controller
  alias Streamshore.Repo
  alias Streamshore.Room
  import Ecto.Query

  def index(conn, _params) do
    query = from r in Room, select: %{title: r.name, owner: r.owner, route: r.route}
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
    params = Map.put(params, "route", route)
    inspect(params)
    %Streamshore.Room{}
    |> Room.changeset(params)
    |> Repo.insert()
    json(conn, %{success: true})
  end

  def update(_conn, _params) do
    # TODO: room edit action
  end

  def delete(_conn, _params) do
    # TODO: delete room
  end

end