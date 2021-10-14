use Mix.Config

config :media_watch, MediaWatch.Catalog,
  items: [
    {MediaWatch.Catalog.Item.Le8h30FranceInfo,
     show: %{
       name: "8h30 franceinfo",
       url: "https://www.francetvinfo.fr/replay-radio/8h30-fauvelle-dely/",
       airing_schedule: "30 8 * * *",
       duration_minutes: 25
     },
     sources: [%{rss_feed: %{url: "https://radiofrance-podcast.net/podcast09/rss_16370.xml"}}],
     channels: [MediaWatch.Catalog.Channel.FranceInfo]},
    {MediaWatch.Catalog.Item.BourdinDirect,
     show: %{
       name: "Bourdin Direct",
       url: "https://rmc.bfmtv.com/emission/bourdin-direct/",
       airing_schedule: "35 8 * * MON-FRI",
       duration_minutes: 25
     },
     sources: [%{rss_feed: %{url: "https://podcast.rmc.fr/channel30/RMCInfochannel30.xml"}}],
     channels: [MediaWatch.Catalog.Channel.RMC]},
    {MediaWatch.Catalog.Item.Invite7h50,
     show: %{
       name: "L'invité de 7h50",
       url: "https://www.franceinter.fr/emissions/invite-de-7h50",
       airing_schedule: "50 7 * * MON-FRI",
       duration_minutes: 10
     },
     sources: [%{rss_feed: %{url: "http://radiofrance-podcast.net/podcast09/rss_11710.xml"}}],
     channels: [MediaWatch.Catalog.Channel.FranceInter]},
    {MediaWatch.Catalog.Item.Invite8h20,
     show: %{
       name: "L'invité de 8h20'",
       url: "https://www.franceinter.fr/emissions/l-invite",
       airing_schedule: "20 8 * * MON-FRI",
       duration_minutes: 25
     },
     sources: [%{rss_feed: %{url: "http://radiofrance-podcast.net/podcast09/rss_10239.xml"}}],
     channels: [MediaWatch.Catalog.Channel.FranceInter]},
    {MediaWatch.Catalog.Item.InviteDesMatins,
     show: %{
       name: "L'Invité(e) des Matins",
       url: "https://www.franceculture.fr/emissions/linvite-des-matins",
       airing_schedule: "40 7 * * MON-FRI",
       duration_minutes: 45
     },
     sources: [%{rss_feed: %{url: "https://radiofrance-podcast.net/podcast09/rss_13983.xml"}}],
     channels: [MediaWatch.Catalog.Channel.FranceCulture]},
    {MediaWatch.Catalog.Item.InviteRTL,
     show: %{
       name: "L'invité de RTL",
       url: "https://www.rtl.fr/programmes/l-invite-de-rtl",
       airing_schedule: "45 7 * * MON-FRI",
       duration_minutes: 10
     },
     sources: [%{rss_feed: %{url: "https://www.rtl.fr/podcast/linvite-de-rtl.xml"}}],
     channels: [MediaWatch.Catalog.Channel.RTL]},
    {MediaWatch.Catalog.Item.InviteRTLSoir,
     show: %{
       name: "L'invité de RTL Soir",
       url: "https://www.rtl.fr/programmes/l-invite-de-rtl-soir",
       airing_schedule: "20 18 * * MON-FRI",
       duration_minutes: 10
     },
     sources: [%{rss_feed: %{url: "https://www.rtl.fr/podcast/l-invite-de-rtl-soir.xml"}}],
     channels: [MediaWatch.Catalog.Channel.RTL]},
    {MediaWatch.Catalog.Item.LaGrandeTableIdees,
     show: %{
       name: "La Grande Table idées",
       url: "https://www.franceculture.fr/emissions/la-grande-table-2eme-partie",
       airing_schedule: "55 12 * * MON-FRI",
       duration_minutes: 35
     },
     sources: [%{rss_feed: %{url: "https://radiofrance-podcast.net/podcast09/rss_12360.xml"}}],
     channels: [MediaWatch.Catalog.Channel.FranceCulture]},
    {MediaWatch.Catalog.Item.LeGrandFaceAFace,
     show: %{
       name: "Le Grand Face-à-face",
       url: "https://www.franceinter.fr/emissions/le-grand-face-a-face",
       airing_schedule: "0 12 * * SAT",
       duration_minutes: 55
     },
     sources: [%{rss_feed: %{url: "https://radiofrance-podcast.net/podcast09/rss_18558.xml"}}],
     channels: [MediaWatch.Catalog.Channel.FranceInter]},
    {MediaWatch.Catalog.Item.LeGrandRendezVous,
     show: %{
       name: "Le grand rendez-vous",
       url: "https://www.europe1.fr/emissions/Le-grand-rendez-vous",
       airing_schedule: "0 10 * * SUN",
       duration_minutes: 45
     },
     sources: [
       %{rss_feed: %{url: "https://www.europe1.fr/rss/podcasts/le-grand-rendez-vous.xml"}}
     ],
     channels: [MediaWatch.Catalog.Channel.Europe1]},
    {MediaWatch.Catalog.Item.LInterviewPolitique,
     show: %{
       name: "L'interview politique",
       url: "https://www.europe1.fr/emissions/linterview-politique-de-8h20",
       airing_schedule: "14 8 * * MON-FRI",
       duration_minutes: 15
     },
     sources: [%{rss_feed: %{url: "https://www.europe1.fr/rss/podcasts/interview-8h20.xml"}}],
     channels: [MediaWatch.Catalog.Channel.Europe1]},
    {MediaWatch.Catalog.Item.QuestionsPolitiques,
     show: %{
       name: "Questions politiques",
       url: "https://www.franceinter.fr/emissions/questions-politiques",
       airing_schedule: "0 12 * * SUN",
       duration_minutes: 55
     },
     sources: [%{rss_feed: %{url: "https://radiofrance-podcast.net/podcast09/rss_16170.xml"}}],
     channels: [MediaWatch.Catalog.Channel.FranceInter]}
  ],
  channels: [
    {MediaWatch.Catalog.Channel.FranceInter,
     name: "France Inter", url: "https://www.franceinter.fr"},
    {MediaWatch.Catalog.Channel.FranceCulture,
     name: "France Culture", url: "https://www.franceculture.fr"},
    {MediaWatch.Catalog.Channel.FranceInfo,
     name: "France Info", url: "https://www.francetvinfo.fr"},
    {MediaWatch.Catalog.Channel.RTL, name: "RTL", url: "https://www.rtl.fr"},
    {MediaWatch.Catalog.Channel.RMC, name: "RMC", url: "https://rmc.bfmtv.com/"},
    {MediaWatch.Catalog.Channel.Europe1, name: "Europe 1", url: "https://www.europe1.fr"}
  ]