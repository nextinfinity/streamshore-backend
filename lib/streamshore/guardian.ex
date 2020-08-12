defmodule Streamshore.Guardian do
  use Guardian, otp_app: :streamshore

  alias StreamshoreWeb.PermissionController
  alias StreamshoreWeb.UserController

  def subject_for_token(user, _claims) do
    sub = to_string(user)
    {:ok, sub}
  end

  def resource_from_claims(claims) do
    user = claims["sub"]
    anon = claims["anon"]
    resource = %{user: user, anon: anon}
    {:ok, resource}
  end

  def token_from_conn(conn) do
    case Enum.find(conn.req_headers, fn {key, _value} ->
           String.downcase(key) == "authorization"
         end) do
      {_, "Bearer " <> token} -> token
      _ -> nil
    end
  end

  def get_user(token) do
    case token do
      nil ->
        {:error, "No valid token provided"}

      token ->
        case decode_and_verify(token) do
          {:error, _error} ->
            {:error, "Invalid token"}

          {:ok, claims} ->
            {:ok, claims["sub"], claims["anon"]}
        end
    end
  end

  def get_user_and_permission(token, room) do
    case token do
      nil ->
        {:error, "No valid token provided"}

      token ->
        case get_user(token) do
          {:error, error} ->
            {:error, error}

          {:ok, user, anon} ->
            perm = PermissionController.get_perm(room, user)
            {:ok, user, anon, perm}
        end
    end
  end

  def get_user_and_admin(token) do
    case token do
      nil ->
        {:error, "No valid token provided"}

      token ->
        case get_user(token) do
          {:error, error} ->
            {:error, error}

          {:ok, user, anon} ->
            admin = UserController.get_admin(user)
            {:ok, user, anon, admin}
        end
    end
  end
end
