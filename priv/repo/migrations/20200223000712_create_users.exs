defmodule Streamshore.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
      create table(:user) do
        add(:userName, :string)
        add(:email, :string)
        add(:password, :string)
    end
  end
end
