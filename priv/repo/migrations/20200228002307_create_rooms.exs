defmodule Streamshore.Repo.Migrations.CreateRooms do
  use Ecto.Migration

  def change do
    create table(:rooms) do
      add(:roomName, :string)
      add(:roomDesc, :string)
      add(:isPrivate, :bool)

      timestamps

  end
end
