defmodule Streamshore.AccountsTest do
  use Streamshore.DataCase, async: false

  alias Streamshore.Accounts
  alias Streamshore.Favorites
  alias Streamshore.Friends
  alias Streamshore.Permission
  alias Streamshore.Repo
  alias Streamshore.Room
  alias Streamshore.Rooms
  alias Streamshore.User

  setup do
    original_mailer_enabled = Application.get_env(:streamshore, :mailer_enabled)
    original_mailer_from_address = Application.get_env(:streamshore, :mailer_from_address)

    on_exit(fn ->
      Application.put_env(:streamshore, :mailer_enabled, original_mailer_enabled)
      Application.put_env(:streamshore, :mailer_from_address, original_mailer_from_address)
    end)

    :ok
  end

  test "create_user returns the created user" do
    assert {:ok, user, []} =
             Accounts.create_user(%{
               "email" => "created@test.com",
               "username" => "created-user",
               "password" => "$Test123"
             })

    assert user.username == "created-user"
    assert user.email == "created@test.com"
    assert user.password != "$Test123"
    assert Repo.get_by(User, username: "created-user") != nil
  end

  test "create_user stores verify token when mailer is enabled" do
    Application.put_env(:streamshore, :mailer_enabled, true)
    Application.put_env(:streamshore, :mailer_from_address, "noreply@example.com")

    assert {:ok, user, [{:send_verification_email, event_user}]} =
             Accounts.create_user(%{
               "email" => "verify@test.com",
               "username" => "verified-user",
               "password" => "$Test123"
             })

    assert user.verify_token != nil
    assert event_user.username == user.username
    assert event_user.verify_token == user.verify_token
  end

  test "verify_email clears the stored verification token" do
    Application.put_env(:streamshore, :mailer_enabled, true)
    Application.put_env(:streamshore, :mailer_from_address, "noreply@example.com")

    assert {:ok, _user, _events} =
             Accounts.create_user(%{
               "email" => "verify@test.com",
               "username" => "verified-user",
               "password" => "$Test123"
             })

    user = Repo.get_by!(User, username: "verified-user")

    assert {:ok, verified_user} = Accounts.verify_email("verified-user", user.verify_token)
    assert verified_user.verify_token == nil
    assert Repo.get_by!(User, username: "verified-user").verify_token == nil
  end

  test "resend_verification_email returns ok for unverified user" do
    Application.put_env(:streamshore, :mailer_enabled, true)
    Application.put_env(:streamshore, :mailer_from_address, "noreply@example.com")

    assert {:ok, _user, _events} =
             Accounts.create_user(%{
               "email" => "verify@test.com",
               "username" => "verified-user",
               "password" => "$Test123"
             })

    assert {:ok, resent_user, [{:send_verification_email, event_user}]} =
             Accounts.resend_verification_email("verified-user")

    assert resent_user.verify_token != nil
    assert event_user.username == resent_user.username
  end

  test "resend_verification_email returns already_verified for verified user" do
    assert {:ok, _user, _events} =
             Accounts.create_user(%{
               "email" => "verified@test.com",
               "username" => "already-verified",
               "password" => "$Test123"
             })

    assert {:error, :already_verified} = Accounts.resend_verification_email("already-verified")
  end

  test "store_reset_token saves a reset token for the user" do
    assert {:ok, _user, _events} =
             Accounts.create_user(%{
               "email" => "reset@test.com",
               "username" => "reset-user",
               "password" => "$Test123"
             })

    assert {:ok, updated_user, [{:send_password_reset_email, event_user, token}]} =
             Accounts.store_reset_token("reset@test.com")

    assert updated_user.reset_token != nil
    assert Repo.get_by!(User, username: "reset-user").reset_token != nil
    assert event_user.username == updated_user.username
    assert token == updated_user.reset_token
  end

  test "update_password hashes the new password and clears reset token" do
    assert {:ok, _user, _events} =
             Accounts.create_user(%{
               "email" => "password@test.com",
               "username" => "password-user",
               "password" => "$Test123"
             })

    assert {:ok, _user, _events} = Accounts.store_reset_token("password@test.com")
    assert {:ok, updated_user} = Accounts.update_password("password-user", "$NewPass123")

    assert updated_user.password != "$NewPass123"
    assert updated_user.reset_token == nil
    assert Repo.get_by!(User, username: "password-user").reset_token == nil
  end

  test "delete_user removes owned room references" do
    assert {:ok, _user, _events} =
             Accounts.create_user(%{
               "email" => "owner@test.com",
               "username" => "owner-user",
               "password" => "$Test123"
             })

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

    assert {:ok, _deleted_user, [{:room_deleted, "owned-room"}]} =
             Accounts.delete_user("owner-user")

    assert Repo.get_by(User, username: "owner-user") == nil
    assert Repo.get_by(Room, route: room.route) == nil
    assert Repo.get_by(Favorites, room: room.route) == nil
    assert Repo.get_by(Permission, room: room.route) == nil
  end

  test "create_favorite stores the room route for the user" do
    assert {:ok, _room} =
             Rooms.create_room("owner-user", %{
               "name" => "Owned Room",
               "motd" => "",
               "privacy" => 0
             })

    assert {:ok, favorite} = Accounts.create_favorite("user-one", "Owned Room")
    assert favorite.room == "owned-room"
    assert Accounts.favorite?("user-one", "owned-room")
  end

  test "create_favorite returns room_not_found when the room is missing" do
    assert {:error, :room_not_found} = Accounts.create_favorite("user-one", "Missing Room")
  end

  test "list_favorite_rooms returns room summaries for a user" do
    assert {:ok, room} =
             Rooms.create_room("owner-user", %{
               "name" => "Owned Room",
               "motd" => "",
               "privacy" => 0
             })

    Repo.insert!(Favorites.changeset(%Favorites{}, %{user: "user-one", room: room.route}))

    [room_summary] = Accounts.list_favorite_rooms("user-one")
    assert room_summary.name == "Owned Room"
    assert room_summary.route == "owned-room"
    assert room_summary.owner == "owner-user"
  end

  test "delete_favorite removes an existing favorite without a preload lookup" do
    assert {:ok, room} =
             Rooms.create_room("owner-user", %{
               "name" => "Owned Room",
               "motd" => "",
               "privacy" => 0
             })

    Repo.insert!(Favorites.changeset(%Favorites{}, %{user: "user-one", room: room.route}))

    assert {:ok, :deleted} = Accounts.delete_favorite("user-one", "Owned Room")
    assert Repo.get_by(Favorites, user: "user-one", room: room.route) == nil
  end

  test "delete_favorite returns not_found when the favorite does not exist" do
    assert {:error, :not_found} = Accounts.delete_favorite("user-one", "Missing Room")
  end

  test "update_friendship accepts a request and creates the reciprocal friendship" do
    Repo.insert!(
      User.registration_changeset(%User{}, %{
        email: "one@test.com",
        username: "one",
        password: "$Test123"
      })
    )

    Repo.insert!(
      User.registration_changeset(%User{}, %{
        email: "two@test.com",
        username: "two",
        password: "$Test123"
      })
    )

    assert {:ok, _request} = Accounts.create_friend_request("one", "two")

    assert {:ok, accepted_friendship} =
             Accounts.update_friendship("two", "one", %{"accepted" => "1"})

    assert accepted_friendship.accepted == 1
    assert Repo.get_by(Friends, friender: "one", friendee: "two", accepted: 1) != nil
    assert Repo.get_by(Friends, friender: "two", friendee: "one", accepted: 1) != nil
  end

  test "update_friendship accepts integer accepted values after normalization" do
    Repo.insert!(
      User.registration_changeset(%User{}, %{
        email: "one@test.com",
        username: "one",
        password: "$Test123"
      })
    )

    Repo.insert!(
      User.registration_changeset(%User{}, %{
        email: "two@test.com",
        username: "two",
        password: "$Test123"
      })
    )

    assert {:ok, _request} = Accounts.create_friend_request("one", "two")

    assert {:ok, accepted_friendship} =
             Accounts.update_friendship("two", "one", %{"accepted" => 1})

    assert accepted_friendship.accepted == 1
    assert Repo.get_by(Friends, friender: "one", friendee: "two", accepted: 1) != nil
    assert Repo.get_by(Friends, friender: "two", friendee: "one", accepted: 1) != nil
  end

  test "delete_friendship removes both sides when present" do
    Repo.insert!(Friends.changeset(%Friends{}, %{friender: "one", friendee: "two", accepted: 1}))
    Repo.insert!(Friends.changeset(%Friends{}, %{friender: "two", friendee: "one", accepted: 1}))

    assert :ok = Accounts.delete_friendship("one", "two")
    assert Repo.get_by(Friends, friender: "one", friendee: "two") == nil
    assert Repo.get_by(Friends, friender: "two", friendee: "one") == nil
  end
end
