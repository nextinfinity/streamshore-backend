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
    { :ok, Enum.into(args, %{}) }
  end

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

end
