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
    |> valid_username()
    |> valid_password()
    |> valid_email()
    end

    def valid_username(changeset) do
        # TODO: Check for unique username
    end

    def valid_password(changeset) do
        password = get_field(changeset, :password)
        # TODO: Hash password
        left_map = %{key: password}
        if (match?(left_map, "^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#\$%\^&\*])(?=.{8,})")) do
            changeset
        else 
            add_error(changeset, :password, "is not a valid password")
        end
    end

    # Checks to see if the email that has been set to the changeset is a valid email.
    # If it is not, then it errors, if it is, then it continues.
    def valid_email(changeset) do
        email = get_field(changeset, :email)
        #TODO: Add check for unique email
        left_map = %{key: email}
        #TODO: Add Regex for email
        if (match?(left_map, "")) do
            changeset
        else 
            add_error(changeset, :email, "is not a valid email")
        end
    end
end