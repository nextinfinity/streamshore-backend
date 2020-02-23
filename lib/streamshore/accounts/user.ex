defmodule Streamshore.User do
    use Ecto.Schema
    import Ecto.Changeset

    schema "users" do
        field(:username, :string, unique: true)
        field(:email, :string, unique: true)
        field(:password, :string)
        # field(:token, :joken)
    end
    
    def register_changeset(user, params \\ %{}) do
    user
    |> cast(params, [:username, :email, :password])
    |> valid_password()
    |> valid_email()
    end

    def valid_password(changeset) do
        password = get_field(changeset, :password)
        #TODO: Validate
        changeset
    end

    def valid_email(changeset) do
        email = get_field(changeset, :email)
        #TODO: Validate
        changeset
    end
end