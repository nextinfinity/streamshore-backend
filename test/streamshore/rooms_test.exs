defmodule Streamshore.RoomsTest do
  use Streamshore.DataCase, async: false

  alias Streamshore.Favorites
  alias Streamshore.Permission
  alias Streamshore.Repo
  alias Streamshore.Room
  alias Streamshore.RoomPermissions
  alias Streamshore.Rooms

  test "create_room creates the room and owner permission" do
    assert {:ok, room} =
             Rooms.create_room("owner-user", %{
               "name" => "Owned Room",
               "motd" => "",
               "privacy" => 0
             })

    assert room.route == "owned-room"
    assert room.owner == "owner-user"
    assert Repo.get_by(Room, route: "owned-room") != nil
    assert RoomPermissions.get_perm("owned-room", "owner-user") == 100
  end

  test "create_room returns changeset error for duplicate room" do
    assert {:ok, _room} =
             Rooms.create_room("owner-user", %{
               "name" => "Owned Room",
               "motd" => "",
               "privacy" => 0
             })

    assert {:error, changeset} =
             Rooms.create_room("owner-user", %{
               "name" => "Owned Room",
               "motd" => "",
               "privacy" => 0
             })

    assert %{name: ["Room name has already been taken"]} = errors_on(changeset)
  end

  test "update_room persists room changes" do
    assert {:ok, _room} =
             Rooms.create_room("owner-user", %{
               "name" => "Owned Room",
               "motd" => "",
               "privacy" => 0
             })

    assert {:ok, updated_room, [{:room_updated, "owned-room", %{"motd" => "Updated"}}]} =
             Rooms.update_room("owned-room", %{"motd" => "Updated"})

    assert updated_room.motd == "Updated"
    assert Repo.get_by!(Room, route: "owned-room").motd == "Updated"
  end

  test "delete_owned_room removes favorites and permissions" do
    assert {:ok, room} =
             Rooms.create_room("owner-user", %{
               "name" => "Owned Room",
               "motd" => "",
               "privacy" => 0
             })

    Repo.insert!(Favorites.changeset(%Favorites{}, %{user: "friend", room: room.route}))

    Repo.insert!(
      Permission.changeset(%Permission{}, %{
        username: "friend",
        room: room.route,
        permission: 50
      })
    )

    assert {:ok, _room, [{:room_deleted, "owned-room"}]} =
             Rooms.delete_owned_room(room.route, "owner-user")

    assert Repo.get_by(Room, route: room.route) == nil
    assert Repo.get_by(Favorites, room: room.route) == nil
    assert Repo.get_by(Permission, room: room.route) == nil
  end

  test "delete_rooms_by_owner removes favorites and permissions for all owned rooms" do
    assert {:ok, room_one} =
             Rooms.create_room("owner-user", %{
               "name" => "Owned Room One",
               "motd" => "",
               "privacy" => 0
             })

    assert {:ok, room_two} =
             Rooms.create_room("owner-user", %{
               "name" => "Owned Room Two",
               "motd" => "",
               "privacy" => 0
             })

    for room <- [room_one, room_two] do
      Repo.insert!(Favorites.changeset(%Favorites{}, %{user: "friend", room: room.route}))

      Repo.insert!(
        Permission.changeset(%Permission{}, %{
          username: "friend",
          room: room.route,
          permission: 50
        })
      )
    end

    assert {:ok, ["owned-room-one", "owned-room-two"], room_events} =
             Rooms.delete_rooms_by_owner("owner-user")

    assert Enum.sort(room_events) == [
             {:room_deleted, "owned-room-one"},
             {:room_deleted, "owned-room-two"}
           ]

    assert Repo.get_by(Room, route: room_one.route) == nil
    assert Repo.get_by(Room, route: room_two.route) == nil
    assert Repo.get_by(Favorites, room: room_one.route) == nil
    assert Repo.get_by(Favorites, room: room_two.route) == nil
    assert Repo.get_by(Permission, room: room_one.route) == nil
    assert Repo.get_by(Permission, room: room_two.route) == nil
  end

  test "delete_owned_room returns forbidden for non-owner" do
    assert {:ok, room} =
             Rooms.create_room("owner-user", %{
               "name" => "Owned Room",
               "motd" => "",
               "privacy" => 0
             })

    assert {:error, :forbidden} = Rooms.delete_owned_room(room.route, "other-user")
  end
end
