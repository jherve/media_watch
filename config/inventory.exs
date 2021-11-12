import Config

config :media_watch, MediaWatchInventory,
  items: [
    {MediaWatchInventory.Item.Le8h30FranceInfo,
     show: %{
       name: "8h30 franceinfo",
       url: "https://www.francetvinfo.fr/replay-radio/8h30-fauvelle-dely/",
       airing_schedule: "30 8 * * *",
       duration_minutes: 25,
       host_names: [
         "Marc Fauvelle",
         "Ersin Leibowitch",
         "Jean-Jérôme Bertolus",
         "Salhia Brakhlia",
         "Myriam Encaoua"
       ]
     },
     sources: [%{rss_feed: %{url: "https://radiofrance-podcast.net/podcast09/rss_16370.xml"}}],
     channels: [MediaWatchInventory.Channel.FranceInfo]},
    {MediaWatchInventory.Item.BourdinDirect,
     show: %{
       name: "Bourdin Direct",
       url: "https://rmc.bfmtv.com/emission/bourdin-direct/",
       airing_schedule: "35 8 * * MON-FRI",
       duration_minutes: 25,
       host_names: ["Jean-Jacques Bourdin"],
       alternate_hosts: [
         "Philippe Corbé",
         "Rémy Barret",
         "Apolline de Malherbe",
         "Matthieu Rouault"
       ]
     },
     sources: [%{rss_feed: %{url: "https://podcast.rmc.fr/channel30/RMCInfochannel30.xml"}}],
     channels: [MediaWatchInventory.Channel.RMC]},
    {MediaWatchInventory.Item.Invite7h50,
     show: %{
       name: "L'invité de 7h50",
       url: "https://www.franceinter.fr/emissions/invite-de-7h50",
       airing_schedule: "50 7 * * MON-FRI",
       duration_minutes: 10,
       host_names: ["Léa Salamé"],
       alternate_hosts: ["Laetitia Gayet", "Hélène Roussel", "Amélie Perrier", "Carine Bécard"]
     },
     sources: [%{rss_feed: %{url: "http://radiofrance-podcast.net/podcast09/rss_11710.xml"}}],
     channels: [MediaWatchInventory.Channel.FranceInter]},
    {MediaWatchInventory.Item.Invite8h20,
     show: %{
       name: "L'invité de 8h20'",
       url: "https://www.franceinter.fr/emissions/l-invite",
       airing_schedule: "20 8 * * MON-FRI",
       duration_minutes: 25,
       host_names: ["Léa Salamé", "Nicolas Demorand"],
       alternate_hosts: ["Hélène Roussel"]
     },
     sources: [%{rss_feed: %{url: "http://radiofrance-podcast.net/podcast09/rss_10239.xml"}}],
     channels: [MediaWatchInventory.Channel.FranceInter]},
    {MediaWatchInventory.Item.InviteDesMatins,
     show: %{
       name: "L'Invité(e) des Matins",
       url: "https://www.franceculture.fr/emissions/linvite-des-matins",
       airing_schedule: "40 7 * * MON-FRI",
       duration_minutes: 45,
       host_names: ["Guillaume Erner"]
     },
     sources: [%{rss_feed: %{url: "https://radiofrance-podcast.net/podcast09/rss_13983.xml"}}],
     channels: [MediaWatchInventory.Channel.FranceCulture]},
    {MediaWatchInventory.Item.InviteRTL,
     show: %{
       name: "L'invité de RTL",
       url: "https://www.rtl.fr/programmes/l-invite-de-rtl",
       airing_schedule: "45 7 * * MON-FRI",
       duration_minutes: 10,
       host_names: ["Alba Ventura"],
       alternate_hosts: ["Benjamin Sportouch", "Jérôme Florin", "Stéphane Carpentier"]
     },
     sources: [%{rss_feed: %{url: "https://www.rtl.fr/podcast/linvite-de-rtl.xml"}}],
     channels: [MediaWatchInventory.Channel.RTL]},
    {MediaWatchInventory.Item.InviteRTLSoir,
     show: %{
       name: "L'invité de RTL Soir",
       url: "https://www.rtl.fr/programmes/l-invite-de-rtl-soir",
       airing_schedule: "20 18 * * MON-FRI",
       duration_minutes: 10,
       host_names: ["Julien Sellier"],
       alternate_hosts: [
         "Thomas Sotto",
         "Olivier Boy",
         "Amandine Bégot",
         "Bénédicte Tassart",
         "Christophe Pacaud",
         "Vincent Parizot"
       ]
     },
     sources: [%{rss_feed: %{url: "https://www.rtl.fr/podcast/l-invite-de-rtl-soir.xml"}}],
     channels: [MediaWatchInventory.Channel.RTL]},
    {MediaWatchInventory.Item.LaGrandeTableIdees,
     show: %{
       name: "La Grande Table idées",
       url: "https://www.franceculture.fr/emissions/la-grande-table-2eme-partie",
       airing_schedule: "55 12 * * MON-FRI",
       duration_minutes: 35,
       host_names: ["Olivia Gesbert"]
     },
     sources: [%{rss_feed: %{url: "https://radiofrance-podcast.net/podcast09/rss_12360.xml"}}],
     channels: [MediaWatchInventory.Channel.FranceCulture]},
    {MediaWatchInventory.Item.LeGrandFaceAFace,
     show: %{
       name: "Le Grand Face-à-face",
       url: "https://www.franceinter.fr/emissions/le-grand-face-a-face",
       airing_schedule: "0 12 * * SAT",
       duration_minutes: 55,
       host_names: ["Ali Baddou", "Natacha Polony", "Gilles Finchelstein"]
     },
     sources: [%{rss_feed: %{url: "https://radiofrance-podcast.net/podcast09/rss_18558.xml"}}],
     channels: [MediaWatchInventory.Channel.FranceInter]},
    {MediaWatchInventory.Item.LeGrandRendezVous,
     show: %{
       name: "Le grand rendez-vous",
       url: "https://www.europe1.fr/emissions/Le-grand-rendez-vous",
       airing_schedule: "0 10 * * SUN",
       duration_minutes: 45,
       host_names: ["Sonia Mabrouk"],
       alternate_hosts: ["Charles Villeneuve"]
     },
     sources: [
       %{rss_feed: %{url: "https://www.europe1.fr/rss/podcasts/le-grand-rendez-vous.xml"}}
     ],
     channels: [MediaWatchInventory.Channel.Europe1]},
    {MediaWatchInventory.Item.LInterviewPolitique,
     show: %{
       name: "L'interview politique",
       url: "https://www.europe1.fr/emissions/linterview-politique-de-8h20",
       airing_schedule: "14 8 * * MON-FRI",
       duration_minutes: 15,
       host_names: ["Sonia Mabrouk"],
       alternate_hosts: ["Dimitri Pavlenko"]
     },
     sources: [%{rss_feed: %{url: "https://www.europe1.fr/rss/podcasts/interview-8h20.xml"}}],
     channels: [MediaWatchInventory.Channel.Europe1]},
    {MediaWatchInventory.Item.QuestionsPolitiques,
     show: %{
       name: "Questions politiques",
       url: "https://www.franceinter.fr/emissions/questions-politiques",
       airing_schedule: "0 12 * * SUN",
       duration_minutes: 55,
       host_names: ["Thomas Snegaroff"],
       columnists: [
         "Carine Bécard",
         "Nathalie Saint-Cricq",
         "Françoise Fressoz",
         "Alexandra Bensaid"
       ]
     },
     sources: [%{rss_feed: %{url: "https://radiofrance-podcast.net/podcast09/rss_16170.xml"}}],
     channels: [MediaWatchInventory.Channel.FranceInter]},
    {MediaWatchInventory.Item.LInterviewPolitiqueLCI,
     show: %{
       name: "L'interview politique",
       url: "https://www.lci.fr/emission/l-interview-politique-12190/",
       airing_schedule: "30 8 * * MON-FRI",
       duration_minutes: 20,
       host_names: ["Elizabeth Martichoux"]
     },
     sources: [
       %{web_index_page: %{url: "https://www.lci.fr/emission/l-interview-politique-12190/"}}
     ],
     channels: [MediaWatchInventory.Channel.LCI]},
    {MediaWatchInventory.Item.CAVous,
     show: %{
       name: "C à vous",
       url: "https://www.france.tv/france-5/c-a-vous/",
       airing_schedule: "0 19 * * MON-FRI",
       duration_minutes: 55,
       host_names: ["Anne-Elisabeth Lemoine"],
       columnists: [
         "Patrick Cohen",
         "Bertrand Chameroy",
         "Pierre Lescure",
         "Marion Ruggieri",
         "Emilie Tran NGuyen",
         "Mohamed Bouhafsi",
         "Matthieu Belliard"
       ]
     },
     sources: [
       %{web_index_page: %{url: "https://www.france.tv/france-5/c-a-vous/"}}
     ],
     channels: [MediaWatchInventory.Channel.France5]},
    {MediaWatchInventory.Item.RuthElkrief2022,
     show: %{
       name: "Ruth Elkrief 2022",
       url: "https://www.lci.fr/emission/ruth-elkrief-2022-12712/",
       airing_schedule: "0 20 * * MON-THU",
       duration_minutes: 110,
       host_names: ["Ruth Elkrief"]
     },
     sources: [
       %{web_index_page: %{url: "https://www.lci.fr/emission/ruth-elkrief-2022-12712/"}}
     ],
     channels: [MediaWatchInventory.Channel.LCI]},
    {MediaWatchInventory.Item.BercoffDansTousSesEtats,
     show: %{
       name: "Bercoff dans tous ses états",
       url: "https://www.sudradio.fr/programme/andre-bercoff-dans-tous-ses-etats",
       airing_schedule: "0 12 * * MON-FRI",
       duration_minutes: 120,
       host_names: ["André Bercoff"]
     },
     sources: [
       %{
         web_index_page: %{
           url: "https://www.sudradio.fr/programme/andre-bercoff-dans-tous-ses-etats"
         }
       }
     ],
     channels: [MediaWatchInventory.Channel.SudRadio]},
    {MediaWatchInventory.Item.LesIrreductibles,
     show: %{
       name: "Les irréductibles",
       url: "https://www.sudradio.fr/programme/les-irreductibles",
       airing_schedule: "0 11 * * SUN",
       duration_minutes: 60,
       host_names: ["Alexandre Devecchio"]
     },
     sources: [
       %{
         web_index_page: %{
           url: "https://www.sudradio.fr/programme/les-irreductibles"
         }
       }
     ],
     channels: [MediaWatchInventory.Channel.SudRadio]}
  ],
  channels: [
    {MediaWatchInventory.Channel.France5,
     name: "France 5", url: "https://www.france.tv/france-5/"},
    {MediaWatchInventory.Channel.FranceInter,
     name: "France Inter", url: "https://www.franceinter.fr"},
    {MediaWatchInventory.Channel.FranceCulture,
     name: "France Culture", url: "https://www.franceculture.fr"},
    {MediaWatchInventory.Channel.FranceInfo,
     name: "France Info", url: "https://www.francetvinfo.fr"},
    {MediaWatchInventory.Channel.LCI, name: "LCI", url: "https://www.lci.fr"},
    {MediaWatchInventory.Channel.RTL, name: "RTL", url: "https://www.rtl.fr"},
    {MediaWatchInventory.Channel.RMC, name: "RMC", url: "https://rmc.bfmtv.com/"},
    {MediaWatchInventory.Channel.Europe1, name: "Europe 1", url: "https://www.europe1.fr"},
    {MediaWatchInventory.Channel.SudRadio, name: "Sud Radio", url: "https://www.sudradio.fr"}
  ]
