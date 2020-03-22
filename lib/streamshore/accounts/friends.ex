defmodule Streamshore.Friends do
    use Ecto.Schema
    import Ecto.Changeset
    
    schema "friends" do
        field(:friender, :string)
        field(:friendee, :string)
        field(:nickname, :string)
    end

    def changeset(friend, params \\ %{}) do
        friend
        |> cast(params, [:friender, :friendee, :nickname])
    end

    
end