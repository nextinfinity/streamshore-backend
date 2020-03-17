defmodule Streamshore.Repo.Migrations.CreateRooms do
  use Ecto.Migration

  def change do
    create table(:rooms) do
      add(:name, :string)
      add(:description, :string)
      add(:privacy, :integer)
      add(:owner, :string)
      add(:route, :string)
      timestamps
    end
  end
end
