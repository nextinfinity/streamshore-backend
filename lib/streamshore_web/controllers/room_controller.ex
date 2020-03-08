defmodule StreamshoreWeb.RoomController do
  use StreamshoreWeb, :controller
  alias Streamshore.Repo
  alias Streamshore.Room

  def index(_conn, _params) do
    # TODO: list
  end

  def show(conn, _params) do
    json(conn, %{video: "https://d2zihajmogu5jn.cloudfront.net/bipbop-advanced/bipbop_16x9_variant.m3u8"})
    # TODO: show room info
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