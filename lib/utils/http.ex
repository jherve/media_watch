defmodule MediaWatch.Http do
  def is_alive?(url) do
    case Finch.build(:get, url) |> Finch.request(MediaWatch.Finch, receive_timeout: 500) do
      {:error, %{reason: reason}} when reason in [:econnrefused, :timeout] -> false
      {:ok, _} -> true
    end
  end

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

  def post_json(url, body_params, headers \\ [])
      when is_binary(url) and is_list(headers) and is_map(body_params) do
    with {:ok, body} <- body_params |> Jason.encode(body_params) do
      case Finch.build(:post, url, headers, body) |> Finch.request(MediaWatch.Finch) do
        {:ok, %{body: body, status: 200}} -> body |> Jason.decode()
        e = {:error, _} -> e
      end
    end
  end
end
