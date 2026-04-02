defmodule Streamshore.Favorites do
  use Ecto.Schema
  import Ecto.Changeset

  schema "favorites" do
    field(:user, :string)
    field(:room, :string)
  end

  def changeset(favorite, params \\ %{}) do
    favorite
    |> cast(params, [:user, :room])
    |> validate_required([:user, :room])
    |> unique_constraint(:room, name: :favorites_user_room_index, message: "Room is already a favorite room")
  end
end
