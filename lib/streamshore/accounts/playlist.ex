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
    |> validate_required([:name, :owner])
    |> unique_constraint(:name,
      name: :playlists_owner_name_index,
      message: "Playlist already exists"
    )
  end
end
