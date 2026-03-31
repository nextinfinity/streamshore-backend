defmodule Streamshore.Rooms do
  import Ecto.Query

  alias Streamshore.PermissionLevel
  alias Streamshore.Repo
  alias Streamshore.Room

  def sanitize_route(name) do
    name
    |> String.downcase()
    |> String.replace(" ", "-")
    |> then(&Regex.replace(~r/[^A-Za-z0-9\-]/, &1, ""))
  end

  def exists?(room) do
    Repo.exists?(from r in Room, where: r.route == ^room)
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
end
