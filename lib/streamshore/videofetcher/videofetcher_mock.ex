defmodule Streamshore.VideoFetcher.Mock do
  @behaviour Streamshore.VideoFetcher

  @videos %{
    "_-k6ppRkpcM" => %{
      id: "_-k6ppRkpcM",
      title: "the snow storm cant get us here",
      channel: "vomit",
      thumbnail: "https://i.ytimg.com/vi/_-k6ppRkpcM/hqdefault.jpg",
      length: 9
    },
    "VlbtLvZqMsI" => %{
      id: "VlbtLvZqMsI",
      title: "streamshore test video 2",
      channel: "streamshore",
      thumbnail: "https://i.ytimg.com/vi/VlbtLvZqMsI/hqdefault.jpg",
      length: 12
    },
    "9jzsr5wyG4o" => %{
      id: "9jzsr5wyG4o",
      title: "streamshore test video 3",
      channel: "streamshore",
      thumbnail: "https://i.ytimg.com/vi/9jzsr5wyG4o/hqdefault.jpg",
      length: 15
    }
  }

  def fetch_video(id) when is_binary(id) do
    case Map.fetch(@videos, id) do
      {:ok, video} -> {:ok, video}
      :error -> {:error, "Unable to retrieve video information."}
    end
  end
end
