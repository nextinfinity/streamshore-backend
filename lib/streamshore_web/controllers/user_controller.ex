defmodule StreamshoreWeb.UserController do
  use StreamshoreWeb, :controller
  alias Streamshore.Repo
  alias Streamshore.User

  def index(conn, _params) do
    # TODO: list

  end

  def edit(conn, _params) do
    # TODO: edit user (precursor to update)
  end

  def new(conn, _params) do
    # TODO: new user (precursor to create)
  end

  def show(conn, _params) do
    # TODO: show user info
  end

  def create(conn, params) do
    
    %Streamshore.User{}
    |> User.register_changeset(params)
    |> Repo.insert()
    # TODO: create user (register)
  end

  def update(conn, _params) do
    # TODO: profile edit action
  end

  def delete(conn, _params) do
    # TODO: delete user
  end

end
