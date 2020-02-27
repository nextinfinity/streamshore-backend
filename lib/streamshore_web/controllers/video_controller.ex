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
    QueueManager.add_to_queue(params[:room_id], params[:url])
    json(conn, %{success: true})
  end

  def update(conn, _params) do
    # TODO: video edit action
  end

  def delete(conn, _params) do
    # TODO: delete video
  end

end
