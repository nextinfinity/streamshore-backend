defmodule StreamshoreWeb.RoomChannel do
  use StreamshoreWeb, :channel
  alias StreamshoreWeb.Presence

  def join("room:" <> _room, payload, socket) do
    if authorized?(payload) do
      send(self(), :after_join)
      {:ok, assign(socket, :user_id, payload["user_id"])}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info(:after_join, socket) do
    push(socket, "presence_state", Presence.list(socket))
    {:ok, _} = Presence.track(socket, socket.assigns.user_id, %{
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
    payload = Map.put(payload, :time, time)
    payload = Map.put(payload, :uuid, UUID.uuid4())
    broadcast socket, "chat", payload
    {:noreply, socket}
  end

  def handle_in("video", payload, socket) do
    video = Streamshore.QueueManager.get_video(payload["room"])
    video = if video do
      video
    else
      %{}
    end
    {:reply, {:ok, video}, socket}
  end

  def handle_in("delete", payload, socket) do
    broadcast socket, "delete", payload
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    # TODO: authentication
    true
  end
end
