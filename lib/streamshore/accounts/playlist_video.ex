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
    |> validate_required([:name, :owner, :video])
    |> unique_constraint(:video, name: :playlist_video_owner_name_video_index, message: "Video is already in playlist")
  end
end
