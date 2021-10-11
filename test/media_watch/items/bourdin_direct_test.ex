defmodule MediaWatchWeb.BourdinDirectTest do
  use ExUnit.Case
  alias MediaWatch.Catalog.Item.BourdinDirect

  describe "guests detection" do
    @expected_guests [
      {"when guest is male", "L'invité de Bourdin Direct : Eric Caumes - 28/05", ["Eric Caumes"]},
      {"when guest is female", "L'invitée de Bourdin Direct : Amélie de Montchalin - 06/07",
       ["Amélie de Montchalin"]},
      {"when there are several guests",
       "Les invités de Bourdin Direct : Thierry Mariani et Renaud Muselier - 24/06",
       ["Thierry Mariani", "Renaud Muselier"]}
    ]

    for {test_name, string, result} <- @expected_guests do
      test "finds guests from title #{test_name}" do
        assert %{title: unquote(string), description: nil} |> BourdinDirect.get_guests_attrs() ==
                 unquote(result) |> Enum.map(&%{person: %{label: &1}})
      end
    end
  end
end
