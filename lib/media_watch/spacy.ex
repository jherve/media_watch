defmodule MediaWatch.Spacy do
  alias MediaWatch.Http

  def extract_entities(string, language \\ "fr") do
    query = URI.encode_query(lang: language)

    with {:ok, %{"ents" => entities}} <-
           Http.post_json("#{entities_url() |> URI.to_string()}?#{query}", %{text: string}) do
      {:ok,
       entities
       |> Enum.map(&convert_to_atom_map/1)
       |> Enum.filter(&(&1.label == "PER"))
       |> Enum.map(&(&1.text |> String.trim()))}
    end
  end

  defp convert_to_atom_map(%{"label_" => label, "text" => text}),
    do: %{label: label, text: text}

  defp config(key) when is_atom(key), do: Application.get_env(:media_watch, __MODULE__)[key]
  defp base_uri(), do: %URI{host: config(:host), port: config(:port), scheme: "http"}
  defp entities_url(), do: %{base_uri() | path: "/entities/"}
end
