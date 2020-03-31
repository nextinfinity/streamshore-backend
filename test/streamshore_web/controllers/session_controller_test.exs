defmodule SessionControllerTest do
    use StreamshoreWeb.ConnCase

    test "Getting an anonymous username", %{conn: conn} do
        name = conn
           |> post(Routes.session_path(conn, :create))
           |> json_response(200)
        assert name["name"]
    end
    
    test "Anonymous usernames are different", %{conn: conn} do
        name = conn
           |> post(Routes.session_path(conn, :create))
           |> json_response(200)
        assert name["name"]
        second_name = conn
           |> post(Routes.session_path(conn, :create))
           |> json_response(200)
        assert second_name["name"]
        assert name["name"] != second_name["name"]
    end

    test "Username validation", %{conn: conn} do
        username = "Test Account"
        conn = post(conn, Routes.user_path(conn, :create), %{email: "Email@Test.com", username: username, password: "$Test123"})
        assert json_response(conn, 200) == %{"success" => true, "username" => "Test Account"}
        conn = post(conn, Routes.session_path(conn, :create), %{email: "bad", password: "$Test123"})
        assert json_response(conn, 200) == %{}
    end

    test "Password validation", %{conn: conn} do
        username = "Test Account"
        conn = post(conn, Routes.user_path(conn, :create), %{email: "Email@Test.com", username: username, password: "$Test123"})
        assert json_response(conn, 200) == %{"success" => true, "username" => "Test Account"}
        conn = post(conn, Routes.session_path(conn, :create), %{email: "Email@Test.com", password: "bad"})
        assert json_response(conn, 200) == %{}
    end
end