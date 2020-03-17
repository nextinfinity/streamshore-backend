defmodule StreamshoreWeb.RoomController do
  use StreamshoreWeb, :controller
  alias Streamshore.Repo
  alias Streamshore.Room

  def index(_conn, _params) do
    # TODO: list
  end

  def show(conn, params) do
    room = Repo.get_by(Room, roomName: params["id"])
    success = if room do
      true
    else
      false
    end
    json(conn, %{success: success})
  end

  def create(conn, params) do
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