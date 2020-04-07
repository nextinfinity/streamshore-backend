defmodule UserControllerTest do
    use StreamshoreWeb.ConnCase

    test "Registering an account", %{conn: conn} do 
        username = "Test Account"
        conn = post(conn, Routes.user_path(conn, :create), %{email: "Email@Test.com", username: username, password: "$Test123"})
        assert json_response(conn, 200) == %{"success" => true}
    end

    test "Cannot register duplicate user", %{conn: conn} do
        username = "Test Account"
        conn = post(conn, Routes.user_path(conn, :create), %{email: "Email@Test.com", username: username, password: "$Test123"})
        assert json_response(conn, 200) == %{"success" => true}
        conn = post(conn, Routes.user_path(conn, :create), %{email: "Email@Testing.com", username: username, password: "$Test123"})
        assert json_response(conn, 200) == %{"success" => false, "error_msg" => "Username has already been taken"}
    end

    test "Updating with valid password", %{conn: conn} do
        username = "Test Account"
        conn = post(conn, Routes.user_path(conn, :create), %{email: "Email@Test.com", username: username, password: "$Test123"})
        assert json_response(conn, 200) == %{"success" => true}
        conn = put(conn, Routes.user_path(conn, :update, username), %{password: "$NewPass123"})
        assert json_response(conn, 200) == %{"success" => true}
    end

    test "Updating with invalid password", %{conn: conn} do
        username = "Test Account"
        conn = post(conn, Routes.user_path(conn, :create), %{email: "Email@Test.com", username: username, password: "$Test123"})
        assert json_response(conn, 200) == %{"success" => true}
        conn = put(conn, Routes.user_path(conn, :update, username), %{password: "BadPass"})
        assert json_response(conn, 200) == %{"success" => false, "error" => "password: password is invalid"}
    end
end