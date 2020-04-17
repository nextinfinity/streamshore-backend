defmodule StreamshoreWeb.RoomChannelTest do
  use StreamshoreWeb.ChannelCase
  import Phoenix.ConnTest
  alias Plug.Conn
  alias Streamshore.Guardian

  setup do
    {:ok, token, _claims} = Guardian.encode_and_sign("anon", %{anon: false, admin: false})

    conn = build_conn()
            |> Conn.put_req_header("authorization", "Bearer " <> token)
    post(conn, "/api/rooms", %{name: "Lobby", motd: "", privacy: 0})

    {:ok, _, socket} =
      socket(StreamshoreWeb.UserSocket, "anon", %{user: "anon", anon: false})
      |> subscribe_and_join(StreamshoreWeb.RoomChannel, "room:lobby")

    {:ok, socket: socket}
  end

  test "user list" do
    {:ok, _, _socket} = socket(StreamshoreWeb.UserSocket, "test", %{user: "test", anon: true})
    |> subscribe_and_join(StreamshoreWeb.RoomChannel, "room:lobby")

    assert_push "presence_state", %{"anon" => %{}}
    assert_push "presence_diff", %{:joins => %{"test" => %{}}}
  end

  test "ping replies with status ok", %{socket: socket} do
    ref = push socket, "ping", %{"msg" => "hello world"}
    assert_reply ref, :ok, %{"msg" => "hello world"}
  end

  test "chat", %{socket: socket} do
    push socket, "chat", %{"msg" => "hello world"}
    assert_broadcast "chat", %{"msg" => "hello world"}
  end

  test "chat travel time", %{socket: socket} do
    push socket, "chat", %{"msg" => "hello world"}
    assert_broadcast "chat", %{"msg" => "hello world"}, 1000
  end

  test "chat user", %{socket: socket} do
    push socket, "chat", %{"msg" => "hello world"}
    assert_broadcast "chat", %{:user => "anon"}
  end

  test "chat time", %{socket: socket} do
    push socket, "chat", %{"msg" => "hello world"}
    _time = Timex.to_unix(Timex.now())
    assert_broadcast "chat", %{:time => _time}
  end

  test "broadcasts are pushed to the client", %{socket: socket} do
    broadcast_from! socket, "broadcast", %{"msg" => "hello world"}
    assert_push "broadcast", %{"msg" => "hello world"}
  end
end
