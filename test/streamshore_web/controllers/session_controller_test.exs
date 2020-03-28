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
end