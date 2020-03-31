defmodule RoomControllerTest do
  use StreamshoreWeb.ConnCase
  import Phoenix.ChannelTest

  test "room counts", %{conn: conn} do
    conn
    |> post(Routes.room_path(conn, :create), %{name: "Name", description: "", privacy: 0, owner: "user"})
    list = conn
           |> get(Routes.room_path(conn, :index))
           |> json_response(200)
    assert Enum.at(list, 0)["users"] == 0
    {:ok, _, socket} = socket(StreamshoreWeb.UserSocket)
                 |> subscribe_and_join(StreamshoreWeb.RoomChannel, "room:name", %{user: "user", anon: true})
    list = conn
           |> get(Routes.room_path(conn, :index))
           |> json_response(200)
    assert Enum.at(list, 0)["users"] == 1
    socket
    |> leave
  end


test "Room creation is successful", %{conn: conn} do

  #Creating Public Room
  conn = post(Routes.room_path(conn, :create), %{name: "Name", description: "", privacy: 0, owner: "user"})
  assert json_response(conn, 200) == %{"success" => true}

  #Creating Private Room
  conn = post(Routes.room_path(conn, :create), %{name: "Name", description: "", privacy: 1, owner: "user"})
  assert json_response(conn, 200) == %{"success" => true}

  end


end
