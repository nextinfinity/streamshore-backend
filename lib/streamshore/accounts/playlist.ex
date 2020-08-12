defmodule Streamshore.Playlist do
  use Ecto.Schema
  import Ecto.Changeset

  schema "playlists" do
    field(:name, :string)
    field(:owner, :string)
  end

  def changeset(playlist, params \\ %{}) do
    playlist
    |> cast(params, [:name, :owner])
  end
end
