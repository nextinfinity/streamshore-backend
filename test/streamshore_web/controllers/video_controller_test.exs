defmodule VideoControllerTest do
  use StreamshoreWeb.ConnCase
  import Phoenix.ChannelTest

  alias Streamshore.Guardian
  alias Streamshore.QueueManager
  alias Streamshore.Videos

  setup %{conn: conn} do
    {:ok, token, _claims} = Guardian.encode_and_sign("anon", %{anon: false})

    conn =
      conn
      |> put_req_header("authorization", "Bearer " <> token)

    {:ok, conn: conn}
  end

  test "Add invalid video", %{conn: conn} do
    conn = post(conn, Routes.room_video_path(conn, :create, "invalid"), %{id: "abc"})
    assert json_response(conn, 422) == %{"error" => "Unable to retrieve video information."}
  end

  test "Add valid video", %{conn: conn} do
    id = "VlbtLvZqMsI"
    conn = post(conn, Routes.room_video_path(conn, :create, "valid"), %{id: id})
    assert json_response(conn, 200) == %{}
    assert Videos.get("valid")[:playing][:id] == id
  end

  test "Queue tracks time", %{conn: conn} do
    id = "_-k6ppRkpcM"
    conn = post(conn, Routes.room_video_path(conn, :create, "time"), %{id: id})
    assert json_response(conn, 200) == %{}

    room_data = Videos.get("time")
    playing = Map.update!(room_data[:playing], :start, &(&1 - 2))
    Videos.set("time", Map.put(room_data, :playing, playing))

    assert_in_delta QueueManager.get_runtime("time"), 1.0, 0.05
  end

  test "Queue progression", %{conn: conn} do
    id1 = "_-k6ppRkpcM"
    id2 = "VlbtLvZqMsI"
    conn = post(conn, Routes.room_video_path(conn, :create, "progress"), %{id: id1})
    assert json_response(conn, 200) == %{}
    conn = post(conn, Routes.room_video_path(conn, :create, "progress"), %{id: id2})
    assert json_response(conn, 200) == %{}
    assert Videos.get("progress")[:playing][:id] == id1
    room_data = Videos.get("progress")
    playing = Map.update!(room_data[:playing], :start, &(&1 - 10))
    Videos.set("progress", Map.put(room_data, :playing, playing))
    QueueManager.tick()
    assert Videos.get("progress")[:playing][:id] == id2
  end

  test "Pushing video to front of queue", %{conn: conn} do
    conn =
      conn
      |> post(Routes.room_path(conn, :create), %{name: "front", motd: "", privacy: 0})

    id1 = "_-k6ppRkpcM"
    id2 = "VlbtLvZqMsI"
    id3 = "9jzsr5wyG4o"
    conn = post(conn, Routes.room_video_path(conn, :create, "front"), %{id: id1})
    assert json_response(conn, 200) == %{}
    conn = post(conn, Routes.room_video_path(conn, :create, "front"), %{id: id2})
    assert json_response(conn, 200) == %{}
    conn = post(conn, Routes.room_video_path(conn, :create, "front"), %{id: id3})
    assert json_response(conn, 200) == %{}
    _conn = put(conn, Routes.room_video_path(conn, :update, "front", "1"))
    assert Enum.at(Videos.get("front")[:queue], 0)[:id] == id3
  end

  test "Removing video from queue", %{conn: conn} do
    conn =
      conn
      |> post(Routes.room_path(conn, :create), %{name: "remove", motd: "", privacy: 0})

    id1 = "_-k6ppRkpcM"
    id2 = "VlbtLvZqMsI"
    conn = post(conn, Routes.room_video_path(conn, :create, "remove"), %{id: id1})
    assert json_response(conn, 200) == %{}
    conn = post(conn, Routes.room_video_path(conn, :create, "remove"), %{id: id2})
    assert json_response(conn, 200) == %{}
    _conn = delete(conn, Routes.room_video_path(conn, :delete, "remove", "0"))
    assert Videos.get("remove")[:queue] == []
  end

  test "queue permissions", %{conn: conn} do
    conn =
      post(conn, Routes.room_path(conn, :create), %{
        name: "QueuePerm",
        motd: "",
        queue_level: 101,
        privacy: 0
      })

    assert json_response(conn, 200) == %{"route" => "queueperm"}
    id = "_-k6ppRkpcM"
    conn = post(conn, Routes.room_video_path(conn, :create, "queueperm"), %{id: id})
    assert json_response(conn, 403) == %{"error" => "Insufficient permission"}
  end

  test "video queue update without a token returns unauthorized", %{conn: conn} do
    conn =
      post(conn, Routes.room_path(conn, :create), %{name: "UpdateAuth", motd: "", privacy: 0})

    assert json_response(conn, 200) == %{"route" => "updateauth"}

    conn = put(build_conn(), Routes.room_video_path(build_conn(), :update, "updateauth", "0"))

    assert json_response(conn, 401) == %{"error" => "No valid token provided"}
  end

  test "queue limit returns conflict", %{conn: conn} do
    conn =
      post(conn, Routes.room_path(conn, :create), %{
        name: "QueueLimit",
        motd: "",
        queue_limit: 1,
        privacy: 0
      })

    assert json_response(conn, 200) == %{"route" => "queuelimit"}

    conn = post(conn, Routes.room_video_path(conn, :create, "queuelimit"), %{id: "_-k6ppRkpcM"})
    assert json_response(conn, 200) == %{}

    conn = post(conn, Routes.room_video_path(conn, :create, "queuelimit"), %{id: "VlbtLvZqMsI"})
    assert json_response(conn, 200) == %{}

    conn = post(conn, Routes.room_video_path(conn, :create, "queuelimit"), %{id: "9jzsr5wyG4o"})

    assert json_response(conn, 409) == %{
             "error" => "You already have the maximum allowed amount of videos in the queue."
           }
  end

  test "anonymous permissions", %{conn: conn} do
    conn =
      post(conn, Routes.room_path(conn, :create), %{
        name: "QueueAnon",
        motd: "",
        anon_queue: 0,
        privacy: 0
      })

    assert json_response(conn, 200) == %{"route" => "queueanon"}
    {:ok, token, _claims} = Guardian.encode_and_sign("anon", %{anon: true})

    conn2 =
      build_conn()
      |> put_req_header("authorization", "Bearer " <> token)

    id = "_-k6ppRkpcM"
    conn2 = post(conn2, Routes.room_video_path(conn2, :create, "queueanon"), %{id: id})

    assert json_response(conn2, 403) == %{
             "error" => "You must be logged in to perform this action"
           }
  end

  test "votes tracked", %{conn: conn} do
    id1 = "_-k6ppRkpcM"
    id2 = "VlbtLvZqMsI"

    conn =
      post(conn, Routes.room_path(conn, :create), %{
        name: "Votes",
        motd: "",
        privacy: 0,
        vote_threshold: 101
      })

    assert json_response(conn, 200) == %{"route" => "votes"}
    conn = post(conn, Routes.room_video_path(conn, :create, "votes"), %{id: id1})
    assert json_response(conn, 200) == %{}
    conn = post(conn, Routes.room_video_path(conn, :create, "votes"), %{id: id2})
    assert json_response(conn, 200) == %{}

    {:ok, _, socket} =
      socket(StreamshoreWeb.UserSocket, "user", %{user: "user", anon: false})
      |> subscribe_and_join(StreamshoreWeb.RoomChannel, "room:votes")

    Phoenix.ChannelTest.push(socket, "vote", %{})
    assert_eventually(fn -> Videos.get("votes")[:playing][:votes] == ["user"] end)
  end

  test "vote skip", %{conn: conn} do
    id1 = "_-k6ppRkpcM"
    id2 = "VlbtLvZqMsI"

    conn =
      post(conn, Routes.room_path(conn, :create), %{
        name: "Skip",
        motd: "",
        privacy: 0,
        vote_threshold: 50
      })

    assert json_response(conn, 200) == %{"route" => "skip"}
    conn = post(conn, Routes.room_video_path(conn, :create, "skip"), %{id: id1})
    assert json_response(conn, 200) == %{}
    conn = post(conn, Routes.room_video_path(conn, :create, "skip"), %{id: id2})
    assert json_response(conn, 200) == %{}

    {:ok, _, socket} =
      socket(StreamshoreWeb.UserSocket, "user", %{user: "user", anon: false})
      |> subscribe_and_join(StreamshoreWeb.RoomChannel, "room:skip")

    Phoenix.ChannelTest.push(socket, "vote", %{})
    assert_eventually(fn -> Videos.get("skip")[:playing][:id] == id2 end)
  end

  test "no votes", %{conn: conn} do
    id1 = "_-k6ppRkpcM"
    id2 = "VlbtLvZqMsI"

    conn =
      post(conn, Routes.room_path(conn, :create), %{
        name: "No Votes",
        motd: "",
        privacy: 0,
        vote_enable: 0
      })

    assert json_response(conn, 200) == %{"route" => "no-votes"}
    conn = post(conn, Routes.room_video_path(conn, :create, "no-votes"), %{id: id1})
    assert json_response(conn, 200) == %{}
    conn = post(conn, Routes.room_video_path(conn, :create, "no-votes"), %{id: id2})
    assert json_response(conn, 200) == %{}

    {:ok, _, socket} =
      socket(StreamshoreWeb.UserSocket, "user", %{user: "user", anon: false})
      |> subscribe_and_join(StreamshoreWeb.RoomChannel, "room:no-votes")

    Phoenix.ChannelTest.push(socket, "vote", %{})
    assert_eventually(fn -> Videos.get("no-votes")[:playing][:votes] == [] end)
  end

  test "update vote enable", %{conn: conn} do
    id1 = "_-k6ppRkpcM"
    id2 = "VlbtLvZqMsI"

    conn =
      post(conn, Routes.room_path(conn, :create), %{
        name: "Update Votes",
        motd: "",
        privacy: 0,
        vote_enable: 0
      })

    assert json_response(conn, 200) == %{"route" => "update-votes"}
    conn = post(conn, Routes.room_video_path(conn, :create, "update-votes"), %{id: id1})
    assert json_response(conn, 200) == %{}
    conn = post(conn, Routes.room_video_path(conn, :create, "update-votes"), %{id: id2})
    assert json_response(conn, 200) == %{}

    {:ok, _, socket} =
      socket(StreamshoreWeb.UserSocket, "user", %{user: "user", anon: false})
      |> subscribe_and_join(StreamshoreWeb.RoomChannel, "room:update-votes")

    Phoenix.ChannelTest.push(socket, "vote", %{})
    assert_eventually(fn -> Videos.get("update-votes")[:playing][:votes] == [] end)

    conn =
      put(conn, Routes.room_path(conn, :update, "update-votes"), %{
        vote_threshold: 101,
        vote_enable: 1
      })

    assert json_response(conn, 200) == %{}

    Phoenix.ChannelTest.push(socket, "vote", %{})
    assert_eventually(fn -> Videos.get("update-votes")[:playing][:votes] == ["user"] end)
  end

  test "vote threshold", %{conn: conn} do
    id1 = "_-k6ppRkpcM"
    id2 = "VlbtLvZqMsI"

    conn =
      post(conn, Routes.room_path(conn, :create), %{
        name: "Vote Threshold",
        motd: "",
        privacy: 0,
        vote_threshold: 50
      })

    assert json_response(conn, 200) == %{"route" => "vote-threshold"}
    conn = post(conn, Routes.room_video_path(conn, :create, "vote-threshold"), %{id: id1})
    assert json_response(conn, 200) == %{}
    conn = post(conn, Routes.room_video_path(conn, :create, "vote-threshold"), %{id: id2})
    assert json_response(conn, 200) == %{}

    {:ok, _, socket} =
      socket(StreamshoreWeb.UserSocket, "user", %{user: "user", anon: false})
      |> subscribe_and_join(StreamshoreWeb.RoomChannel, "room:vote-threshold")

    Phoenix.ChannelTest.push(socket, "vote", %{})
    assert_eventually(fn -> Videos.get("vote-threshold")[:playing][:id] == id2 end)

    conn = put(conn, Routes.room_path(conn, :update, "vote-threshold"), %{vote_threshold: 101})
    assert json_response(conn, 200) == %{}

    Phoenix.ChannelTest.push(socket, "vote", %{})

    assert_eventually(fn ->
      Videos.get("vote-threshold")[:playing][:id] == id2 &&
        Videos.get("vote-threshold")[:playing][:votes] == ["user"]
    end)
  end

  defp assert_eventually(assertion, attempts \\ 20)

  defp assert_eventually(assertion, attempts) when attempts > 0 do
    if assertion.() do
      assert true
    else
      receive do
      after
        10 -> assert_eventually(assertion, attempts - 1)
      end
    end
  end

  defp assert_eventually(_assertion, 0) do
    flunk("condition was not met in time")
  end
end
