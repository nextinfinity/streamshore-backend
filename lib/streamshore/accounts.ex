defmodule Streamshore.Accounts do
  import Ecto.Query

  alias Ecto.Multi
  alias Streamshore.AuthTokens
  alias Streamshore.Favorites
  alias Streamshore.Friends
  alias Streamshore.Mailer
  alias Streamshore.Permission
  alias Streamshore.Playlist
  alias Streamshore.PlaylistVideo
  alias Streamshore.Repo
  alias Streamshore.Rooms
  alias Streamshore.User

  def admin?(user) do
    Repo.one(from u in User, where: u.username == ^user, select: u.admin) == 1
  end

  def list_users do
    Repo.all(
      from u in User,
        select: %{
          username: u.username,
          email: u.email,
          room: u.room,
          admin: u.admin,
          verify_token: u.verify_token
        }
    )
  end

  def create_user(params) do
    params =
      if Mailer.enabled?() do
        verify_token = AuthTokens.create_token("Verify-" <> params["username"], false)
        Map.put(params, "verify_token", verify_token)
      else
        params
      end

    %User{}
    |> User.registration_changeset(params)
    |> Repo.insert()
    |> case do
      {:ok, user} ->
        events =
          if Mailer.enabled?() do
            [{:send_verification_email, user}]
          else
            []
          end

        {:ok, user, events}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def resend_verification_email(id) do
    case get_by_email_or_username(id) do
      nil ->
        {:error, :not_found}

      %User{verify_token: nil} ->
        {:error, :already_verified}

      %User{} = user ->
        {:ok, user, [{:send_verification_email, user}]}
    end
  end

  def get_public_user(username) do
    Repo.one(
      from u in User,
        where: [username: ^username],
        select: %{username: u.username, room: u.room}
    )
  end

  def get_by_email_or_username(id) do
    case Repo.get_by(User, email: id) do
      nil -> Repo.get_by(User, username: id)
      user -> user
    end
  end

  def get_by_email(email) do
    Repo.get_by(User, email: email)
  end

  def set_admin(username, admin) do
    update_user(username, &User.admin_changeset(&1, %{admin: admin}))
  end

  def verify_email(username, token) do
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

  def store_reset_token(email) do
    case get_by_email(email) do
      nil ->
        {:error, :not_found}

      user ->
        token = AuthTokens.create_token("Reset-" <> user.username, false)

        case update_user(user.username, &User.reset_token_changeset(&1, %{reset_token: token})) do
          {:ok, updated_user} ->
            {:ok, updated_user, [{:send_password_reset_email, updated_user, token}]}

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  def update_password(username, password) do
    case Repo.get_by(User, username: username) do
      nil ->
        {:error, :not_found}

      user ->
        user
        |> User.password_changeset(%{password: password})
        |> Repo.update()
    end
  end

  def delete_user(username) do
    case Repo.get_by(User, username: username) do
      nil ->
        {:error, :not_found}

      user ->
        Multi.new()
        |> Multi.delete_all(:favorites_by_user, from(f in Favorites, where: f.user == ^username))
        |> Multi.delete_all(
          :permissions_by_user,
          from(p in Permission, where: p.username == ^username)
        )
        |> Multi.merge(fn _changes -> Rooms.delete_rooms_by_owner_multi(username) end)
        |> Multi.delete_all(
          :friends,
          from(f in Friends, where: f.friendee == ^username or f.friender == ^username)
        )
        |> Multi.delete_all(
          :playlist_videos,
          from(v in PlaylistVideo, where: v.owner == ^username)
        )
        |> Multi.delete_all(:playlists, from(p in Playlist, where: p.owner == ^username))
        |> Multi.delete(:user, user)
        |> Repo.transaction()
        |> case do
          {:ok, %{room_events: room_events, user: deleted_user}} ->
            {:ok, deleted_user, room_events}

          {:error, _step, changeset, _changes} ->
            {:error, changeset}
        end
    end
  end

  def set_room(user, room) do
    case Repo.get_by(User, username: user) do
      nil ->
        nil

      schema ->
        schema
        |> User.room_changeset(%{room: room})
        |> Repo.update()
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
end
