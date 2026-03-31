defmodule StreamshoreWeb.ApiResponses do
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  def ok(conn, payload \\ %{}) do
    conn
    |> put_status(:ok)
    |> json(payload)
  end

  def created(conn, payload) do
    conn
    |> put_status(:created)
    |> json(payload)
  end

  def no_content(conn) do
    send_resp(conn, :no_content, "")
  end

  def error(conn, status, message) do
    conn
    |> put_status(status)
    |> json(%{error: message})
  end
end
