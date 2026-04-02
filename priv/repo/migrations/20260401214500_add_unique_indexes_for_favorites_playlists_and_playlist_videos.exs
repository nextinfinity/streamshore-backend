defmodule Streamshore.Repo.Migrations.AddUniqueIndexesForFavoritesPlaylistsAndPlaylistVideos do
  use Ecto.Migration

  def change do
    create unique_index(:favorites, [:user, :room])
    create unique_index(:playlists, [:owner, :name])
    create unique_index(:playlist_video, [:owner, :name, :video])
  end
end
