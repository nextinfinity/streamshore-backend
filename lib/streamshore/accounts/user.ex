defmodule Streamshore.User do
    use Ecto.Schema
    import Ecto.Changeset
    alias Comeonin.Bcrypt

    schema "users" do
        field(:username, :string, unique: true)
        field(:email, :string, unique: true)
        field(:password, :string)

        timestamps()
        # field(:token, :joken)
    end
    
    def changeset(user, params \\ %{}) do
        user
        |> cast(params, [:username, :email, :password])
        |> unique_constraint(:username)
        |> unique_constraint(:email)
        |> valid_password()
        |> hash_pass
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

    def hash_pass(changeset) do
        case changeset do
          %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
                put_change(changeset, :password, Bcrypt.hashpwsalt(pass))

            _ ->
                changeset
        end
    end
end