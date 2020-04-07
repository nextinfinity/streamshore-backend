defmodule StreamshoreWeb.ConnectionUtil do
  @moduledoc false

  def get_token(conn) do
    {_, "Bearer " <> token} = Enum.find(conn.req_headers, fn {key, value} -> key == "authorization" end)
    token
  end
end
