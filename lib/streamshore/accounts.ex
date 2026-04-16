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
  alias Streamshore.Room
  alias Streamshore.Rooms
  alias Streamshore.User

  def admin?(user) do
    Repo.one(from u in User, where: u.username == ^user, select: u.admin) == 1
  end

  def list_favorite_rooms(user) do
    Repo.all(
      from f in Favorites,
        join: r in Room,
        on: r.route == f.room,
        where: f.user == ^user,
        select: %{
          name: r.name,
          owner: r.owner,
          route: r.route,
          thumbnail: r.thumbnail,
          privacy: r.privacy
        }
    )
  end

  def favorite?(user, room_identifier) do
    room = normalize_room_identifier(room_identifier)

    Repo.exists?(from f in Favorites, where: f.user == ^user and f.room == ^room)
  end

  def create_favorite(user, room_identifier) do
    room = normalize_room_identifier(room_identifier)

    if Rooms.exists?(room) do
      %Favorites{}
      |> Favorites.changeset(%{user: user, room: room})
      |> Repo.insert()
    else
      {:error, :room_not_found}
    end
  end

  def delete_favorite(user, room_identifier) do
    room = normalize_room_identifier(room_identifier)

    case Repo.delete_all(from f in Favorites, where: f.user == ^user and f.room == ^room) do
      {0, _} -> {:error, :not_found}
      {_count, _} -> {:ok, :deleted}
    end
  end

  def list_friendships(user) do
    friends =
      Repo.all(
        from f in Friends,
          where: f.friender == ^user and f.accepted == 1,
          select: %{friendee: f.friendee, nickname: f.nickname}
      )

    requests =
      Repo.all(
        from f in Friends,
          where: f.friender == ^user and f.accepted == 0,
          select: %{friendee: f.friendee, nickname: f.nickname}
      )

    %{friends: friends, requests: requests}
  end

  def create_friend_request(friender, friendee) do
    cond do
      Repo.get_by(User, username: friendee) == nil ->
        {:error, :user_not_found}

      friendship_exists?(friender, friendee) ->
        {:error, :already_exists}

      true ->
        %Friends{}
        |> Friends.changeset(%{
          friender: friendee,
          friendee: friender,
          nickname: nil,
          accepted: 0
        })
        |> Repo.insert()
    end
  end

  def update_friendship(friender, friendee, attrs) do
    case Repo.get_by(Friends, friender: friender, friendee: friendee) do
      nil ->
        {:error, :not_found}

      relation ->
        case normalize_accepted_value(Map.get(attrs, "accepted")) do
          nil ->
            relation
            |> Friends.changeset(attrs)
            |> Repo.update()

          "1" ->
            accept_friend_request(relation, friender, friendee)

          _ ->
            Repo.delete(relation)
        end
    end
  end

  def delete_friendship(friender, friendee) do
    Multi.new()
    |> Multi.delete_all(
      :forward_friendship,
      from(f in Friends, where: f.friender == ^friender and f.friendee == ^friendee)
    )
    |> Multi.delete_all(
      :reverse_friendship,
      from(f in Friends, where: f.friender == ^friendee and f.friendee == ^friender)
    )
    |> Repo.transaction()
    |> case do
      {:ok, _changes} -> :ok
      {:error, _step, reason, _changes} -> {:error, reason}
    end
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
        Map.put(params, "verify_token", AuthTokens.create_verify_email_token(params["username"]))
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

  def get_public_user(username) do
    Repo.one(
      from u in User,
        where: [username: ^username],
        select: %{username: u.username, room: u.room}
    )
  end

  def set_admin(username, admin) do
    update_user(username, &User.admin_changeset(&1, %{admin: admin}))
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
    update_user(user, &User.room_changeset(&1, %{room: room}))
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

  defp normalize_room_identifier(room_identifier) when is_binary(room_identifier) do
    Rooms.sanitize_route(room_identifier)
  end

  defp normalize_room_identifier(room_identifier), do: room_identifier

  defp normalize_accepted_value(nil), do: nil
  defp normalize_accepted_value(value) when is_binary(value), do: value
  defp normalize_accepted_value(value) when is_integer(value), do: Integer.to_string(value)

  defp friendship_exists?(friender, friendee) do
    Repo.exists?(
      from f in Friends,
        where:
          (f.friender == ^friender and f.friendee == ^friendee) or
            (f.friender == ^friendee and f.friendee == ^friender)
    )
  end

  defp accept_friend_request(relation, friender, friendee) do
    reciprocal_relation =
      Repo.get_by(Friends, friender: friendee, friendee: friender) ||
        %Friends{friender: friendee, friendee: friender}

    Multi.new()
    |> Multi.update(:friend_request, Friends.changeset(relation, %{accepted: 1}))
    |> Multi.insert_or_update(
      :friendship,
      Friends.changeset(reciprocal_relation, %{
        friender: friendee,
        friendee: friender,
        nickname: nil,
        accepted: 1
      })
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{friend_request: friendship}} -> {:ok, friendship}
      {:error, _step, changeset, _changes} -> {:error, changeset}
    end
  end
end
