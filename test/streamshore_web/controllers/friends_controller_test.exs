defmodule FriendsControllerTest do
  use StreamshoreWeb.ConnCase

  alias Streamshore.Guardian

  setup %{conn: conn} do
    {:ok, token, _claims} = Guardian.encode_and_sign("Tester1", %{anon: false})

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
      post(conn, Routes.user_path(conn, :create), %{
        email: "Test@Test.com",
        username: friender,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "Test@Tester.com",
        username: friendee,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}
    # send friend request
    conn = post(conn, Routes.user_friend_path(conn, :create, friender), %{friendee: friendee})
    assert json_response(conn, 200) == %{}
    # accept friend request
    conn = put(conn, Routes.user_friend_path(conn, :update, friendee, friender), %{accepted: "1"})
    assert json_response(conn, 200) == %{}
  end

  test "No existing user", %{conn: conn} do
    friender = "Tester1"
    friendee = "Tester2"
    # insert users into database
    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "Test@Test.com",
        username: friender,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}
    # send friend request
    conn = post(conn, Routes.user_friend_path(conn, :create, friender), %{friendee: friendee})
    assert json_response(conn, 200) == %{"error" => "User does not exist"}
  end

  test "Getting a list of friends", %{conn: conn} do
    friender = "Tester1"
    friendee = "Tester2"
    # insert users into database
    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "Test@Test.com",
        username: friender,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "Test@Tester.com",
        username: friendee,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}
    # send friend request
    conn = post(conn, Routes.user_friend_path(conn, :create, friender), %{friendee: friendee})
    assert json_response(conn, 200) == %{}
    # accept friend request
    conn = put(conn, Routes.user_friend_path(conn, :update, friendee, friender), %{accepted: "1"})
    assert json_response(conn, 200) == %{}
    # get list of friends
    conn = get(conn, Routes.user_friend_path(conn, :index, friender))

    assert json_response(conn, 200) == %{
             "friends" => [%{"friendee" => "Tester2", "nickname" => nil}],
             "requests" => []
           }
  end

  test "Users cannot see other users friends", %{conn: conn} do
    friender = "Tester1"
    friendee = "Tester2"
    tester3 = "Tester3"
    # insert users into database
    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "Test@Test.com",
        username: friender,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "Test@Tester.com",
        username: friendee,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "Test@Testing.com",
        username: tester3,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}
    # send friend request
    conn = post(conn, Routes.user_friend_path(conn, :create, friender), %{friendee: friendee})
    assert json_response(conn, 200) == %{}
    # accept friend request
    conn = put(conn, Routes.user_friend_path(conn, :update, friendee, friender), %{accepted: "1"})
    assert json_response(conn, 200) == %{}
    # get friends of 3rd user
    conn = get(conn, Routes.user_friend_path(conn, :index, tester3))
    assert json_response(conn, 200) == %{"friends" => [], "requests" => []}
  end

  test "Getting a list of nicknames", %{conn: conn} do
    friender = "Tester1"
    friendee = "Tester2"
    # insert users into database
    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "Test@Test.com",
        username: friender,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "Test@Tester.com",
        username: friendee,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}
    # send friend request
    conn = post(conn, Routes.user_friend_path(conn, :create, friender), %{friendee: friendee})
    assert json_response(conn, 200) == %{}
    # accept friend request
    conn = put(conn, Routes.user_friend_path(conn, :update, friendee, friender), %{accepted: "1"})
    assert json_response(conn, 200) == %{}
    # set nickname
    conn =
      put(conn, Routes.user_friend_path(conn, :update, friender, friendee), %{
        nickname: "Test Nickname"
      })

    assert json_response(conn, 200) == %{}
    # get list of friends
    conn = get(conn, Routes.user_friend_path(conn, :index, friender))

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
      post(conn, Routes.user_path(conn, :create), %{
        email: "Test@Test.com",
        username: friender,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "Test@Tester.com",
        username: friendee,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}
    # send friend request
    conn = post(conn, Routes.user_friend_path(conn, :create, friender), %{friendee: friendee})
    assert json_response(conn, 200) == %{}
    # accept friend request
    conn = put(conn, Routes.user_friend_path(conn, :update, friendee, friender), %{accepted: "1"})
    assert json_response(conn, 200) == %{}
    # set nickname
    conn =
      put(conn, Routes.user_friend_path(conn, :update, friender, friendee), %{
        nickname: "Test Nickname"
      })

    assert json_response(conn, 200) == %{}
    # update nickname
    conn =
      put(conn, Routes.user_friend_path(conn, :update, friender, friendee), %{
        nickname: "Replaced Nickname"
      })

    assert json_response(conn, 200) == %{}
    # get list of friends
    conn = get(conn, Routes.user_friend_path(conn, :index, friender))

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
      post(conn, Routes.user_path(conn, :create), %{
        email: "Test@Test.com",
        username: friender,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}

    conn =
      post(conn, Routes.user_path(conn, :create), %{
        email: "Test@Tester.com",
        username: friendee,
        password: "$Test123"
      })

    assert json_response(conn, 200) == %{}
    # send friend request
    conn = post(conn, Routes.user_friend_path(conn, :create, friender), %{friendee: friendee})
    assert json_response(conn, 200) == %{}
    # accept friend request
    conn = put(conn, Routes.user_friend_path(conn, :update, friendee, friender), %{accepted: "1"})
    assert json_response(conn, 200) == %{}
    # set nickname
    conn =
      put(conn, Routes.user_friend_path(conn, :update, friender, friendee), %{
        nickname: "Test Nickname"
      })

    assert json_response(conn, 200) == %{}
    # update nickname
    conn = put(conn, Routes.user_friend_path(conn, :update, friender, friendee), %{nickname: ""})
    assert json_response(conn, 200) == %{}
    # get list of friends
    conn = get(conn, Routes.user_friend_path(conn, :index, friender))

    assert json_response(conn, 200) == %{
             "friends" => [%{"friendee" => "Tester2", "nickname" => nil}],
             "requests" => []
           }
  end
end
