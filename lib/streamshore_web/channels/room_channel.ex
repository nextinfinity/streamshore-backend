defmodule StreamshoreWeb.RoomChannel do
  use StreamshoreWeb, :channel
  alias StreamshoreWeb.PermissionController
  alias Streamshore.PermissionLevel
  alias StreamshoreWeb.Presence
  alias Streamshore.Videos

  def join("room:" <> room, payload, socket) do
    if authorized?(payload, room) do
      send(self(), :after_join)
      perm = PermissionController.get_perm(room, payload["user"])
      socket = assign(socket, :user, payload["user"])
      socket = assign(socket, :anon, payload["anon"])
      socket = assign(socket, :permission, perm)
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info(:after_join, socket) do
    push(socket, "presence_state", Presence.list(socket))
    {:ok, _} = Presence.track(socket, socket.assigns.user, %{
      anon: socket.assigns.anon,
      permission: socket.assigns.permission,
      online_at: inspect(System.system_time(:second))
    })
    {:noreply, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (room_chat:lobby).
  def handle_in("chat", payload, socket) do
    time = Timex.to_unix(Timex.now)
    uuid = UUID.uuid4()
    payload = Map.merge(payload, %{user: socket.assigns.user, anon: socket.assigns.anon, time: time, uuid: uuid})
    broadcast socket, "chat", payload
    {:noreply, socket}
  end

  def handle_in("video", payload, socket) do
    data = case Videos.get(payload["room"]) do
      nil -> %{}
      data -> data
    end
    {:reply, {:ok, data}, socket}
  end

  def handle_in("delete", payload, socket) do
    broadcast socket, "delete", payload
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(payload, room) do
    PermissionController.get_perm(room, payload["user"]) > PermissionLevel.banned()
  end
end
