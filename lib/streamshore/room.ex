defmodule Streamshore.Room do
    use Ecto.Schema
    import Ecto.Changeset

    schema "rooms" do
        field(:roomName, :string, unique: true)
        field(:roomDesc, :string, unique: true)
        field(:isPrivate, :boolean)

        timestamps()
        # field(:token, :joken)
    end

    def changeset(room, params \\ %{}) do
        room
        |> cast(params, [:roomName, :roomDesc, :isPrivate])
    end
end