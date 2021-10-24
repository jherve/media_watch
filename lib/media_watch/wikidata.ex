defmodule MediaWatch.Wikidata do
  alias MediaWatch.Http

  defmodule Sparql do
    @base_url "https://query.wikidata.org/sparql"
    @entity_page_url "https://www.wikidata.org/wiki/Special:EntityData"

    def run_query(name) do
      with {:ok, data} <- query(name: name),
           {:ok, qid} <- extract(data, :qid),
           {:ok, label} <- extract(data, :label),
           {:ok, description} <- extract(data, :description) do
        {:ok, %{id: qid, label: label, description: description}}
      end
    end

    def get(qid) do
      with {:ok, data} <- query(id: qid),
           data <- data |> Map.get("entities") |> Map.get("Q#{qid}"),
           true <- data |> is_human?,
           {:ok, label} <- extract_from_sp(data, :label),
           {:ok, description} <- extract_from_sp(data, :description) do
        {:ok, %{id: qid, label: label, description: description}}
      else
        false -> {:error, :no_match}
        e = {:error, _} -> e
      end
    end

    defp is_human?(%{
           "claims" => %{
             "P31" => [%{"mainsnak" => %{"datavalue" => %{"value" => %{"id" => "Q5"}}}}]
           }
         }),
         do: true

    defp is_human?(%{}), do: false

    defp query(name: name) do
      query_string = URI.encode_query(query: person_query(name), format: "json")

      with {:ok, body} <- Http.get_body("#{@base_url}?#{query_string}"), do: Jason.decode(body)
    end

    defp query(id: id) do
      entity_url = "#{@entity_page_url}/Q#{id}.json"
      with {:ok, body} <- Http.get_body(entity_url), do: Jason.decode(body)
    end

    defp extract_from_sp(%{"labels" => %{"fr" => %{"value" => value}}}, :label), do: {:ok, value}

    defp extract_from_sp(%{"labels" => %{}}, :label),
      do: {:error, :no_fr_label}

    defp extract_from_sp(%{"descriptions" => %{"fr" => %{"value" => value}}}, :description),
      do: {:ok, value}

    defp extract_from_sp(%{"descriptions" => %{}}, :description),
      do: {:ok, nil}

    defp extract(%{"results" => %{"bindings" => []}}, _key), do: {:error, :no_match}

    defp extract(%{"results" => %{"bindings" => [binding]}}, key),
      do: {:ok, extract(binding, key)}

    defp extract(%{"person" => %{"type" => "uri", "value" => uri}}, :qid) do
      with %URI{path: path} <- uri |> URI.parse(),
           "Q" <> qid <- path |> Path.basename() do
        qid |> String.to_integer()
      end
    end

    defp extract(%{"personLabel" => %{"type" => "literal", "value" => label}}, :label),
      do: label

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
          ?person wdt:P31 wd:Q5 .
          ?person rdfs:label "#{name}"@#{language} .

          SERVICE wikibase:label { bd:serviceParam wikibase:language "#{language}". }
        }
        LIMIT 1
      """
  end

  defmodule WbSearch do
    @wikidata_api_url "https://www.wikidata.org/w/api.php"

    def run_query(name) do
      with {:ok, data} <- query(name),
           qid when not is_nil(qid) <- extract(data, :qid),
           {:ok, map} <- Sparql.get(qid) do
        map
      else
        nil -> {:error, :no_match}
        e = {:error, _} -> e
      end
    end

    defp query(name, language \\ "fr") do
      query_string =
        URI.encode_query(
          action: "wbsearchentities",
          search: name,
          format: "json",
          language: language,
          uselang: language,
          type: "item",
          limit: 1
        )

      with {:ok, body} <- Http.get_body("#{@wikidata_api_url}?#{query_string}"),
           do: Jason.decode(body)
    end

    defp extract(%{"search" => [%{"id" => "Q" <> qid}]}, :qid),
      do: qid |> String.to_integer()

    defp extract(%{"search" => []}, :qid), do: nil
  end

  def get_info_from_name(name) do
    case Sparql.run_query(name) do
      {:ok, res} -> res
      {:error, _} -> WbSearch.run_query(name)
    end
  end
end
