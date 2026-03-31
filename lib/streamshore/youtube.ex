defmodule Streamshore.YouTube do
  @moduledoc false

  def fetch_video(id) when is_binary(id) do
    with {:ok, response} <- Req.get(base_url(), params: request_params(id)),
         {:ok, item} <- first_item(response.body["items"]) do
      {:ok, build_video(item, id)}
    else
      {:ok, %Req.Response{}} -> {:error, "Unable to retrieve video information."}
      {:error, _reason} -> {:error, "Unable to retrieve video information."}
      :error -> {:error, "Unable to retrieve video information."}
    end
  end

  defp base_url(), do: "https://www.googleapis.com/youtube/v3/videos"

  defp request_params(id) do
    [
      id: id,
      key: System.fetch_env!("YOUTUBE_KEY"),
      part: "snippet,contentDetails"
    ]
  end

  defp first_item([item | _items]), do: {:ok, item}
  defp first_item(_items), do: :error

  defp build_video(item, id) do
    %{
      id: id,
      title: item["snippet"]["title"],
      channel: item["snippet"]["channelTitle"],
      thumbnail: item["snippet"]["thumbnails"]["high"]["url"],
      length: parse_duration(item["contentDetails"]["duration"])
    }
  end

  defp parse_duration(duration) do
    duration
    |> Timex.Duration.parse!()
    |> Timex.Duration.to_seconds()
  end
end
