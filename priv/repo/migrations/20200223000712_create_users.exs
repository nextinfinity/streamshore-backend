defmodule Streamshore.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
      create table(:users) do
        add(:userName, :string)
        add(:email, :string)
        add(:password, :string)
        # add(:token, :joken)

        timestamps
    end
  end
end
