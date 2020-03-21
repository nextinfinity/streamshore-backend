defmodule Streamshore.Room do
    use Ecto.Schema
    import Ecto.Changeset

    schema "rooms" do
        field :name, :string, unique: true
        field :description, :string
        field :privacy, :integer
        field :owner, :string
        field :route, :string, unique: true
        field :thumbnail, :string
        timestamps()
    end

    def changeset(room, params \\ %{}) do
        room
        |> cast(params, [:name, :description, :privacy, :owner, :route, :thumbnail])
        |> validate_required([:name])
        |> validate_required([:owner])
        |> validate_required([:route])
        |> validate_length(:name, min: 1, max: 32)
        |> validate_length(:route, min: 1, max: 32)
        |> unique_constraint(:name)
        |> unique_constraint(:route)
    end

end