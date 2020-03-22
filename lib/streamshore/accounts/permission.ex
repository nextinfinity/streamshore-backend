defmodule Streamshore.Permission do
  use Ecto.Schema
  import Ecto.Changeset

  schema "permissions" do
    field(:username, :string)
    field(:room, :string)
    field(:permission, :integer)

    timestamps()
  end

  def changeset(permission, params \\ %{}) do
    permission
    |> cast(params, [:username, :room, :permission])
  end
end