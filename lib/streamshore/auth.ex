defmodule Streamshore.Auth do
  import Dictionary

  alias Streamshore.AuthTokens
  alias Streamshore.Guardian
  alias Streamshore.Repo
  alias Streamshore.User

  def log_in_with_password(identifier, password) do
    with user when not is_nil(user) <- user_by_identifier(identifier),
         true <- Pbkdf2.verify_pass(password, user.password),
         :ok <- ensure_verified(user) do
      {:ok, session_payload(user.username, false)}
    else
      nil ->
        {:error, :invalid_credentials}

      false ->
        {:error, :invalid_credentials}

      {:error, :email_not_verified} ->
        {:error, :email_not_verified}
    end
  end

  def create_anonymous_session do
    {:ok, session_payload(build_anonymous_username(), true)}
  end

  def resend_verification(identifier) do
    case user_by_identifier(identifier) do
      nil ->
        {:error, :not_found}

      %User{verify_token: nil} ->
        {:error, :already_verified}

      %User{} = user ->
        token = AuthTokens.create_verify_email_token(user.username)

        case update_user(user.username, &User.verification_changeset(&1, %{verify_token: token})) do
          {:ok, updated_user} ->
            {:ok, updated_user, [{:send_verification_email, updated_user}]}

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  def request_password_reset(identifier) do
    case user_by_identifier(identifier) do
      nil ->
        {:error, :not_found}

      %User{} = user ->
        token = AuthTokens.create_password_reset_token(user.username)

        case update_user(user.username, &User.reset_token_changeset(&1, %{reset_token: token})) do
          {:ok, updated_user} ->
            {:ok, updated_user, [{:send_password_reset_email, updated_user, token}]}

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  def reset_password_from_token(reset_token, password) do
    with {:ok, username} <- AuthTokens.password_reset_username(reset_token) do
      reset_password(username, reset_token, password)
    end
  end

  def verify_email_from_token(token) do
    with {:ok, username} <- AuthTokens.verify_email_username(token) do
      verify_email(username, token)
    end
  end

  def update_password(username, password) do
    update_user(username, &User.password_changeset(&1, %{password: password}))
  end

  def log_out(token) do
    Guardian.revoke(token)
  end

  defp user_by_identifier(identifier) do
    case Repo.get_by(User, email: identifier) do
      nil -> Repo.get_by(User, username: identifier)
      user -> user
    end
  end

  defp verify_email(username, token) do
    case Repo.get_by(User, username: username) do
      nil ->
        {:error, :not_found}

      %User{verify_token: nil} ->
        {:error, :already_verified}

      %User{verify_token: ^token} ->
        update_user(username, &User.verification_changeset(&1, %{verify_token: nil}))

      %User{} ->
        {:error, :invalid_token}
    end
  end

  defp reset_password(username, reset_token, password) do
    case Repo.get_by(User, username: username) do
      nil ->
        {:error, :not_found}

      %User{reset_token: ^reset_token} when not is_nil(reset_token) ->
        update_password(username, password)

      %User{} ->
        {:error, :invalid_token}
    end
  end

  defp update_user(username, changeset_fun) do
    case Repo.get_by(User, username: username) do
      nil ->
        {:error, :not_found}

      user ->
        user
        |> changeset_fun.()
        |> Repo.update()
    end
  end

  defp ensure_verified(%{verify_token: nil}), do: :ok
  defp ensure_verified(_user), do: {:error, :email_not_verified}

  defp session_payload(username, anonymous?) do
    %{
      token: AuthTokens.create_session_token(username, anonymous?),
      user: username,
      anon: anonymous?
    }
  end

  defp build_anonymous_username do
    String.capitalize(String.trim(random_adjective(), "\r")) <>
      String.capitalize(String.trim(random_adjective(), "\r")) <>
      String.capitalize(String.trim(random_animal(), "\r"))
  end
end
