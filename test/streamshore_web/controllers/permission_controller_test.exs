defmodule PermissionControllerTest do
  use StreamshoreWeb.ConnCase
  import Phoenix.ChannelTest

  alias Streamshore.Guardian
  alias Streamshore.PermissionLevel

  setup %{conn: conn} do
    {:ok, token, _claims} = Guardian.encode_and_sign("user", %{anon: false, admin: false})

    conn = conn
           |> put_req_header("authorization", "Bearer " <> token)
           |> post(Routes.room_path(conn, :create), %{name: "permissions", motd: "", privacy: 0})
    {:ok, conn: conn}
  end

  test "default permission", %{conn: conn} do
    perm = conn
           |> get(Routes.room_permission_path(conn, :show, "permissions", "default-user"))
           |> json_response(200)
    assert perm == PermissionLevel.user()
  end

  test "set permission", %{conn: conn} do
    conn
    |> put(Routes.room_permission_path(conn, :show, "permissions", "set-user"), %{permission: PermissionLevel.manager()})
    perm = conn
           |> get(Routes.room_permission_path(conn, :show, "permissions", "set-user"))
           |> json_response(200)
    assert perm == PermissionLevel.manager()
  end

  test "ban permission", %{conn: conn} do
    conn
    |> put(Routes.room_permission_path(conn, :show, "permissions", "ban-user"), %{permission: PermissionLevel.banned()})
    perm = conn
           |> get(Routes.room_permission_path(conn, :show, "permissions", "ban-user"))
           |> json_response(200)
    assert perm == PermissionLevel.banned()
  end

  test "banned user can't join", %{conn: conn} do
    conn
    |> put(Routes.room_permission_path(conn, :show, "permissions", "ban-user2"), %{permission: PermissionLevel.banned()})
    perm = conn
           |> get(Routes.room_permission_path(conn, :show, "permissions", "ban-user2"))
           |> json_response(200)
    assert perm == PermissionLevel.banned()
    connection = socket(StreamshoreWeb.UserSocket, "ban-user", %{user: "ban-user2", anon: true})
                 |> subscribe_and_join(StreamshoreWeb.RoomChannel, "room:permissions")
    assert connection == {:error, %{reason: "unauthorized"}}
  end

  test "mute permission", %{conn: conn} do
    conn
    |> put(Routes.room_permission_path(conn, :show, "permissions", "mute-user"), %{permission: PermissionLevel.muted()})
    perm = conn
           |> get(Routes.room_permission_path(conn, :show, "permissions", "mute-user"))
           |> json_response(200)
    assert perm == PermissionLevel.muted()
  end

  test "muted user can't chat", %{conn: conn} do
    conn
    |> put(Routes.room_permission_path(conn, :show, "permissions", "mute-user2"), %{permission: PermissionLevel.muted()})
    perm = conn
           |> get(Routes.room_permission_path(conn, :show, "permissions", "mute-user2"))
           |> json_response(200)
    assert perm == PermissionLevel.muted()
    {:ok, _, connection} = socket(StreamshoreWeb.UserSocket, "mute-user2", %{user: "mute-user2", anon: true})
                 |> subscribe_and_join(StreamshoreWeb.RoomChannel, "room:permissions")
    Phoenix.ChannelTest.push connection, "chat", %{"msg" => "hello world"}
    refute_broadcast "chat", %{"msg" => "hello world"}
  end

end
