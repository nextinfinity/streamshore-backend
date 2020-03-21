defmodule StreamshoreWeb.RoomController do
  use StreamshoreWeb, :controller
  alias Streamshore.Repo
  alias Streamshore.Room
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
      {:ok, schema}->
        json(conn, %{success: true, route: route})

      {:error, changeset}->
        json(conn, %{success: false})
    end
  end

  def update(_conn, _params) do
    # TODO: room edit action
  end

  def delete(_conn, _params) do
    # TODO: delete room
  end

end