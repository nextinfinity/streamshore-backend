defmodule Streamshore.Room do
    use Ecto.Schema
    import Ecto.Changeset

    schema "rooms" do
        field :roomName, :string
        field :roomDesc, :string
        field :isPrivate, :boolean
        timestamps()
    end

    def changeset(room, params \\ %{}) do
        room
        |> cast(params, [:roomName, :roomDesc, :isPrivate])
        |> validate_required([:roomName])
        |> validate_length(:roomName, min: 1, max: 32)
    end

end