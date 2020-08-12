defmodule Streamshore.Repo.Migrations.CreateRooms do
  use Ecto.Migration

  def change do
    create table(:rooms) do
      add(:name, :string)
      add(:motd, :string)
      add(:privacy, :integer)
      add(:owner, :string)
      add(:route, :string)
      add(:thumbnail, :string)
      add(:queue_level, :integer)
      add(:anon_queue, :integer)
      add(:queue_limit, :integer)
      add(:chat_level, :integer)
      add(:anon_chat, :integer)
      add(:chat_filter, :integer)
      add(:vote_threshold, :integer)
      add(:vote_enable, :integer)

      timestamps()
    end

    create(unique_index(:rooms, [:name]))
    create(unique_index(:rooms, [:route]))
  end
end
