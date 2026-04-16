defmodule FriendsControllerTest do
  use StreamshoreWeb.ConnCase

  alias Streamshore.AuthTokens

  defp authorized_conn(username) do
    token = AuthTokens.create_session_token(username, false)

    build_conn()
    |> put_req_header("authorization", "Bearer " <> token)
  end

  setup %{conn: conn} do
    token = AuthTokens.create_session_token("Tester1", false)

    conn =
      conn
      |> put_req_header("authorization", "Bearer " <> token)

    {:ok, conn: conn}
  end

  test "Creating friend connection", %{conn: conn} do
    friender = "Tester1"
    friendee = "Tester2"
    # insert users into database
    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: "Test@Test.com",
        username: friender,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: "Test@Tester.com",
        username: friendee,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}
    # send friend request
    conn = post(conn, Routes.account_friend_path(conn, :create), %{friendee: friendee})
    assert json_response(conn, 200) == %{}

    conn2 = authorized_conn(friendee)
    # accept friend request
    conn2 =
      put(conn2, Routes.account_friend_path(conn2, :update, friender), %{accepted: "1"})

    assert json_response(conn2, 200) == %{}
  end

  test "No existing user", %{conn: conn} do
    friender = "Tester1"
    friendee = "Tester2"
    # insert users into database
    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: "Test@Test.com",
        username: friender,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}
    # send friend request
    conn = post(conn, Routes.account_friend_path(conn, :create), %{friendee: friendee})
    assert json_response(conn, 404) == %{"error" => "User does not exist"}
  end

  test "Getting a list of friends", %{conn: conn} do
    friender = "Tester1"
    friendee = "Tester2"
    # insert users into database
    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: "Test@Test.com",
        username: friender,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: "Test@Tester.com",
        username: friendee,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}
    # send friend request
    conn = post(conn, Routes.account_friend_path(conn, :create), %{friendee: friendee})
    assert json_response(conn, 200) == %{}
    conn2 = authorized_conn(friendee)
    # accept friend request
    conn2 =
      put(conn2, Routes.account_friend_path(conn2, :update, friender), %{accepted: "1"})

    assert json_response(conn2, 200) == %{}
    # get list of friends
    conn = get(conn, Routes.account_friend_path(conn, :index))

    assert json_response(conn, 200) == %{
             "friends" => [%{"friendee" => "Tester2", "nickname" => nil}],
             "requests" => []
           }
  end

  test "users can only see their own friends list through the account route", %{conn: conn} do
    friender = "Tester1"
    friendee = "Tester2"
    tester3 = "Tester3"
    # insert users into database
    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: "Test@Test.com",
        username: friender,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: "Test@Tester.com",
        username: friendee,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: "Test@Testing.com",
        username: tester3,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}
    # send friend request
    conn = post(conn, Routes.account_friend_path(conn, :create), %{friendee: friendee})
    assert json_response(conn, 200) == %{}
    conn2 = authorized_conn(friendee)
    # accept friend request
    conn2 =
      put(conn2, Routes.account_friend_path(conn2, :update, friender), %{accepted: "1"})

    assert json_response(conn2, 200) == %{}
    # get friends of 3rd user
    conn = get(conn, Routes.account_friend_path(conn, :index))
    assert json_response(conn, 200)["friends"] == [%{"friendee" => "Tester2", "nickname" => nil}]
  end

  test "Getting a list of nicknames", %{conn: conn} do
    friender = "Tester1"
    friendee = "Tester2"
    # insert users into database
    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: "Test@Test.com",
        username: friender,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: "Test@Tester.com",
        username: friendee,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}
    # send friend request
    conn = post(conn, Routes.account_friend_path(conn, :create), %{friendee: friendee})
    assert json_response(conn, 200) == %{}
    conn2 = authorized_conn(friendee)
    # accept friend request
    conn2 =
      put(conn2, Routes.account_friend_path(conn2, :update, friender), %{accepted: "1"})

    assert json_response(conn2, 200) == %{}
    # set nickname
    conn =
      put(conn, Routes.account_friend_path(conn, :update, friendee), %{
        nickname: "Test Nickname"
      })

    assert json_response(conn, 200) == %{}
    # get list of friends
    conn = get(conn, Routes.account_friend_path(conn, :index))

    assert json_response(conn, 200) == %{
             "friends" => [%{"friendee" => "Tester2", "nickname" => "Test Nickname"}],
             "requests" => []
           }
  end

  test "Can update nickname", %{conn: conn} do
    friender = "Tester1"
    friendee = "Tester2"
    # insert users into database
    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: "Test@Test.com",
        username: friender,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: "Test@Tester.com",
        username: friendee,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}
    # send friend request
    conn = post(conn, Routes.account_friend_path(conn, :create), %{friendee: friendee})
    assert json_response(conn, 200) == %{}
    conn2 = authorized_conn(friendee)
    # accept friend request
    conn2 =
      put(conn2, Routes.account_friend_path(conn2, :update, friender), %{accepted: "1"})

    assert json_response(conn2, 200) == %{}
    # set nickname
    conn =
      put(conn, Routes.account_friend_path(conn, :update, friendee), %{
        nickname: "Test Nickname"
      })

    assert json_response(conn, 200) == %{}
    # update nickname
    conn =
      put(conn, Routes.account_friend_path(conn, :update, friendee), %{
        nickname: "Replaced Nickname"
      })

    assert json_response(conn, 200) == %{}
    # get list of friends
    conn = get(conn, Routes.account_friend_path(conn, :index))

    assert json_response(conn, 200) == %{
             "friends" => [%{"friendee" => "Tester2", "nickname" => "Replaced Nickname"}],
             "requests" => []
           }
  end

  test "Removing a nickname", %{conn: conn} do
    friender = "Tester1"
    friendee = "Tester2"
    # insert users into database
    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: "Test@Test.com",
        username: friender,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: "Test@Tester.com",
        username: friendee,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}
    # send friend request
    conn = post(conn, Routes.account_friend_path(conn, :create), %{friendee: friendee})
    assert json_response(conn, 200) == %{}
    conn2 = authorized_conn(friendee)
    # accept friend request
    conn2 =
      put(conn2, Routes.account_friend_path(conn2, :update, friender), %{accepted: "1"})

    assert json_response(conn2, 200) == %{}
    # set nickname
    conn =
      put(conn, Routes.account_friend_path(conn, :update, friendee), %{
        nickname: "Test Nickname"
      })

    assert json_response(conn, 200) == %{}
    # update nickname
    conn = put(conn, Routes.account_friend_path(conn, :update, friendee), %{nickname: ""})
    assert json_response(conn, 200) == %{}
    # get list of friends
    conn = get(conn, Routes.account_friend_path(conn, :index))

    assert json_response(conn, 200) == %{
             "friends" => [%{"friendee" => "Tester2", "nickname" => nil}],
             "requests" => []
           }
  end

  test "authenticated users can create friend requests from their own account", %{conn: conn} do
    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: "owner@test.com",
        username: "Tester2",
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    conn = post(conn, Routes.account_friend_path(conn, :create), %{friendee: "Tester2"})
    assert json_response(conn, 200) == %{}
  end

  test "Creating a duplicate friend request returns conflict", %{conn: conn} do
    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: "test1@test.com",
        username: "Tester1",
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    conn =
      post(conn, Routes.account_path(conn, :create), %{
        email: "test2@test.com",
        username: "Tester2",
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    conn = post(conn, Routes.account_friend_path(conn, :create), %{friendee: "Tester2"})
    assert json_response(conn, 200) == %{}

    conn = post(conn, Routes.account_friend_path(conn, :create), %{friendee: "Tester2"})
    assert json_response(conn, 409) == %{"error" => "Friend connection already exists"}
  end
end
