defmodule MediaWatch.Http do
  def get_body(url) when is_binary(url) do
    case Finch.build(:get, url) |> Finch.request(MediaWatch.Finch) do
      {:ok, %{body: body, status: 200}} ->
        {:ok, body}

      {:ok, %{headers: headers, status: 301}} ->
        headers |> Map.new() |> Map.get("location") |> get_body

      {:ok, e = %{status: status}} when status >= 400 ->
        {:error, e}

      e = {:error, _} ->
        e
    end
  end
end
