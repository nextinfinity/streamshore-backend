defmodule Streamshore.Repo.Migrations.Friends do
  use Ecto.Migration

  def change do
    create table(:friends) do 
      add(:friender, :string)
      add(:friendee, :string)
      add(:nickname, :string)
    end

  end
end
