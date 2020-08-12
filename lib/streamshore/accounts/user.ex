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
  end

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, [:username, :email, :password, :room, :admin, :verify_token, :reset_token])
    |> unique_constraint(:username)
    |> unique_constraint(:email)
    |> hash_pass
  end

  def valid_password(password) do
    Regex.match?(~r/^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#\$%\^&\*])(?=.{8,})/, password)
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
