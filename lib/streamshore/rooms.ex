defmodule Streamshore.Rooms do
  import Ecto.Query

  alias Ecto.Multi
  alias Streamshore.Favorites
  alias Streamshore.Permission
  alias Streamshore.PermissionLevel
  alias Streamshore.Repo
  alias Streamshore.Room

  def list_rooms do
    room_summary_query()
    |> Repo.all()
  end

  def list_rooms_by_owner(user) do
    room_summary_query()
    |> where([r], r.owner == ^user)
    |> Repo.all()
  end

  def search_rooms(search) do
    route = "%" <> sanitize_route(search) <> "%"

    room_summary_query()
    |> where([r], like(r.route, ^route))
    |> Repo.all()
  end

  def get_room_name(room) do
    Repo.one(from r in Room, where: r.route == ^room, select: r.name)
  end

  def create_room(owner, attrs) do
    attrs =
      attrs
      |> Map.put("route", sanitize_route(attrs["name"]))
      |> Map.put("owner", owner)

    Multi.new()
    |> Multi.insert(:room, Room.changeset(%Room{}, attrs))
    |> Multi.run(:permission, fn _repo, %{room: room} ->
      update_permission_internal(room.route, owner, PermissionLevel.owner())
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{room: room}} -> {:ok, room}
      {:error, :room, changeset, _changes} -> {:error, changeset}
      {:error, :permission, changeset, _changes} -> {:error, changeset}
    end
  end

  def update_room(room, attrs) do
    case Repo.get_by(Room, route: room) do
      nil ->
        {:error, :not_found}

      schema ->
        schema
        |> Room.changeset(Map.delete(attrs, "id"))
        |> Repo.update()
        |> case do
          {:ok, updated_room} ->
            {:ok, updated_room, [room_updated_event(updated_room, attrs)]}

          {:error, changeset} ->
            {:error, changeset}
        end
    end
  end

  def delete_room(room) do
    case room
         |> single_room_scope()
         |> run_room_deletion() do
      {:ok, [room_route], events} ->
        {:ok, room_route, events}

      {:ok, [], _events} ->
        {:error, :not_found}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def delete_rooms_by_owner(owner) do
    owner
    |> owned_rooms_scope()
    |> run_room_deletion()
  end

  def delete_rooms_by_owner_multi(owner) do
    owner
    |> owned_rooms_scope()
    |> delete_rooms_multi()
  end

  def sanitize_route(name) do
    name
    |> String.downcase()
    |> String.replace(" ", "-")
    |> then(&Regex.replace(~r/[^A-Za-z0-9\-]/, &1, ""))
  end

  def exists?(room) do
    Repo.exists?(from r in Room, where: r.route == ^room)
  end

  def list_permissions(room) do
    query =
      from p in Permission,
        where: [room: ^room],
        select: %{user: p.username, permission: p.permission}

    Repo.all(query)
  end

  def get_permission(room, user) do
    case Repo.get_by(Permission, room: room, username: user) do
      nil -> PermissionLevel.user()
      perm -> perm.permission
    end
  end

  def update_permission(room, user, permission) do
    case update_permission_internal(room, user, permission) do
      {:ok, updated_permission} ->
        {:ok, updated_permission,
          [
            {:permission_updated, room,
              %{
                user: user,
                permission: permission
              }}
          ]}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  defp update_permission_internal(room, user, permission) do
    case Repo.get_by(Permission, room: room, username: user) do
      nil -> %Permission{room: room, username: user}
      permission -> permission
    end
    |> Permission.changeset(%{permission: permission})
    |> Repo.insert_or_update()
  end

  def get_room(room) do
    query =
      from r in Room,
        where: r.route == ^room,
        select: %{
          name: r.name,
          motd: r.motd,
          owner: r.owner,
          route: r.route,
          queue_level: r.queue_level,
          anon_queue: r.anon_queue,
          chat_level: r.chat_level,
          anon_chat: r.anon_chat,
          queue_limit: r.queue_limit,
          vote_enable: r.vote_enable
        }

    Repo.one(query)
  end

  def settings(room) do
    query =
      from r in Room,
        where: r.route == ^room,
        select: %{
          motd: r.motd,
          privacy: r.privacy,
          queue_level: r.queue_level,
          anon_queue: r.anon_queue,
          queue_limit: r.queue_limit,
          chat_level: r.chat_level,
          anon_chat: r.anon_chat,
          chat_filter: r.chat_filter,
          vote_enable: r.vote_enable,
          vote_threshold: r.vote_threshold
        }

    Repo.one(query)
  end

  def owner(room) do
    Repo.one(from r in Room, where: r.route == ^room, select: r.owner)
  end

  def queue_perm(room) do
    case Repo.get_by(Room, route: room) do
      nil -> PermissionLevel.user()
      room -> room.queue_level
    end
  end

  def anon_queue?(room) do
    case Repo.get_by(Room, route: room) do
      nil -> false
      room -> room.anon_queue == 1
    end
  end

  def chat_perm(room) do
    case Repo.get_by(Room, route: room) do
      nil -> PermissionLevel.user()
      room -> room.chat_level
    end
  end

  def anon_chat?(room) do
    case Repo.get_by(Room, route: room) do
      nil -> false
      room -> room.anon_chat == 1
    end
  end

  def filter_enabled?(room) do
    case Repo.get_by(Room, route: room) do
      nil -> false
      room -> room.chat_filter == 1
    end
  end

  defp room_summary_query do
    from r in Room,
      select: %{
        name: r.name,
        owner: r.owner,
        route: r.route,
        thumbnail: r.thumbnail,
        privacy: r.privacy
      }
  end

  defp delete_rooms_multi(room_scope) do
    Multi.new()
    |> Multi.run(:room_routes, fn repo, _changes ->
      {:ok, repo.all(from r in room_scope, select: r.route)}
    end)
    |> Multi.run(:room_events, fn _repo, %{room_routes: room_routes} ->
      {:ok, Enum.map(room_routes, &{:room_deleted, &1})}
    end)
    |> Multi.delete_all(:favorites, fn %{room_routes: room_routes} ->
      from(f in Favorites, where: f.room in ^room_routes)
    end)
    |> Multi.delete_all(:permissions, fn %{room_routes: room_routes} ->
      from(p in Permission, where: p.room in ^room_routes)
    end)
    |> Multi.delete_all(:rooms, fn %{room_routes: room_routes} ->
      from(r in Room, where: r.route in ^room_routes)
    end)
  end

  defp run_room_deletion(room_scope) do
    room_scope
    |> delete_rooms_multi()
    |> Repo.transaction()
    |> case do
      {:ok, %{room_routes: room_routes, room_events: room_events}} ->
        {:ok, room_routes, room_events}

      {:error, _step, changeset, _changes} ->
        {:error, changeset}
    end
  end

  defp owned_rooms_scope(owner) do
    from(r in Room, where: r.owner == ^owner)
  end

  defp single_room_scope(room) do
    from(r in Room, where: r.route == ^room)
  end

  defp room_updated_event(room, attrs) do
    {:room_updated, room.route,
     Map.take(attrs, [
       "motd",
       "queue_level",
       "anon_queue",
       "queue_limit",
       "chat_level",
       "anon_chat",
       "vote_enable"
     ])}
  end
end
