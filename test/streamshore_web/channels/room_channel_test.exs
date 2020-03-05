defmodule StreamshoreWeb.RoomChannelTest do
  use StreamshoreWeb.ChannelCase

  setup do
    {:ok, _, socket} =
      socket(StreamshoreWeb.UserSocket, "user_id", %{some: :assign})
      |> subscribe_and_join(StreamshoreWeb.RoomChannel, "room_chat:lobby")

    {:ok, socket: socket}
  end

  test "ping replies with status ok", %{socket: socket} do
    ref = push socket, "ping", %{"hello" => "there"}
    assert_reply ref, :ok, %{"hello" => "there"}
  end

  #test "shout broadcasts to room_chat:lobby", %{socket: socket} do
  #  push socket, "chat", %{"hello" => "all"}
  #  assert_broadcast "shout", %{"hello" => "all"}
  #end

  test "broadcasts are pushed to the client", %{socket: socket} do
    broadcast_from! socket, "broadcast", %{"some" => "data"}
    assert_push "broadcast", %{"some" => "data"}
  end
end
