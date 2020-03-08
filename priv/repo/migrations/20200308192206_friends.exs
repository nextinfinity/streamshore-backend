defmodule Streamshore.Repo.Migrations.Friends do
  use Ecto.Migration

  def change do
    create table(:friends) do
      add(:friend, :string)
      add(:friendee, :string)
  end
end
