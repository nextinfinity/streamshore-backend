defmodule PermissionControllerTest do
  use StreamshoreWeb.ConnCase
  import Phoenix.ChannelTest
  alias Streamshore.PermissionLevel

  test "default permission", %{conn: conn} do
    perm = conn
           |> get(Routes.room_permission_path(conn, :show, "default-room", "default-user"))
           |> json_response(200)
    assert perm == PermissionLevel.user()
  end

  test "set permission", %{conn: conn} do
    conn
    |> put(Routes.room_permission_path(conn, :show, "set-room", "set-user"), %{permission: PermissionLevel.owner()})
    perm = conn
           |> get(Routes.room_permission_path(conn, :show, "set-room", "set-user"))
           |> json_response(200)
    assert perm == PermissionLevel.owner()
  end

  test "ban permission", %{conn: conn} do
    conn
    |> put(Routes.room_permission_path(conn, :show, "ban-room", "ban-user"), %{permission: PermissionLevel.banned()})
    perm = conn
           |> get(Routes.room_permission_path(conn, :show, "ban-room", "ban-user"))
           |> json_response(200)
    assert perm == PermissionLevel.banned()
  end

  test "banned user can't join", %{conn: conn} do
    conn
    |> put(Routes.room_permission_path(conn, :show, "ban-room2", "ban-user"), %{permission: PermissionLevel.banned()})
    perm = conn
           |> get(Routes.room_permission_path(conn, :show, "ban-room2", "ban-user"))
           |> json_response(200)
    assert perm == PermissionLevel.banned()
    connection = socket(StreamshoreWeb.UserSocket, "ban-user", %{user: "ban-user", anon: true})
                 |> subscribe_and_join(StreamshoreWeb.RoomChannel, "room:ban-room2")
    assert connection == {:error, %{reason: "unauthorized"}}
  end

end
