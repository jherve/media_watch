defmodule MediaWatch.Wikidata do
  alias MediaWatch.Http
  @base_url "https://query.wikidata.org/sparql"

  def get_info_from_name(name) do
    query_string = URI.encode_query(query: person_query(name), format: "json")

    with {:ok, body} <- Http.get_body("#{@base_url}?#{query_string}"),
         {:ok, data} <- Jason.decode(body),
         qid <- extract(data, :qid),
         label = ^name <- extract(data, :label),
         description <- extract(data, :description) do
      %{id: qid, label: label, description: description}
    end
  end

  defp extract(%{"results" => %{"bindings" => []}}, _key), do: {:error, :no_match}
  defp extract(%{"results" => %{"bindings" => [binding]}}, key), do: extract(binding, key)

  defp extract(%{"person" => %{"type" => "uri", "value" => uri}}, :qid) do
    with %URI{path: path} <- uri |> URI.parse(),
         "Q" <> qid <- path |> Path.basename() do
      qid |> String.to_integer()
    end
  end

  defp extract(%{"personLabel" => %{"type" => "literal", "value" => label}}, :label), do: label

  defp extract(
         %{"personDescription" => %{"type" => "literal", "value" => description}},
         :description
       ),
       do: description

  defp extract(_, :description), do: nil

  defp person_query(name, language \\ "fr"),
    do: """
      SELECT ?person ?personLabel ?personDescription
      WHERE {
        ?person rdfs:label "#{name}"@#{language} .

        SERVICE wikibase:label { bd:serviceParam wikibase:language "#{language}". }
      }
      LIMIT 1
    """
end
