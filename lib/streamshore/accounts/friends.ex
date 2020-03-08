defmodule Streamshore.Friends do
    use Ecto.Schema
    import Ecto.Changeset
    
    schema "friends" do
        field(:friend, :string)
        field(:friendee, :string)
    end

    def changeset(friend, params \\ %{}) do
        friend
        |> cast(params, [:friend, :friendee])
    end

    
end