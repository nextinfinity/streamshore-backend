defmodule StreamshoreWeb.RoomController do
  use StreamshoreWeb, :controller

  def index(conn, _params) do
    # TODO: list
  end

  def show(conn, _params) do
    json(conn, %{video: "https://d2zihajmogu5jn.cloudfront.net/bipbop-advanced/bipbop_16x9_variant.m3u8"})
    # TODO: show room info
  end

  def create(conn, _params) do
    %Streamshore.Room{}
    |> Repo.insert()
    json(conn, %{success: true})
  end

  def update(conn, _params) do
    # TODO: room edit action
  end

  def delete(conn, _params) do
    # TODO: delete room
  end

end