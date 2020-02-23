defmodule StreamshoreWeb.RoomController do
  use StreamshoreWeb, :controller

  def index(conn, _params) do
    # TODO: list
  end

  def edit(conn, _params) do
    # TODO: edit room (precursor to update)
  end

  def new(conn, _params) do
    # TODO: new room (precursor to create)
  end

  def show(conn, _params) do
    System.cmd("E:/Downloads/youtube-dl.exe", ["https://www.youtube.com/watch?v=rezzjJ4NtK0", "-o", "video.mp4"])
    Task.async(fn -> System.cmd("E:/Downloads/test/ffmpeg.exe", ["-i", System.cwd() <> "/video.mp4", "-f", "hls", System.cwd() <> "/video/index.m3u8"]) end)
    json(conn, %{video: System.cwd() <> "/video/index.m3u8"})
    # TODO: show room info
  end

  def create(conn, _params) do
    # TODO: create room
  end

  def update(conn, _params) do
    # TODO: room edit action
  end

  def delete(conn, _params) do
    # TODO: delete room
  end

end