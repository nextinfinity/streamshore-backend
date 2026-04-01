defmodule Streamshore.Videos do
  use GenServer

  @me __MODULE__

  def start_link(default \\ []) do
    GenServer.start_link(__MODULE__, default, name: @me)
  end

  def set(key, value) do
    GenServer.call(@me, {:set, key, value})
  end

  def get(key) do
    GenServer.call(@me, {:get, key})
  end

  def keys do
    GenServer.call(@me, {:keys})
  end

  def delete(key) do
    GenServer.call(@me, {:remove, key})
  end

  def stop do
    GenServer.stop(@me)
  end

  #######################
  # Server Implemention #
  #######################

  def init(args) do
    {:ok, Enum.into(args, %{})}
  end

  def handle_call({:set, key, value}, _from, state) do
    {:reply, :ok, Map.put(state, key, value)}
  end

  def handle_call({:get, key}, _from, state) do
    {:reply, state[key], state}
  end

  def handle_call({:keys}, _from, state) do
    {:reply, Map.keys(state), state}
  end

  def handle_call({:remove, key}, _from, state) do
    {:reply, :ok, Map.delete(state, key)}
  end
end
