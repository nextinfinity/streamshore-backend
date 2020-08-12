defmodule UserControllerTest do
  use StreamshoreWeb.ConnCase

  alias Streamshore.Guardian
  alias Streamshore.Repo

  setup %{conn: conn} do
    {:ok, token, _claims} = Guardian.encode_and_sign("user", %{anon: false, admin: false})

    conn =
      conn
      |> put_req_header("authorization", "Bearer " <> token)

    {:ok, conn: conn}
  end

  test "Registering an account", %{conn: conn} do
    username = "Test Account"

    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "Email@Test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}
  end

  test "Cannot register duplicate user", %{conn: conn} do
    username = "Test Account"

    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "Email@Test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "Email@Testing.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{"error" => "Username has already been taken"}
  end

  test "Updating with valid password", %{conn: conn} do
    username = "user"

    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "Email@Test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    conn = put(conn, Routes.user_path(conn, :update, username), %{password: "$NewPass123"})
    assert json_response(conn, 200) == %{}
  end

  test "Updating with invalid password", %{conn: conn} do
    username = "user"

    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "Email@Test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}
    conn = put(conn, Routes.user_path(conn, :update, username), %{password: "BadPass"})
    assert json_response(conn, 200) == %{"error" => "password: password is invalid"}
  end

  test "Deleting account", %{conn: conn} do
    username = "user"

    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "Email@Test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}
    conn = delete(conn, Routes.user_path(conn, :delete, username))
    assert json_response(conn, 200) == %{}
  end

  test "Deleting account with wrong credentials", %{conn: conn} do
    username = "Not User"

    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "Email@Test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}
    conn = delete(conn, Routes.user_path(conn, :delete, username))
    assert json_response(conn, 200) == %{"error" => "Insufficient permission"}
  end

  test "Getting list of all users as admin", %{conn: conn} do
    username = "Test Account"

    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "Email@Test.com",
        username: username,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    Repo
    |> Ecto.Adapters.SQL.query!(
      "UPDATE `streamshore_test`.`users` SET `admin` = '1' WHERE (`username` = 'Test Account')"
    )

    Repo
    |> Ecto.Adapters.SQL.query!(
      "UPDATE `streamshore_test`.`users` SET `verify_token` = NULL WHERE (`username` = 'Test Account')"
    )

    {:ok, token, _claims} = Guardian.encode_and_sign("Test Account", %{anon: false, admin: true})

    conn2 =
      build_conn()
      |> put_req_header("authorization", "Bearer " <> token)

    conn2 = get(conn2, Routes.user_path(conn2, :index))

    assert json_response(conn2, 200) == [
             %{
               "email" => "Email@Test.com",
               "username" => "Test Account",
               "admin" => 1,
               "room" => nil,
               "verify_token" => nil
             }
           ]
  end

  test "Getting list of all users as non-admin", %{conn: conn} do
    conn = get(conn, Routes.user_path(conn, :index))
    assert json_response(conn, 200) == %{"error" => "Insufficient permission"}
  end
end
