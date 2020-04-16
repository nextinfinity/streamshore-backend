defmodule RoomControllerTest do
  use StreamshoreWeb.ConnCase
  import Phoenix.ChannelTest

  alias Streamshore.Guardian

  setup %{conn: conn} do
    {:ok, token, _claims} = Guardian.encode_and_sign("user", %{anon: false, admin: false})

    conn = conn
           |> put_req_header("authorization", "Bearer " <> token)
    {:ok, conn: conn}
  end

  test "room counts", %{conn: conn} do
    conn
    |> post(Routes.room_path(conn, :create), %{name: "Count", iodescriptn: "", privacy: 0})
    list = conn
           |> get(Routes.room_path(conn, :index))
           |> json_response(200)
    assert Enum.at(list, 0)["users"] == 0
    {:ok, _, _socket} = socket(StreamshoreWeb.UserSocket, "user", %{user: "user", anon: true})
                 |> subscribe_and_join(StreamshoreWeb.RoomChannel, "room:count")
    list = conn
           |> get(Routes.room_path(conn, :index))
           |> json_response(200)
    assert Enum.at(list, 0)["users"] == 1
  end

  test "welcome message", %{conn: conn} do
    conn = post(conn, Routes.room_path(conn, :create), %{name: "MOTD", motd: "Lorem Ipsum", privacy: 0})
    assert json_response(conn, 200) == %{"route" => "motd"}
    {:ok, _, _socket} = socket(StreamshoreWeb.UserSocket, "user", %{user: "user", anon: true})
                        |> subscribe_and_join(StreamshoreWeb.RoomChannel, "room:motd")
    assert_push("motd", %{:message => "Lorem Ipsum"})
  end

  test "update welcome message", %{conn: conn} do
    conn = post(conn, Routes.room_path(conn, :create), %{name: "MOTD", motd: "Lorem Ipsum", privacy: 0})
    assert json_response(conn, 200) == %{"route" => "motd"}
    {:ok, _, _socket} = socket(StreamshoreWeb.UserSocket, "user", %{user: "user", anon: true})
                        |> subscribe_and_join(StreamshoreWeb.RoomChannel, "room:motd")
    assert_push("motd", %{:message => "Lorem Ipsum"})
    conn = put(conn, Routes.room_path(conn, :update, "MOTD"), %{motd: "Other Lorem Ipsum"})
    assert json_response(conn, 200) == %{}
    {:ok, _, _socket} = socket(StreamshoreWeb.UserSocket, "user", %{user: "user", anon: true})
                        |> subscribe_and_join(StreamshoreWeb.RoomChannel, "room:motd")
    assert_push("motd", %{:message => "Other Lorem Ipsum"})
  end

  test "creating a room", %{conn: conn} do
    conn = post(conn, Routes.room_path(conn, :create), %{name: "Create", motd: "", privacy: 0})
    assert json_response(conn, 200) == %{"route" => "create"}
  end

  test "get room from username", %{conn: conn} do
    #making room
    conn = post(conn, Routes.room_path(conn, :create), %{name: "Test", motd: "", privacy: 0})
    assert json_response(conn, 200) == %{"route" => "test"}
    # assert Enum.at(list, 0)["users"] == 0

    #user joins the room
    {:ok, _, _socket} = socket(StreamshoreWeb.UserSocket, "user", %{user: "user", anon: true})
                 |> subscribe_and_join(StreamshoreWeb.RoomChannel, "room:test")
    list = conn
           |> get(Routes.room_path(conn, :index))
           |> json_response(200)
    assert Enum.at(list, 0)["users"] == 1

    #another user joins
    {:ok, _, _socket} = socket(StreamshoreWeb.UserSocket, "friend", %{user: "friend", anon: true})
                 |> subscribe_and_join(StreamshoreWeb.RoomChannel, "room:test")
    list = conn
           |> get(Routes.room_path(conn, :index))
           |> json_response(200)
    assert Enum.at(list, 0)["users"] == 2

    #getting room from database to show it's the users'
    list = conn
           |> get(Routes.room_path(conn, :index))
           |> json_response(200)
    assert Enum.at(list, 0)["owner"] == "user"
    assert Enum.at(list, 0)["users"] == 2
  end


  test "getting a room from database", %{conn: conn} do
    conn = post(conn, Routes.room_path(conn, :create), %{name: "Name", motd: "", privacy: 0})
    assert json_response(conn, 200) == %{"route" => "name"}
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
