defmodule Streamshore.PlaylistVideo do
  use Ecto.Schema
  import Ecto.Changeset

  schema "playlist_video" do
    field(:name, :string)
    field(:owner, :string)
    field(:video, :string)
  end

  def changeset(playlist_video, params \\ %{}) do
    playlist_video
    |> cast(params, [:name, :owner, :video])
  end
end