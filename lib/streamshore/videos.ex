defmodule Streamshore.Videos do
  use GenServer

  @me __MODULE__

  def start_link(default \\ []) do
    GenServer.start_link(__MODULE__, default, name: @me)
  end

  def set(key, value) do
    GenServer.cast(@me, { :set, key, value })
  end

  def get(key) do
    GenServer.call(@me, { :get, key })
  end

  def keys do
    GenServer.call(@me, { :keys })
  end

  def delete(key) do
    GenServer.cast(@me, { :remove, key })
  end

  def stop do
    GenServer.stop(@me)
  end

  #######################
  # Server Implemention #
  #######################

  def init(args) do
    schedule()
    { :ok, Enum.into(args, %{}) }
  end

  def schedule, do: Process.send_after(self(), :timer, 1000)

  def handle_cast({ :set, key, value }, state) do
    { :noreply, Map.put(state, key, value) }
  end

  def handle_cast({ :remove, key }, state) do
    { :noreply, Map.delete(state, key) }
  end

  def handle_call({ :get, key }, _from, state) do
    { :reply, state[key], state }
  end

  def handle_call({ :keys }, _from, state) do
    { :reply, Map.keys(state), state }
  end

  def play_next do

  end

  def timer(state) do
    schedule()
    current_time = get_seconds()
    Enum.each(Map.keys(state), fn room ->
      if state[room][:playing] do
        runtime = current_time - state[room][:playing][:start]
        if runtime >= state[room][:playing][:length] do
          play_next()
        else
          StreamshoreWeb.Endpoint.broadcast("room:" <> room, "time", runtime)
        end
      end
    end)
  end

  def get_seconds() do
    :os.system_time(:second)
  end

  def handle_info(:timer, state) do
    timer(state)
    {:noreply, state}
  end

end
