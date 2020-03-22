defmodule Streamshore.Repo.Migrations.CreateRooms do
  use Ecto.Migration

  def change do
    create table(:rooms) do
      add(:name, :string)
      add(:description, :string)
      add(:privacy, :integer)
      add(:owner, :string)
      add(:route, :string)
      add(:thumbnail, :string)
      timestamps
    end

    create(unique_index(:rooms, [:name]))
    create(unique_index(:rooms, [:route]))
  end
end
