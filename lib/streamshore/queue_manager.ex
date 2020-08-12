defmodule Streamshore.QueueManager do
  @moduledoc false
  use GenServer

  alias StreamshoreWeb.Presence
  alias Streamshore.Repo
  alias Streamshore.Room
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
    room_data =
      case Videos.get(room) do
        nil -> %{queue: []}
        room_data -> room_data
      end

    queue_limit =
      case Repo.get_by(Room, %{route: room}) do
        nil -> 0
        schema -> schema.queue_limit
      end

    allow =
      if queue_limit > 0 do
        video_count = Enum.count(room_data[:queue], fn video -> video.submittedBy == user end)
        video_count < queue_limit
      else
        true
      end

    if allow do
      data =
        HTTPoison.get!(
          "https://www.googleapis.com/youtube/v3/videos?id=" <>
            id <> "&key=AIzaSyBWO0zsG8H5Uf4PTXMVPvTNNUxp__cTMO0&part=snippet,contentDetails"
        )

      body = Enum.at(Poison.decode!(data.body)["items"], 0)

      if body do
        title = body["snippet"]["title"]
        channel = body["snippet"]["channelTitle"]
        thumbnail = body["snippet"]["thumbnails"]["high"]["url"]
        length = body["contentDetails"]["duration"]
        length = Timex.Duration.to_seconds(Timex.Duration.parse!(length))

        video = [
          %{
            id: id,
            submittedBy: user,
            title: title,
            channel: channel,
            thumbnail: thumbnail,
            length: length
          }
        ]

        room_data = Map.put(room_data, :queue, room_data[:queue] ++ video)
        Videos.set(room, room_data)
        StreamshoreWeb.Endpoint.broadcast("room:" <> room, "queue", %{videos: room_data[:queue]})

        if !room_data[:playing] do
          play_next(room)
        end

        :ok
      else
        {:error, "Unable to retrieve video information."}
      end
    else
      {:error, "You already have the maximum allowed amount of videos in the queue."}
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

    room_data =
      if length(room_data[:queue]) > 0 do
        room_data = Videos.get(room)
        {next_video, queue} = List.pop_at(room_data[:queue], 0)
        next_video = Map.put(next_video, :start, get_seconds() + 1)
        next_video = Map.put(next_video, :votes, [])
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

    thumbnail =
      case room_data[:playing] do
        nil -> nil
        video -> video[:thumbnail]
      end

    case Repo.get_by(Room, %{route: room}) do
      nil ->
        nil

      schema ->
        schema
        |> Room.changeset(%{thumbnail: thumbnail})
        |> Repo.update()
    end
  end

  def vote_skip(room, user) do
    room_data = Videos.get(room)
    playing = room_data[:playing]
    room_entry = Repo.get_by(Room, %{route: room})

    if room_entry.vote_enable == 1 do
      if playing do
        user_count = Enum.count(Presence.list("room:" <> room))
        votes = MapSet.new(playing[:votes]) |> MapSet.put(user)
        threshold = room_entry.vote_threshold

        if MapSet.size(votes) > threshold / 100 * user_count do
          play_next(room)
        else
          playing = Map.put(playing, :votes, MapSet.to_list(votes))
          room_data = Map.put(room_data, :playing, playing)
          Videos.set(room, room_data)
        end
      end
    end
  end

  def timer() do
    schedule()

    Enum.each(
      Videos.keys(),
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
