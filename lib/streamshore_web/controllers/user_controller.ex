defmodule StreamshoreWeb.UserController do
  use StreamshoreWeb, :controller

  alias Streamshore.Accounts
  alias Streamshore.Events
  alias Streamshore.Guardian
  alias StreamshoreWeb.ApiResponses

  def index(conn, _params) do
    case Guardian.get_user_and_admin(Guardian.token_from_conn(conn)) do
      {:error, error} ->
        ApiResponses.error(conn, :unauthorized, error)

      {:ok, _user, _anon, admin} ->
        if admin do
          ApiResponses.ok(conn, Accounts.list_users())
        else
          ApiResponses.error(conn, :forbidden, "Insufficient permission")
        end
    end
  end

  def create(conn, params) do
    case Accounts.create_user(params) do
      {:ok, _user, events} ->
        Events.dispatch_all(events)
        ApiResponses.ok(conn)

      {:error, changeset} ->
        ApiResponses.changeset_error(conn, changeset)
    end
  end

  def show(conn, params) do
    case Accounts.get_public_user(params["id"]) do
      nil ->
        ApiResponses.error(conn, :not_found, "User not found")

      user ->
        ApiResponses.ok(conn, Map.put(user, :online, user[:room] != nil))
    end
  end

  def update(conn, params) do
    cond do
      params["resend_verification"] ->
        handle_resend_verification(conn, params)

      params["reset_password"] ->
        handle_password_reset_request(conn, params)

      params["verify_token"] ->
        handle_verify_email(conn, params)

      params["password"] ->
        handle_password_update(conn, params)

      true ->
        ApiResponses.error(conn, :bad_request, "No valid options specified")
    end
  end

  def delete(conn, params) do
    case Guardian.get_user(Guardian.token_from_conn(conn)) do
      {:ok, user, anon} ->
        username = params["id"]

        if user == username && !anon do
          case Accounts.delete_user(username) do
            {:ok, _schema, events} ->
              Events.dispatch_all(events)
              ApiResponses.ok(conn)

            {:error, :not_found} ->
              ApiResponses.error(conn, :not_found, "User not found")

            {:error, changeset} ->
              ApiResponses.changeset_error(conn, changeset)
          end
        else
          ApiResponses.error(conn, :forbidden, "Insufficient permission")
        end

      {:error, error} ->
        ApiResponses.error(conn, :unauthorized, error)
    end
  end

  defp handle_resend_verification(conn, params) do
    case Accounts.resend_verification_email(params["id"]) do
      {:error, :not_found} ->
        ApiResponses.error(conn, :not_found, "User not found")

      {:error, :already_verified} ->
        ApiResponses.error(conn, :conflict, "Email already verified")

      {:ok, _schema, events} ->
        Events.dispatch_all(events)
        ApiResponses.ok(conn)
    end
  end

  defp handle_password_reset_request(conn, params) do
    case Accounts.store_reset_token(params["id"]) do
      {:error, :not_found} ->
        ApiResponses.error(conn, :not_found, "User not found")

      {:ok, _schema, events} ->
        Events.dispatch_all(events)
        ApiResponses.ok(conn)

      {:error, changeset} ->
        ApiResponses.changeset_error(conn, changeset)
    end
  end

  defp handle_verify_email(conn, params) do
    case Accounts.verify_email(params["id"], params["verify_token"]) do
      {:error, :not_found} ->
        ApiResponses.error(conn, :not_found, "User not found")

      {:error, :already_verified} ->
        ApiResponses.error(conn, :conflict, "Email already verified")

      {:error, :invalid_token} ->
        ApiResponses.error(conn, :unauthorized, "Invalid token")

      {:ok, _schema} ->
        ApiResponses.ok(conn)

      {:error, changeset} ->
        ApiResponses.changeset_error(conn, changeset)
    end
  end

  defp handle_password_update(conn, params) do
    case Guardian.get_user(Guardian.token_from_conn(conn)) do
      {:error, error} ->
        ApiResponses.error(conn, :unauthorized, error)

      {:ok, user, anon} ->
        username = params["id"]

        if !anon do
          if user == username || user == "Reset-" <> username do
            case Accounts.update_password(username, params["password"]) do
              {:ok, _schema} ->
                ApiResponses.ok(conn)

              {:error, :not_found} ->
                ApiResponses.error(conn, :not_found, "User not found")

              {:error, changeset} ->
                ApiResponses.changeset_error(conn, changeset)
            end
          else
            ApiResponses.error(conn, :forbidden, "Insufficient permission")
          end
        else
          ApiResponses.error(conn, :forbidden, "Insufficient permission")
        end
    end
  end
end
