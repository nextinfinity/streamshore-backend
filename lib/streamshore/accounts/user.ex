defmodule Streamshore.Accounts.User do
    use Ecto.Schema

    schema "users" do
        field(:username, :string, unique: true)
        field(:email, :string, unique: true)
        field(:password, :string)
    end
    
    def changeset(user, params \\ %{}) do
    user
    |> Ecto.Changeset.cast(params, [:username, :email, :password])
    |> Ecto.Changeset.validate_required([:username, :password])
    end
end