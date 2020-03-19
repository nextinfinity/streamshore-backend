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
    success = QueueManager.move_to_front(params["room_id"], params["id"])
    json(conn, %{success: success})
  end

  def delete(conn, _params) do
    # TODO: delete video
  end

end
