defmodule MediaWatch.Spacy do
  alias MediaWatch.Http

  @spec extract_entities(binary, binary) :: {:ok, list} | {:error, atom}
  def extract_entities(string, language \\ "fr"),
    do: extract_entities(string, language, has_config?())

  defp extract_entities(_, _, false), do: {:error, :no_config}

  defp extract_entities(string, language, true) when is_binary(string) do
    query = URI.encode_query(lang: language)

    case Http.post_json("#{entities_url() |> URI.to_string()}?#{query}", %{text: string}) do
      {:ok, %{"ents" => entities}} ->
        {:ok,
         entities
         |> Enum.map(&convert_to_atom_map/1)
         |> Enum.map(&%{&1 | text: &1.text |> String.trim()})}

      {:error, %Mint.TransportError{reason: :econnrefused}} ->
        {:error, :server_down}
    end
  end

  defp convert_to_atom_map(%{"label_" => label, "text" => text}),
    do: %{label: label, text: text}

  defp config(key) when is_atom(key), do: Application.get_env(:media_watch, __MODULE__)[key]
  defp base_uri(), do: %URI{host: config(:host), port: config(:port), scheme: "http"}
  defp entities_url(), do: %{base_uri() | path: "/entities/"}

  defp has_config?(), do: not is_nil(Application.get_env(:media_watch, __MODULE__))

  def is_alive?(), do: base_uri() |> URI.to_string() |> Http.is_alive?()
end
