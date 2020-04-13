defmodule Streamshore.Repo.Migrations.Favorites do
  use Ecto.Migration

  def change do
    create table(:favorites) do 
      add(:user, :string)
      add(:room, :string)
    end
    
  end
end
