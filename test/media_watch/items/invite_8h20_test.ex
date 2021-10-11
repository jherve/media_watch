defmodule MediaWatchWeb.Invite8h20Test do
  use ExUnit.Case
  alias MediaWatch.Catalog.Item.Invite8h20

  describe "guests detection" do
    @expected_guests [
      {"when guest is in 'Invités'",
       """
       durée : 00:23:47 - L'invité de 8h20 : le grand entretien - Alain Fischer, pédiatre, professeur d'immunologie \
       et président du Conseil d'orientation de la stratégie vaccinale, est l'invité du Grand entretien. - invités : \
       Alain FISCHER - Alain Fischer : médecin, professeur d'immunologie pédiatrique et chercheur en biologie, directeur \
       scientifique de l'Institut hospitalo-universitaire Imagine depuis 2011 et titulaire de la Chaire, titulaire de \
       la chaire Médecine expérimentale au Collège de
       """, ["Alain Fischer"]},
      {"when there are several guests in 'Invités'",
       """
       durée : 00:25:12 - L'invité de 8h20 : le grand entretien - Jean-François Clervoy, astronaute, président de Novespace, \
             Philippe Baptiste, PDG du CNES (Centre national d’études spatiales), et Philippe Henarejos, rédacteur en chef du \
       magazine "Ciel et espace", auteur de "Ils ont marché sur la Lune" (Belin), sont les invités du Grand entretien de France Inter.\
        - invités : Jean François CLERVOY, Philippe Baptiste, Philippe HENAREJOS - Jean-François Clervoy : Astronaute de \
       l'Agence spatiale européenne (ESA), Président de Novespace, Philippe Baptiste : Président du Centre national d'études \
             spatiales (CNES), Philippe Henarejos : Rédacteur en chef du magazine "Ciel et Espace"
       """, ["Jean François Clervoy", "Philippe Baptiste", "Philippe Henarejos"]},
      {"when there is a 'par' section",
       """
       durée : 00:24:46 - L'invité de 8h20 : le grand entretien - par : Nicolas Demorand, Léa Salamé - Atiq Rahimi, \
       écrivain et réalisateur, et Jean-Pierre Filiu, historien, professeur à Sciences-Po, auteur de «Le milieu des mondes.\
       Une histoire laïque du Moyen-Orient de 395 à nos jours » (Seuil), sont les invités du Grand entretien de France Inter. \
       - invités : Atiq Rahimi, Jean Pierre FILIU - Atiq Rahimi : Ecrivain, réalisateur, Jean-Pierre Filiu : \
       Historien spécialiste de la Syrie
       """, ["Atiq Rahimi", "Jean Pierre Filiu"]}
    ]

    for {test_name, description, result} <- @expected_guests do
      test "finds guests from description #{test_name}" do
        assert %{title: nil, description: unquote(description)} |> Invite8h20.get_guests_attrs() ==
                 unquote(result) |> Enum.map(&%{person: %{label: &1}})
      end
    end

    @guests_from_title [
      {"when there is no 'Invités' section in description",
       """
       Damien Abad : "Le pass sanitaire ne peut pas être plus liberticide que le confinement"
       """,
       """
       durée : 00:24:13 - L'invité de 8h20 : le grand entretien - par : Nicolas Demorand, Léa Salamé - Damien Abad, \
       président du groupe Les Républicains à l'Assemblée nationale, député de l'Ain, est l'invité du Grand entretien \
       de France Inter.
       """, ["Damien Abad"]}
    ]

    for {test_name, title, description, result} <- @guests_from_title do
      test "finds guests from title #{test_name}" do
        assert %{title: unquote(title), description: unquote(description)}
               |> Invite8h20.get_guests_attrs() ==
                 unquote(result) |> Enum.map(&%{person: %{label: &1}})
      end
    end

    test "fails when the title ends with ', said XXX'" do
      title = """
      Covid-19 : "La situation à l'école est la plus complexe qui nous attend cet automne", juge Arnaud Fontanet
      """

      description = """
            durée : 00:24:43 - L'invité de 8h20 : le grand entretien - par : Nicolas Demorand, Léa Salamé - Bruno Lina, virologue au CHU de Lyon, et Arnaud Fontanet, épidémiologiste à l'Institut Pasteur, tous deux membres du conseil scientifique, sont les invités d'Hélène Roussel dans le grand entretien pour évoquer la situation sanitaire.
      """

      assert %{title: title, description: description} |> Invite8h20.get_guests_attrs() == []
    end
  end
end
