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
    {:ok, _, _socket} = socket(StreamshoreWeb.UserSocket)
                 |> subscribe_and_join(StreamshoreWeb.RoomChannel, "room:name", %{user: "user", anon: true})
    list = conn
           |> get(Routes.room_path(conn, :index))
           |> json_response(200)
    assert Enum.at(list, 0)["users"] == 1
  end

  test "creating a room", %{conn: conn} do
    conn = post(conn, Routes.room_path(conn, :create), %{name: "Name", description: "", privacy: 0, owner: "user"})
    assert json_response(conn, 200) == %{"route" => "name", "success" => true}
  end

  test "getting a room from database", %{conn: conn} do
    conn = post(conn, Routes.room_path(conn, :create), %{name: "Name", description: "", privacy: 0, owner: "user"})
    assert json_response(conn, 200) == %{"route" => "name", "success" => true}
    list = conn
           |> get(Routes.room_path(conn, :index))
           |> json_response(200)
    assert Enum.at(list, 0)["name"] == "Name"
    assert Enum.at(list, 0)["owner"] == "user"
    assert Enum.at(list, 0)["route"] == "name"
    assert Enum.at(list, 0)["privacy"] == 0
    assert Enum.at(list, 0)["thumbnail"] == nil
    assert Enum.at(list, 0)["users"] == 0
  end
end
