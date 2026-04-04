defmodule Streamshore.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:username, :string)
    field(:email, :string)
    field(:password, :string, redact: true)
    field(:room, :string)
    field(:admin, :integer, default: 0)
    field(:verify_token, :string, default: nil)
    field(:reset_token, :string, default: nil)

    timestamps()
  end

  def registration_changeset(user, params \\ %{}) do
    user
    |> cast(params, [:username, :email, :password, :verify_token, :reset_token])
    |> validate_required([:username, :email, :password])
    |> validate_password()
    |> unique_constraint(:username)
    |> unique_constraint(:email)
    |> hash_password()
  end

  def password_changeset(user, params \\ %{}) do
    user
    |> cast(params, [:password])
    |> validate_required([:password])
    |> validate_password()
    |> put_change(:reset_token, nil)
    |> hash_password()
  end

  def room_changeset(user, params \\ %{}) do
    user
    |> cast(params, [:room])
  end

  def admin_changeset(user, params \\ %{}) do
    user
    |> cast(params, [:admin])
  end

  def verification_changeset(user, params \\ %{}) do
    user
    |> cast(params, [:verify_token])
  end

  def reset_token_changeset(user, params \\ %{}) do
    user
    |> cast(params, [:reset_token])
  end

  defp validate_password(changeset) do
    # Passwords must be at least 8 chars and include upper, lower, number, and special.
    validate_format(
      changeset,
      :password,
      ~r/^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#\$%\^&\*]).{8,}$/,
      message: "is invalid"
    )
  end

  defp hash_password(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password, Pbkdf2.hash_pwd_salt(pass))

      _ ->
        changeset
    end
  end
end
