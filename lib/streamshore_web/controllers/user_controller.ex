defmodule StreamshoreWeb.UserController do
  use StreamshoreWeb, :controller
  alias Streamshore.Repo
  alias Streamshore.User

  def index(conn, params) do
    # TODO: list
    # Show every instance of user, (a list of all the users)
  end

  def create(conn, params) do
    %Streamshore.User{}
    |> User.register_changeset(params)
    |> Repo.insert()
    json(conn, %{success: true})
    # TODO: create user (register)
  end

  def update(conn, params) do
    # TODO: profile edit action
  end

  def delete(conn, params) do
    # TODO: delete user
  end

end
