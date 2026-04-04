defmodule Streamshore.UserTest do
  use Streamshore.DataCase, async: true

  alias Streamshore.User

  test "registration_changeset requires password" do
    changeset = User.registration_changeset(%User{}, %{email: "user@test.com", username: "user"})

    refute changeset.valid?
    assert %{password: ["can't be blank"]} = errors_on(changeset)
  end

  test "registration_changeset validates password format" do
    changeset =
      User.registration_changeset(%User{}, %{
        email: "user@test.com",
        username: "user",
        password: "BadPass"
      })

    refute changeset.valid?
    assert %{password: ["is invalid"]} = errors_on(changeset)
  end

  test "room_changeset does not validate password when it is unchanged" do
    changeset = User.room_changeset(%User{}, %{room: "lobby"})

    assert changeset.valid?
    assert %{} = errors_on(changeset)
  end

  test "admin_changeset only allows admin updates" do
    changeset = User.admin_changeset(%User{}, %{admin: 1, room: "ignored"})

    assert changeset.valid?
    assert changeset.changes == %{admin: 1}
  end
end
