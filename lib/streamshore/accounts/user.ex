defmodule Streamshore.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:username, :string, unique: true)
    field(:email, :string, unique: true)
    field(:password, :string)
    field(:room, :string)
    field(:admin, :integer, default: 0)
    field(:verify_token, :string, default: nil)
    field(:reset_token, :string, default: nil)

    timestamps()
    # field(:token, :joken)
  end

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, [:username, :email, :password, :room, :admin, :verify_token, :reset_token])
    |> unique_constraint(:username)
    |> unique_constraint(:email)
    |> hash_pass
  end

  def valid_password(password) do
    if Regex.match?(~r/^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#\$%\^&\*])(?=.{8,})/, password) do
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

  #    def set_name_if_anonymous(changeset) do
  #        name = get_field(changeset, :username)
  #
  #        if is_nil(name) do
  #          put_change(changeset, :username, String.capitalize(String.trim(random_adjective(), "\r")) <>
  #          String.capitalize(String.trim(random_adjective(), "\r")) <>
  #          String.capitalize(String.trim(random_animal(), "\r")))
  #        else
  #          changeset
  #        end
  #    end
end
