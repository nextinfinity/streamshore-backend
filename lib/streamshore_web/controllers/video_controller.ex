defmodule StreamshoreWeb.VideoController do
  use StreamshoreWeb, :controller
  use GenServer

  queue = %{}
  current_video = %{}
  start_time = %{}

  def start_link(_params) do
    GenServer.start_link(__MODULE__, [])
  end

  def init(state) do
    schedule()
    {:ok, state}
  end

  def schedule, do: Process.send_after(self(), :timer, 1000)

  def index(conn, _params) do
    # TODO: list
  end

  def edit(conn, _params) do
    # TODO: edit video (precursor to update)
  end

  def new(conn, _params) do
    # TODO: new video (precursor to create)
  end

  def show(conn, _params) do
    # TODO: show video info
  end

  def create(conn, _params) do
    # TODO: create video (add to list)
  end

  def update(conn, _params) do
    # TODO: video edit action
  end

  def delete(conn, _params) do
    # TODO: delete video
  end

  def timer() do
    schedule()
    IO.puts(get_seconds)
  end

  def get_seconds() do
    :os.system_time(:second)
  end

  def handle_info(:timer, state) do
    timer()
    {:noreply, state}
  end

end
