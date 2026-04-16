defmodule StreamshoreWeb.ApiResponses do
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  alias Streamshore.Util

  def ok(conn, payload \\ %{}) do
    conn
    |> put_status(:ok)
    |> json(payload)
  end

  def accepted(conn, payload \\ %{}) do
    conn
    |> put_status(:accepted)
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

  def changeset_error(conn, changeset) do
    error(conn, infer_changeset_status(changeset), format_changeset_message(changeset))
  end

  defp infer_changeset_status(changeset) do
    if Enum.any?(changeset.errors, fn {_field, {_message, details}} ->
         details[:constraint] == :unique
       end) do
      :conflict
    else
      :unprocessable_entity
    end
  end

  defp format_changeset_message(changeset) do
    errors = Util.convert_changeset_errors(changeset)

    case Map.keys(errors) do
      [key | _rest] ->
        message = Enum.at(errors[key], 0)

        if Regex.match?(~r/^[A-Z]/, message) do
          message
        else
          humanize_field(key) <> " " <> message
        end

      _ ->
        "Request could not be processed"
    end
  end

  defp humanize_field(field) do
    field
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
