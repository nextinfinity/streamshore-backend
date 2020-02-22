defmodule StreamshoreWeb.PageController do
  use StreamshoreWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
