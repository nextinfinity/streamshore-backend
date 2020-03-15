defmodule Streamshore.User do
    use Ecto.Schema
    import Ecto.Changeset

    schema "users" do
        field(:username, :string, unique: true)
        field(:email, :string, unique: true)
        field(:password, :string)

        timestamps()
    end
    
    def changeset(user, params \\ %{}) do
        user
        |> cast(params, [:username, :email, :password])
        |> unique_constraint(:username)
        |> unique_constraint(:email)
        |> hash_pass
    end

    def convert_changeset_errors(changeset) do
        traverse_errors(changeset, fn {msg, otps} ->
            Enum.reduce(opts, msg, fn {key, value}, acc ->
                String.replace(acc, "%{#{key}}", to_string(value))
            end)
        end)
        |> Enum.reduce("", fn {k, v}, acc ->
            joined_errors = Enum.join(v, "; ")
            "#{acc}#{k}: #{joined_errors}"
        end)
    end

    def valid_password(password) do
        if String.match?(password, ~r/^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#\$%\^&\*])(?=.{8,})/) do
            true
        else 
            false
        end
    end

    def hash_pass(changeset) do
        case changeset do
          %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
                put_change(changeset, :password, Bcrypt.hash_pwd_salt(pass))

            _ ->
                changeset
        end
    end
end