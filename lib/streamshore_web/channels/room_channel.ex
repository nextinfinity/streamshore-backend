defmodule StreamshoreWeb.RoomChannel do
  use StreamshoreWeb, :channel

  alias Streamshore.Filter
  alias StreamshoreWeb.PermissionController
  alias Streamshore.PermissionLevel
  alias StreamshoreWeb.Presence
  alias StreamshoreWeb.RoomController
  alias StreamshoreWeb.UserController
  alias Streamshore.Videos

  def join("room:" <> room, _payload, socket) do
    if authorized?(socket.assigns.user, room) do
      send(self(), :after_join)
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info(:after_join, socket) do
    "room:" <> room = socket.topic
    motd = RoomController.get_motd(room)
    if motd != "" do
      push(socket, "motd", %{message: motd})
    end
    push(socket, "presence_state", Presence.list(socket))
    perm = PermissionController.get_perm(room, socket.assigns.user)
    {:ok, _} = Presence.track(socket, socket.assigns.user, %{
      anon: socket.assigns.anon,
      permission: perm,
      online_at: inspect(System.system_time(:second))
    })
    "room:" <> room = socket.topic
    UserController.set_room(socket.assigns.user, room)
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
    "room:" <> room = socket.topic
    perm = PermissionController.get_perm(room, socket.assigns.user)
    if perm >= RoomController.chat_perm(room) do
      if RoomController.anon_chat?(room) || !socket.assigns.anon do
        time = Timex.to_unix(Timex.now)
        uuid = UUID.uuid4()
        payload = if RoomController.filter_enabled?(room) do
          Map.put(payload, "msg", filter(payload["msg"]))
        else
          payload
        end
        payload = Map.merge(payload, %{user: socket.assigns.user, anon: socket.assigns.anon, time: time, uuid: uuid})
        broadcast socket, "chat", payload
      end
    end
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
  defp authorized?(user, room) do
    PermissionController.get_perm(room, user) > PermissionLevel.banned()
  end

  defp filter(msg) do
    regex_string = Enum.reduce(Filter.bad_words(), fn word, acc -> acc <> "|" <> word end)
    {:ok, regex} = Regex.compile("\\b(" <> regex_string <> ")\\b", [:caseless, :extended])
    String.replace(msg, regex, "*****")
  end

  def terminate(_reason, socket) do
    UserController.set_room(socket.assigns.user, nil)
  end
end
