defmodule Streamshore.QueueManager do
  @moduledoc false
  use GenServer

  alias Streamshore.Videos

  def start_link(default \\ []) do
    GenServer.start_link(__MODULE__, default)
  end

  def init(args) do
    schedule()
    { :ok, Enum.into(args, %{}) }
  end

  def schedule, do: Process.send_after(self(), :timer, 1000)

  def add_to_queue(room, id, user) do
    room_data = Videos.get(room)
    IO.inspect(room_data)
    room_data = if (!room_data) do
      %{queue: []}
    else
      room_data
    end
    IO.inspect(room_data)
    video = [%{id: id, submittedBy: user}]
    room_data = Map.put(room_data, :queue, room_data[:queue] ++ video)
    IO.inspect(room_data)
    Videos.set(room, room_data)
    StreamshoreWeb.Endpoint.broadcast("room:" <> room, "queue", %{videos: room_data[:queue]})
  end

  def remove_from_queue(room, index) do
    room_data = Videos.get(room)
  end

  def play_next(room) do
    room_data = Videos.get(room)
    Map.put(room_data, :playing, nil)
    if (length(room_data[:queue]) > 0) do
      {next_video, queue} = List.pop_at(room_data[:queue], 0)
      Map.put(room_data, :playing, next_video)
      Map.put(room_data, :queue, queue)
      Videos.set(room, room_data)
      StreamshoreWeb.Endpoint.broadcast("room:" <> room, "queue", room_data[:queue])
    end
    StreamshoreWeb.Endpoint.broadcast("room:" <> room, "video", %{video: room_data[:playing]})
  end

  def timer() do
    schedule()
    current_time = get_seconds()
    Enum.each(Videos.keys, fn room ->
      if Videos.get(room)[:playing] do
        runtime = current_time - Videos.get(room)[:playing][:start]
        if runtime >= Videos.get(room)[:playing][:length] do
          play_next(room)
        else
          StreamshoreWeb.Endpoint.broadcast("room:room", "time", %{time: runtime})
        end
      end
    end)
  end

  def get_seconds() do
    :os.system_time(:second)
  end

  def handle_info(:timer, state) do
    timer()
    {:noreply, state}
  end

end
