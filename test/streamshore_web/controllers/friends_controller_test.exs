defmodule FriendsControllerTest do
    use StreamshoreWeb.ConnCase

    test "Creating friend connection", %{conn: conn} do
        friender = "Tester1"
        friendee = "Tester2"
        # insert users into database
        conn = post(conn, Routes.user_path(conn, :create), %{email: "Test@Test.com", username: friender, password: "$Test123"})
        assert json_response(conn, 200) == %{"success" => true, "username" => "Tester1"}
        conn = post(conn, Routes.user_path(conn, :create), %{email: "Test@Tester.com", username: friendee, password: "$Test123"})
        assert json_response(conn, 200) == %{"success" => true, "username" => "Tester2"}
        # send friend request
        conn = post(conn, Routes.user_friend_path(conn, :create, friender), %{friendee: friendee})
        assert json_response(conn, 200) == %{"success" => true}
        #accept friend request
        conn = put(conn, Routes.user_friend_path(conn, :update, friendee, friender), %{accepted: "1"})
        assert json_response(conn, 200) == %{"success" => true}
    end

    test "No existing user", %{conn: conn} do
        friender = "Tester1"
        friendee = "Tester2"
        # insert users into database
        conn = post(conn, Routes.user_path(conn, :create), %{email: "Test@Test.com", username: friender, password: "$Test123"})
        assert json_response(conn, 200) == %{"success" => true, "username" => "Tester1"}
        # send friend request
        conn = post(conn, Routes.user_friend_path(conn, :create, friender), %{friendee: friendee})
        assert json_response(conn, 200) == %{"success" => false, "error" => "User does not exist"}
    end

    test "Getting a list of friends", %{conn: conn} do
        
    end

    test "Users cannot see other users friends", %{conn: conn} do
        
    end

    test "Getting a list of nicknames", %{conn: conn} do
        
    end
end