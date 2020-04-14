defmodule Streamshore.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
      create table(:users) do
        add(:username, :string)
        add(:email, :string)
        add(:password, :string)
        add(:room, :string)
        add(:admin, :integer)
        add(:verify-token, :string)
        add(:reset-token, :string)
        # add(:token, :joken)

        timestamps()
    end

    create(unique_index(:users, [:username]))
    create(unique_index(:users, [:email]))
  end
end
