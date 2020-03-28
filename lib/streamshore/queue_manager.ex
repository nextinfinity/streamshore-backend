defmodule Streamshore.QueueManager do
  @moduledoc false
  use GenServer

  alias Streamshore.Videos

  def start_link(default \\ []) do
    GenServer.start_link(__MODULE__, default)
  end

  def init(args) do
    schedule()
    {:ok, Enum.into(args, %{})}
  end

  def schedule, do: Process.send_after(self(), :timer, 1000)

  def add_to_queue(room, id, user) do
    room_data = Videos.get(room)
    room_data = if (!room_data) do
      %{queue: []}
    else
      room_data
    end
    data = HTTPoison.get! "https://www.googleapis.com/youtube/v3/videos?id=" <> id <> "&key=AIzaSyBWO0zsG8H5Uf4PTXMVPvTNNUxp__cTMO0&part=snippet,contentDetails"
    body = Enum.at(Poison.decode!(data.body)["items"], 0)
    if body do
      title = body["snippet"]["title"]
      channel = body["snippet"]["channelTitle"]
      thumbnail = body["snippet"]["thumbnails"]["high"]["url"]
      length = body["contentDetails"]["duration"]
      length = Timex.Duration.to_seconds(Timex.Duration.parse!(length))
      video = [%{id: id, submittedBy: user, title: title, channel: channel, thumbnail: thumbnail, length: length}]
      room_data = Map.put(room_data, :queue, room_data[:queue] ++ video)
      Videos.set(room, room_data)
      StreamshoreWeb.Endpoint.broadcast("room:" <> room, "queue", %{videos: room_data[:queue]})
      if !room_data[:playing] do
        play_next(room)
      end
      true
    else
      false
    end
  end

  def remove_from_queue(room, index) do
    room_data = Videos.get(room)
    {_video, queue} = List.pop_at(room_data[:queue], String.to_integer(index))
    room_data = Map.put(room_data, :queue, queue)
    Videos.set(room, room_data)
    StreamshoreWeb.Endpoint.broadcast("room:" <> room, "queue", %{videos: room_data[:queue]})
  end

  def move_to_front(room, index) do
    room_data = Videos.get(room)
    {video, queue} = List.pop_at(room_data[:queue], String.to_integer(index))
    video = [video]
    queue = video ++ queue
    room_data = Map.put(room_data, :queue, queue)
    Videos.set(room, room_data)
    StreamshoreWeb.Endpoint.broadcast("room:" <> room, "queue", %{videos: room_data[:queue]})
  end

  def play_next(room) do
    room_data = Videos.get(room)
    room_data = if (length(room_data[:queue]) > 0) do
      room_data = Videos.get(room)
      {next_video, queue} = List.pop_at(room_data[:queue], 0)
      next_video = Map.put(next_video, :start, get_seconds() + 1)
      room_data = Map.put(room_data, :playing, next_video)
      room_data = Map.put(room_data, :queue, queue)
      Videos.set(room, room_data)
      StreamshoreWeb.Endpoint.broadcast("room:" <> room, "queue", %{videos: room_data[:queue]})
      room_data
    else
      room_data = Videos.get(room)
      room_data = Map.put(room_data, :playing, nil)
      Videos.set(room, room_data)
      room_data
    end
    StreamshoreWeb.Endpoint.broadcast("room:" <> room, "video", %{video: room_data[:playing]})
  end

  def timer() do
    schedule()
    Enum.each(
      Videos.keys,
      fn room ->
        if Videos.get(room)[:playing] do
          runtime = get_runtime(room)
          if runtime >= Videos.get(room)[:playing][:length] do
            play_next(room)
          else
            StreamshoreWeb.Endpoint.broadcast("room:" <> room, "time", %{time: runtime})
          end
        end
      end
    )
  end

  def get_runtime(room) do
    get_seconds() - Videos.get(room)[:playing][:start]
  end

  def get_seconds() do
    System.monotonic_time(:millisecond) / 1000
  end

  def handle_info(:timer, state) do
    timer()
    {:noreply, state}
  end

end
