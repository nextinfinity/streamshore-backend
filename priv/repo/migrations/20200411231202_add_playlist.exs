defmodule Streamshore.Repo.Migrations.AddPlaylist do
  use Ecto.Migration

  def change do
    create table(:playlists) do 
      add(:name, :string)
      add(:owner, :string)
    end

  end
end
