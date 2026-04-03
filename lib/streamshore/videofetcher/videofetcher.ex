defmodule Streamshore.VideoFetcher do
  @moduledoc false

  @callback fetch_video(String.t()) :: {:ok, map()} | {:error, String.t()}

  def fetch_video(id) when is_binary(id) do
    impl().fetch_video(id)
  end

  defp impl, do: Application.get_env(:streamshore, :video_fetcher, Streamshore.VideoFetcher.Client)
end
