defmodule StreamshoreWeb.UserController do
  use StreamshoreWeb, :controller

  alias Streamshore.Accounts
  alias Streamshore.AuthTokens
  alias Streamshore.Guardian
  alias Streamshore.Favorites
  alias Streamshore.Friends
  alias Streamshore.Mailer
  alias Streamshore.Permission
  alias Streamshore.Playlist
  alias Streamshore.PlaylistVideo
  alias Streamshore.Repo
  alias Streamshore.Room
  alias Streamshore.User
  alias StreamshoreWeb.ApiResponses
  import Ecto.Query

  def index(conn, _params) do
    case Guardian.get_user_and_admin(Guardian.token_from_conn(conn)) do
      {:error, error} ->
        ApiResponses.error(conn, :unauthorized, error)

      {:ok, _user, _anon, admin} ->
        if admin do
          query =
            from u in User,
              select: %{
                username: u.username,
                email: u.email,
                room: u.room,
                admin: u.admin,
                verify_token: u.verify_token
              }

          users = Repo.all(query)
          ApiResponses.ok(conn, users)
        else
          ApiResponses.error(conn, :forbidden, "Insufficient permission")
        end
    end
  end

  def create(conn, params) do
    password = params["password"]
    valid_pass = User.valid_password(password)

    if !valid_pass do
      ApiResponses.error(conn, :unprocessable_entity, "password: password is invalid")
    else
      verify_token = AuthTokens.create_token("Verify-" <> params["username"], false)

      params =
        if Mailer.enabled?() do
          Map.put(params, "verify_token", verify_token)
        else
          params
        end

      successful =
        %Streamshore.User{}
        |> User.changeset(params)
        |> Repo.insert()

      case successful do
        {:ok, _schema} ->
          Mailer.send_email(
            params["email"],
            "Verify your email!",
            "https://streamshore.tv/verify?user=" <>
              params["username"] <> "&token=" <> verify_token
          )

          ApiResponses.ok(conn)

        {:error, changeset} ->
          ApiResponses.changeset_error(conn, changeset)
      end
    end
  end

  def show(conn, params) do
    user =
      Repo.one(
        from(u in User,
          where: [username: ^params["id"]],
          select: %{username: u.username, room: u.room}
        )
      )

    case user do
      nil ->
        ApiResponses.error(conn, :not_found, "User not found")

      user ->
        ApiResponses.ok(conn, Map.put(user, :online, user[:room] != nil))
    end
  end

  def update(conn, params) do
    cond do
      params["resend_verification"] ->
        user = Accounts.get_by_email_or_username(params["id"])

        case user do
          nil ->
            ApiResponses.error(conn, :not_found, "User not found")

          schema ->
            case schema.verify_token do
              nil ->
                ApiResponses.error(conn, :conflict, "Email already verified")

              token ->
                Mailer.send_email(
                  schema.email,
                  "Verify your email!",
                  "https://streamshore.tv/verify?user=" <> schema.username <> "&token=" <> token
                )

                ApiResponses.ok(conn)
            end
        end

      params["reset_password"] ->
        case User |> Repo.get_by(email: params["id"]) do
          nil ->
            ApiResponses.error(conn, :not_found, "User not found")

          schema ->
            reset_token = AuthTokens.create_token("Reset-" <> schema.username, false)

            Mailer.send_email(
              params["id"],
              "Reset your password!",
              "https://streamshore.tv/reset?user=" <> schema.username <> "&token=" <> reset_token
            )

            schema
            |> User.changeset(%{reset_token: reset_token})
            |> Repo.update()

            ApiResponses.ok(conn)
        end

      params["verify_token"] ->
        case User |> Repo.get_by(username: params["id"]) do
          nil ->
            ApiResponses.error(conn, :not_found, "User not found")

          schema ->
            token = params["verify_token"]

            case schema.verify_token do
              nil ->
                ApiResponses.error(conn, :conflict, "Email already verified")

              ^token ->
                schema
                |> User.changeset(%{verify_token: nil})
                |> Repo.update()

                ApiResponses.ok(conn)

              _ ->
                ApiResponses.error(conn, :unauthorized, "Invalid token")
            end
        end

      params["password"] ->
        case Guardian.get_user(Guardian.token_from_conn(conn)) do
          {:error, error} ->
            ApiResponses.error(conn, :unauthorized, error)

          {:ok, user, anon} ->
            username = params["id"]

            if !anon do
              if user == username || user == "Reset-" <> username do
                user_entry = User |> Repo.get_by(username: username)
                password = params["password"]
                valid_pass = User.valid_password(password)

                if !valid_pass do
                  ApiResponses.error(conn, :unprocessable_entity, "Password is invalid")
                else
                  changeset = User.changeset(user_entry, %{password: password, reset_token: nil})
                  successful = Repo.update(changeset)

                  case successful do
                    {:ok, _schema} ->
                      ApiResponses.ok(conn)

                    {:error, changeset} ->
                      ApiResponses.changeset_error(conn, changeset)
                  end
                end
              else
                ApiResponses.error(conn, :forbidden, "Insufficient permission")
              end
            else
              ApiResponses.error(conn, :forbidden, "Insufficient permission")
            end
        end

      true ->
        ApiResponses.error(conn, :bad_request, "No valid options specified")
    end
  end

  def delete(conn, params) do
    case Guardian.get_user(Guardian.token_from_conn(conn)) do
      {:ok, user, anon} ->
        username = params["id"]

        if user == username && !anon do
          query = from(f in Favorites, where: f.user == ^user)
          successful1 = Repo.delete_all(query)
          query = from(p in Permission, where: p.username == ^user)
          successful2 = Repo.delete_all(query)
          query = from r in Room, where: r.owner == ^user, select: %{name: r.name}
          list = Repo.all(query)
          rooms = list |> Enum.map(fn a -> a.name end)
          query = from(f in Favorites, where: f.room in ^rooms)
          successful7 = Repo.delete_all(query)
          query = from(r in Room, where: r.owner == ^user)
          successful3 = Repo.delete_all(query)
          query = from(f in Friends, where: f.friendee == ^user or f.friender == ^user)
          successful4 = Repo.delete_all(query)
          query = from(v in PlaylistVideo, where: v.owner == ^user)
          successful5 = Repo.delete_all(query)
          query = from(p in Playlist, where: p.owner == ^user)
          successful6 = Repo.delete_all(query)
          user_entry = User |> Repo.get_by(username: username)
          successful8 = Repo.delete(user_entry)

          case successful1 && successful2 && successful3 && successful4 && successful5 &&
                 successful6 && successful7 && successful8 do
            {:ok, _schema} ->
              ApiResponses.ok(conn)

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
end
