defmodule StreamshoreWeb.RoomChatChannel do
  use StreamshoreWeb, :channel

  # TODO: handle multiple topics (would a simple room_chat:* do here?)
  def join("room_chat:" <> room, payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (room_chat:lobby).
  def handle_in("new:msg", payload, socket) do
    broadcast socket, "new:msg", payload
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    # TODO: authentication
    true
  end
end
