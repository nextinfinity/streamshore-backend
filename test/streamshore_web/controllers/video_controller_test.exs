defmodule VideoControllerTest do
  use StreamshoreWeb.ConnCase
  alias Streamshore.QueueManager
  alias Streamshore.Videos

  test "Add invalid video", %{conn: conn} do
    conn = post(conn, Routes.room_video_path(conn, :create, "invalid"), %{id: "abc", user: "anon"})
    assert json_response(conn, 200) == %{"success" => false}
  end

  test "Add valid video", %{conn: conn} do
    id = "VlbtLvZqMsI"
    conn = post(conn, Routes.room_video_path(conn, :create, "valid"), %{id: id, user: "anon"})
    assert json_response(conn, 200) == %{"success" => true}
    assert Videos.get("valid")[:playing][:id] == id
  end

  test "Queue tracks time", %{conn: conn} do
    id = "_-k6ppRkpcM"
    conn = post(conn, Routes.room_video_path(conn, :create, "time"), %{id: id, user: "anon"})
    assert json_response(conn, 200) == %{"success" => true}
    init_time = QueueManager.get_runtime("time")
    :timer.sleep(1000)
    final_time = QueueManager.get_runtime("time")
    diff = final_time - init_time
    assert diff > 0.99
    assert diff < 1.01
  end

  test "Queue progression", %{conn: conn} do
    id1 = "_-k6ppRkpcM"
    id2 = "VlbtLvZqMsI"
    conn = post(conn, Routes.room_video_path(conn, :create, "progress"), %{id: id1, user: "anon"})
    assert json_response(conn, 200) == %{"success" => true}
    conn = post(conn, Routes.room_video_path(conn, :create, "progress"), %{id: id2, user: "anon"})
    assert json_response(conn, 200) == %{"success" => true}
    assert Videos.get("progress")[:playing][:id] == id1
    :timer.sleep(10000)
    assert Videos.get("progress")[:playing][:id] == id2
  end
end
