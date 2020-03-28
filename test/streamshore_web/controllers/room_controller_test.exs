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

end
