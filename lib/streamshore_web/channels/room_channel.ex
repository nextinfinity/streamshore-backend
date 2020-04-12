defmodule StreamshoreWeb.RoomChannel do
  use StreamshoreWeb, :channel

  alias StreamshoreWeb.PermissionController
  alias Streamshore.PermissionLevel
  alias StreamshoreWeb.Presence
  alias Streamshore.Repo
  alias Streamshore.User
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
    push(socket, "presence_state", Presence.list(socket))
    "room:" <> room = socket.topic
    perm = PermissionController.get_perm(room, socket.assigns.user)
    {:ok, _} = Presence.track(socket, socket.assigns.user, %{
      anon: socket.assigns.anon,
      permission: perm,
      online_at: inspect(System.system_time(:second))
    })
    room = Enum.at(String.split(socket.topic, ":"), 1)
    case Repo.get_by(User, %{username: socket.assigns.user}) do
      nil -> nil
      schema -> schema
                |> User.changeset(%{room: room})
                |> Repo.update()
    end
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
  defp authorized?(user, room) do
    PermissionController.get_perm(room, user) > PermissionLevel.banned()
  end

  def terminate(_reason, socket) do
    case Repo.get_by(User, %{username: socket.assigns.user}) do
      nil -> nil
      schema -> schema
                |> User.changeset(%{room: nil})
                |> Repo.update()
    end
  end
end
