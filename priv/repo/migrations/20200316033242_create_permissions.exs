defmodule Streamshore.Repo.Migrations.CreatePermissions do
  use Ecto.Migration

  def change do
    create table(:permissions) do
      add(:username, :string)
      add(:room, :string)
      add(:permission, :integer)

      timestamps()
    end
  end
end
