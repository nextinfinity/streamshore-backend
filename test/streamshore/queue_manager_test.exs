defmodule Streamshore.QueueManagerTest do
  use Streamshore.DataCase

  alias Streamshore.QueueManager
  alias Streamshore.Repo
  alias Streamshore.Room
  alias Streamshore.Videos
  alias StreamshoreWeb.Presence

  defp create_room(attrs) do
    unique = System.unique_integer([:positive])

    params =
      Map.merge(
        %{
          name: "Queue Room #{unique}",
          motd: "",
          owner: "owner",
          privacy: 0,
          route: "queue-room-#{unique}"
        },
        attrs
      )

    %Room{}
    |> Room.changeset(params)
    |> Repo.insert!()
  end

  defp rewind_playing!(room, seconds) do
    room_data = Videos.get(room)
    playing = Map.update!(room_data[:playing], :start, &(&1 - seconds))
    Videos.set(room, Map.put(room_data, :playing, playing))
  end

  defp track_presence(room, user) do
    Presence.track(self(), "room:" <> room, user, %{
      anon: false,
      permission: 0,
      online_at: "now"
    })
  end

  setup do
    room = create_room(%{}).route
    on_exit(fn -> Videos.delete(room) end)
    {:ok, room: room}
  end

  test "tick advances to the next queued video without waiting on wall clock", %{room: room} do
    assert :ok = QueueManager.add_to_queue(room, "_-k6ppRkpcM", "user")
    assert :ok = QueueManager.add_to_queue(room, "VlbtLvZqMsI", "user")

    rewind_playing!(room, 10)
    QueueManager.tick()

    assert Videos.get(room)[:playing][:id] == "VlbtLvZqMsI"
  end

  test "vote_skip records votes when the threshold is not met" do
    room = create_room(%{vote_threshold: 101, route: "vote-track", name: "Vote Track"}).route
    on_exit(fn -> Videos.delete(room) end)

    assert :ok = QueueManager.add_to_queue(room, "_-k6ppRkpcM", "user")
    assert :ok = QueueManager.add_to_queue(room, "VlbtLvZqMsI", "user")
    assert {:ok, _} = track_presence(room, "user")

    QueueManager.vote_skip(room, "user")

    assert Videos.get(room)[:playing][:id] == "_-k6ppRkpcM"
    assert Videos.get(room)[:playing][:votes] == ["user"]
  end

  test "vote_skip advances playback when the threshold is met" do
    room = create_room(%{vote_threshold: 50, route: "vote-skip", name: "Vote Skip"}).route
    on_exit(fn -> Videos.delete(room) end)

    assert :ok = QueueManager.add_to_queue(room, "_-k6ppRkpcM", "user")
    assert :ok = QueueManager.add_to_queue(room, "VlbtLvZqMsI", "user")
    assert {:ok, _} = track_presence(room, "user")

    QueueManager.vote_skip(room, "user")

    assert Videos.get(room)[:playing][:id] == "VlbtLvZqMsI"
  end
end
