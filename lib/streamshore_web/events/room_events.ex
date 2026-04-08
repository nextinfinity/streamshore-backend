defmodule StreamshoreWeb.RoomEvents do
  alias StreamshoreWeb.Endpoint

  def dispatch({:room_deleted, route}) do
    Endpoint.broadcast("room:" <> route, "room-deleted", %{})
  end

  def dispatch({:room_updated, route, payload}) do
    Endpoint.broadcast("room:" <> route, "update", payload)
  end

  def dispatch({:permission_updated, route, payload}) do
    Endpoint.broadcast("room:" <> route, "permission", payload)
  end
end
