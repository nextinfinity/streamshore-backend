defmodule StreamshoreWeb.VideoController do
  use StreamshoreWeb, :controller

  alias Streamshore.Videos
  alias Streamshore.QueueManager

  def index(conn, params) do
    json(conn, Videos.get(params[:room_id]))
  end

  def show(conn, params) do
    json(conn, Videos.get(params[:room_id][:id]))
  end

  def create(conn, params) do
    success = QueueManager.add_to_queue(params["room_id"], params["id"], params["user"])
    json(conn, %{success: success})
  end

  def update(conn, params) do
    QueueManager.move_to_front(params["room_id"], params["id"])
    json(conn, %{success: true})
  end

  def delete(conn, params) do
    QueueManager.remove_from_queue(params["room_id"], params["id"])
    json(conn, %{success: true})
  end

end
