defmodule Streamshore.Repo.Migrations.AddPlaylistVideo do
  use Ecto.Migration

  def change do
     create table(:playlist_video) do 
      add(:name, :string)
      add(:owner, :string)
      add(:video, :string)
    end

  end
end
