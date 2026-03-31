defmodule Streamshore.Accounts do
  import Ecto.Query

  alias Streamshore.Repo
  alias Streamshore.User

  def admin?(user) do
    Repo.one(from u in User, where: u.username == ^user, select: u.admin) == 1
  end

  def get_by_email_or_username(id) do
    case Repo.get_by(User, email: id) do
      nil -> Repo.get_by(User, username: id)
      user -> user
    end
  end

  def set_room(user, room) do
    case Repo.get_by(User, username: user) do
      nil ->
        nil

      schema ->
        schema
        |> User.changeset(%{room: room})
        |> Repo.update()
    end
  end
end
