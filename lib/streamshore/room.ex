defmodule Streamshore.Room do
    use Ecto.Schema
    import Ecto.Changeset

    schema "rooms" do
        field :name, :string
        field :description, :string
        field :privacy, :integer
        field :owner, :string
        field :route, :string
        timestamps()
    end

    def changeset(room, params \\ %{}) do
        room
        |> cast(params, [:name, :description, :privacy, :owner, :route])
        |> validate_required([:name])
        |> validate_length(:name, min: 1, max: 32)
    end

end