defmodule Streamshore.Favorites do
    use Ecto.Schema
    import Ecto.Changeset
    
    schema "favorites" do
        field(:user, :string)
        field(:room, :string)
    end

    def changeset(favorite, params \\ %{}) do
        favorite
        |> cast(params, [:user, :room])
    end


end