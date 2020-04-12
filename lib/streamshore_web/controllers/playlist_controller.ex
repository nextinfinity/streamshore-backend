defmodule StreamshoreWeb.PlaylistController do
  use StreamshoreWeb, :controller
  import Ecto.Query, only: [from: 2]
  alias Streamshore.Repo
  alias Streamshore.Playlist
  alias Streamshore.PlaylistVideo

  def index(conn, params) do
    user = params["user_id"]
    query = from p in Playlist, where: p.owner == ^user, select: %{name: p.name}
    list = Repo.all(query)
    json(conn, list)
  end

  def show(_conn, _params) do
    # TODO: show playlist info
  end

  def create(conn, params) do
    name = params["name"]
    owner = params["user_id"]
    if !(Playlist |> Repo.get_by(name: name, owner: owner)) do 
      changeset = Playlist.changeset(%Playlist{}, %{name: name, owner: owner})
      successful = Repo.insert(changeset)

      case successful do
        {:ok, _schema}->
          json(conn, %{success: true})

        {:error, _changeset}->
          json(conn, %{success: false})
      end
    else 
      json(conn, %{success: false, error: "Playlist already exists"})
    end
  end

  def update(conn, params) do
    name = params["name"]
    playlist = params["id"]
    owner = params["user_id"]
    relation = Playlist |> Repo.get_by(name: playlist, owner: owner)
    if relation do 
      changeset = Playlist.changeset(relation, %{name: name, owner: owner})
      successful = Repo.update(changeset)

      case successful do
        {:ok, _schema}->
          json(conn, %{success: true})

        {:error, _changeset}->
          json(conn, %{success: false})
      end
    else 
      json(conn, %{success: false, error: "Playlist doesn't exists"})
    end
  end

  def delete(conn, params) do
    # TODO: delete playlist
    playlist = params["id"]
    owner = params["user_id"]
    query = from(v in PlaylistVideo, where: v.owner == ^owner and v.name == ^playlist)
    successful1 = Repo.delete_all(query)
    relation = Playlist |> Repo.get_by(name: playlist, owner: owner)
    successful2 = Repo.delete(relation)
    case successful1 && successful2 do
      {:ok, _schema}->
        json(conn, %{success: true})

      {:error, _changeset}->
        json(conn, %{success: false})
    end
  end

end
