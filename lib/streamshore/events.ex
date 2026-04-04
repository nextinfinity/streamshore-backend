defmodule Streamshore.Events do
  alias Streamshore.AccountEvents
  alias StreamshoreWeb.RoomEvents

  def dispatch_all(events) do
    Enum.each(events, &dispatch/1)
  end

  def dispatch({:room_deleted, route}) do
    RoomEvents.dispatch({:room_deleted, route})
  end

  def dispatch({:room_updated, route, payload}) do
    RoomEvents.dispatch({:room_updated, route, payload})
  end

  def dispatch({:send_verification_email, user}) do
    AccountEvents.dispatch({:send_verification_email, user})
  end

  def dispatch({:send_password_reset_email, user, token}) do
    AccountEvents.dispatch({:send_password_reset_email, user, token})
  end
end
