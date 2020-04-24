defmodule SessionControllerTest do
    use StreamshoreWeb.ConnCase

    alias Streamshore.Repo

    test "Getting an anonymous username", %{conn: conn} do
        session = conn
           |> post(Routes.session_path(conn, :create))
           |> json_response(200)
        assert session["user"]
    end
    
    test "Anonymous usernames are different", %{conn: conn} do
        session = conn
           |> post(Routes.session_path(conn, :create))
           |> json_response(200)
        assert session["user"]
        second_session = conn
           |> post(Routes.session_path(conn, :create))
           |> json_response(200)
        assert second_session["user"]
        assert session["user"] != second_session["user"]
    end

    test "Username validation", %{conn: conn} do
        username = "Test Account"
        conn = post(conn, Routes.user_path(conn, :create), %{email: "Email@Test.com", username: username, password: "$Test123"})
        assert json_response(conn, 200) == %{}
        conn = post(conn, Routes.session_path(conn, :create), %{id: "bad", password: "$Test123"})
        assert json_response(conn, 200) == %{"error" => "Invalid credentials"}
    end

    test "Password validation", %{conn: conn} do
        username = "Test Account"
        conn = post(conn, Routes.user_path(conn, :create), %{email: "Email@Test.com", username: username, password: "$Test123"})
        assert json_response(conn, 200) == %{}
        conn = post(conn, Routes.session_path(conn, :create), %{id: "Email@Test.com", password: "bad"})
        assert json_response(conn, 200) == %{"error" => "Invalid credentials"}
    end

    test "Logging in via username", %{conn: conn} do
        username = "Test Account"
        conn = post(conn, Routes.user_path(conn, :create), %{email: "Email@Test.com", username: username, password: "$Test123"})
        assert json_response(conn, 200) == %{}
        Repo |> Ecto.Adapters.SQL.query!("UPDATE `streamshore_test`.`users` SET `verify_token` = NULL WHERE (`username` = 'Test Account')")
        conn = post(conn, Routes.session_path(conn, :create), %{id: "Test Account", password: "$Test123"})
        assert json_response(conn, 200)["user"] == "Test Account"
    end

    test "Attempting to log in with bad username", %{conn: conn} do
        username = "Test Account"
        conn = post(conn, Routes.user_path(conn, :create), %{email: "Email@Test.com", username: username, password: "$Test123"})
        assert json_response(conn, 200) == %{}
        conn = post(conn, Routes.session_path(conn, :create), %{id: "Wrong Username", password: "$Test123"})
        assert json_response(conn, 200) == %{"error" => "Invalid credentials"}
    end
end