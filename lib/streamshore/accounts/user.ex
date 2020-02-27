defmodule Streamshore.User do
    use Ecto.Schema
    import Ecto.Changeset

    schema "users" do
        field(:username, :string, unique: true)
        field(:email, :string, unique: true)
        field(:password, :string)

        timestamps()
        # field(:token, :joken)
    end
    
    def register_changeset(user, params \\ %{}) do
    user
    |> cast(params, [:username, :email, :password])
    |> unique_constraint(:username)
    |> unique_constraint(:email)
    |> valid_password()
    end

    def valid_password(changeset) do
    # TODO: Implement later
        # pass = Ecto.Changeset.get_field(changeset, :password)
        # # TODO: Hash password
        # left_map = %{key: pass}
        # if (match?(left_map, "^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#\$%\^&\*])(?=.{8,})")) do
        #     changeset
        # else 
        #     add_error(changeset, :password, "is not a valid password")
        # end
        changeset
    end
end