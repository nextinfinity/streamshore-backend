defmodule Streamshore.Util do

  def convert_changeset_errors(changeset) do
    out =  Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    out
  end

end
