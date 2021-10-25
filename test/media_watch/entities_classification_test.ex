defmodule MediaWatchWeb.EntitiesClassificationTest do
  use ExUnit.Case
  alias MediaWatch.Analysis.EntitiesClassification

  @cases [
    {[
       %{field: "description", label: "Dominique Bourg", type: :show_occurrence_description},
       %{field: "title", label: "Dominique Bourg", type: :show_occurrence_description},
       %{field: "description", label: "Rachid Laïreche", type: :show_occurrence_description},
       %{field: "title", label: "Rachid Laïreche", type: :show_occurrence_description}
     ], ["Dominique Bourg", "Rachid Laïreche"]},
    {[
       %{field: "description", label: "Barbara Pompili", type: :show_occurrence_description},
       %{field: "title", label: "Barbara Pompili", type: :show_occurrence_description}
     ], ["Barbara Pompili"]},
    {[
       %{field: "description", label: "Alain Finkielkraut", type: :show_occurrence_description},
       %{field: "title", label: "Alain Finkielkraut", type: :show_occurrence_description},
       %{field: "description", label: "Darmanin", type: :show_occurrence_description}
     ], ["Alain Finkielkraut"]},
    {[
       %{field: "description", label: "Gérard Larcher", type: :show_occurrence_description},
       %{field: "title", label: "Gérard Larcher", type: :show_occurrence_description},
       %{field: "description", label: "Éric Zemmour", type: :show_occurrence_description},
       %{field: "description", label: "Eric Zemmour", type: :show_occurrence_description},
       %{field: "description", label: "Gérald Darmanin", type: :show_occurrence_description},
       %{field: "description", label: "Gérard Larcher", type: :show_occurrence_description},
       %{field: "title", label: "Gérard Larcher", type: :show_occurrence_description}
     ], ["Gérard Larcher"]},
    {[
       %{field: "description", label: "Louis GARREL", type: :show_occurrence_description},
       %{field: "description", label: "Louis Garrel", type: :show_occurrence_description},
       %{field: "title", label: "Louis Garrel", type: :show_occurrence_description},
       %{field: "description", label: "Rachel Lang", type: :show_occurrence_description},
       %{field: "title", label: "Rachel Lang", type: :show_occurrence_description},
       %{
         field: "description",
         label: "Rachel Lang - Louis Garrel",
         type: :show_occurrence_description
       }
     ], ["Louis Garrel", "Rachel Lang"]},
    {[%{field: "title", label: "Barbara Pompili", type: :show_occurrence_description}],
     ["Barbara Pompili"]},
    {[
       %{field: "description", label: "Denis Mukwege", type: :show_occurrence_description},
       %{
         field: "description",
         label: "Denis Mukwege - Denis Mukwege",
         type: :show_occurrence_description
       },
       %{field: "title", label: "Docteur Denis Mukwege", type: :show_occurrence_description}
     ], ["Denis Mukwege"]},
    {[
       %{field: "description", label: "Daniel Cohn-Bendit"},
       %{field: "description", label: "Hélène MIARD DELACROIX"},
       %{field: "description", label: "Hélène Miard"},
       %{field: "description", label: "Marion VAN RENTHERGHEM"},
       %{field: "description", label: "Marion Van Renterghem"},
       %{field: "description", label: "Marion Van Rentherghem"},
       %{field: "description", label: "Merkel"}
     ], ["Daniel Cohn-Bendit", "Marion Van Renterghem"]}
  ]
  @cases_capitalization [
    {"Louis GARREL", "Louis Garrel"},
    {"Hélène MIARD DELACROIX", "Hélène Miard Delacroix"},
    {"Daniel COHN-BENDIT", "Daniel Cohn-Bendit"}
  ]
  @cases_trim [
    {"Bruno Le Maire - 06/09", "Bruno Le Maire"},
    {"Nicolas Dupont-Aignan - 20/07", "Nicolas Dupont-Aignan"},
    {"Émile Élimé", "Émile Élimé"}
  ]
  @cases_missing_diacritics [
    {["Éric Dupond-Moretti", "Eric Dupond-Moretti"],
     ["Éric Dupond-Moretti", "Éric Dupond-Moretti"]}
  ]
  @cases_split [
    {["Hélène Roussel - Didier Le Bret", "Hélène Roussel", "Didier Le Bret"],
     ["Hélène Roussel", "Didier Le Bret", "Hélène Roussel", "Didier Le Bret"]},
    {["Etienne Ollion Chercheur", "Etienne Ollion"], ["Etienne Ollion", "Etienne Ollion"]},
    {
      ["Denis Mukwege", "Denis Mukwege - Denis Mukwege", "Docteur Denis Mukwege"],
      # TODO: The 2nd element should ideally be split into 2
      ["Denis Mukwege", "Denis Mukwege", "Denis Mukwege"]
    },
    {["Bixente", "Bixente Lizarazu"], ["Bixente", "Bixente Lizarazu"]}
  ]

  describe "guests detection" do
    for {{input, output}, idx} <- @cases_capitalization |> Enum.with_index() do
      test "case #{idx} de-capitalizes #{inspect(output)}" do
        assert unquote(input)
               |> EntitiesClassification.capitalize_first_letters() == unquote(output)
      end
    end

    for {{input, output}, idx} <- @cases_missing_diacritics |> Enum.with_index() do
      test "case #{idx} replaces missing diacritics #{inspect(output)}" do
        assert unquote(input) |> EntitiesClassification.replace_missing_diacritics() ==
                 unquote(output)
      end

      test "case #{idx} replaces missing diacritics in entity #{inspect(output)}" do
        assert unquote(input)
               |> Enum.map(&%{label: &1})
               |> EntitiesClassification.replace_missing_diacritics() ==
                 unquote(output) |> Enum.map(&%{label: &1})
      end
    end

    for {{input, output}, idx} <- @cases_trim |> Enum.with_index() do
      test "case #{idx} trims #{inspect(output)}" do
        assert unquote(input) |> EntitiesClassification.trim_weird_characters() == unquote(output)
      end
    end

    for {{input, output}, idx} <- @cases_split |> Enum.with_index() do
      test "case #{idx} splits #{inspect(output)}" do
        assert unquote(input) |> EntitiesClassification.split_names() == unquote(output)
      end

      test "case #{idx} splits entity #{inspect(output)}" do
        assert unquote(input) |> Enum.map(&%{label: &1}) |> EntitiesClassification.split_names() ==
                 unquote(output) |> Enum.map(&%{label: &1})
      end
    end

    for {{input, output}, idx} <- @cases |> Enum.with_index() do
      test "case #{idx} finds #{inspect(output)}" do
        assert unquote(input |> Macro.escape())
               |> EntitiesClassification.cleanup()
               |> EntitiesClassification.get_guests()
               |> EntitiesClassification.pick_candidates() ==
                 unquote(output)
      end
    end
  end
end
