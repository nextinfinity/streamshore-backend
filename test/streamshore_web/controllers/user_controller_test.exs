defmodule UserControllerTest do
    use StreamshoreWeb.ConnCase

    test "Registering an account", %{conn: conn} do 
        username = "Test Account"
        conn = post(conn, Routes.user_path(conn, :create), %{email: "Email@Test.com", username: username, password: "$Test123"})
        assert json_response(conn, 200) == %{"success" => true, "username" => "Test Account"}
    end

    test "Cannot register duplicate user", %{conn: conn} do
        username = "Test Account"
        conn = post(conn, Routes.user_path(conn, :create), %{email: "Email@Test.com", username: username, password: "$Test123"})
        assert json_response(conn, 200) == %{"success" => true, "username" => "Test Account"}
        conn = post(conn, Routes.user_path(conn, :create), %{email: "Email@Testing.com", username: username, password: "$Test123"})
        assert json_response(conn, 200) == %{"success" => false, "error_msg" => "Username has already been taken"}
    end
end