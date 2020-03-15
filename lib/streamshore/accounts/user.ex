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
        changeset
    end

    def hash_pass(changeset) do
        case changeset do
          %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
                put_change(changeset, :password, Bcrypt.hash_pwd_salt(pass))

            _ ->
                changeset
        end
    end

    def set_name_if_anonymous(changeset) do
        #name = get_field(changeset, :username)
      
        #if is_nil(name) do
          #put_change(changeset, :username, String.capitalize(String.trim(random_adjective(), "\r")) <>
          #String.capitalize(String.trim(random_adjective(), "\r")) <>
          #String.capitalize(String.trim(random_animal(), "\r")))
        #else
          #changeset
        #end
    end
end