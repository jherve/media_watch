# MediaWatch

## Overview

**See a live version here** : https://media.herve.info/

This project is my attempt at a quasi-automated system that figures out who was invited and when on various French radio/TV political shows, with as little human intervention as possible.

The goal is to replicate the basic functionality of this website : https://www.politiquemedia.com/

## Technical details

In more details, this application runs on a server 24/7 and regularly polls an inventory of various sources with vastly different layouts (xml podcast feed, html pages, ...) in order to extract relevant information. This information is stored in a structured SQLite database and presented on a website.

It is currently capable of :

* making snapshots of the data published for each show
* retrieving the shows' metadata (its name, a banner, ...) by HTML parsing
* making regular snapshots of the data published for each occurrence of a show
* retrieving the metadata for each occurrence of a show (the title, a summary, ...)
* extracting a list of guests
* presenting all this information in a website (with a page per show / day / person)

### Automated extraction of guest information

It is a trivial task for a human-being to tell which guests were invited in a given show by just reading the show's webpage or simply listening to/watching some seconds of it.

The whole challenge of this project is to automate as much of this process as possible, but it remains quite fuzzy and incertain.

Firstly because some sources won't even publish any relevant information in text form about each show (see e.g. [this show](https://www.radiofrance.fr/franceinter/podcasts/le-duel-natacha-polony-gilles-finchelstein) that displays the same exact headline/summary every week).

Secondly because when they do, it is done in natural language (e.g. "Notre invité aujourd'hui est NOM_DE_L_INVITE", "Ce matin nous accueillons NOM_DE_L_INVITE", "NOM_DE_L_INVITE : 'Ce qu'a dit X est inacceptable'") ; it therefore requires some analysis that is quite hard to automate (currently done with NLP provided by the open-source library [spaCy](https://spacy.io/)).

Third because the name of the guests is never presented in a consistent way ; a given person will appear as "Firstname Lastname", or "F. Lastname", or "M./Mme Lastname" or even sometimes only "Lastname". [Wikidata's API](https://www.wikidata.org/w/api.php) has been used to try and ensure consistency.

### Maintenance costs

Please note that, even though the goal is to minimize human intervention, this project still requires some maintenance in order to keep on working reliably on long-term, mainly :

* validating the data guessed by the NLP pipeline (should be done on a daily basis)
* updating the inventory (e.g. when a show's podcast URL changes)
* updating the parsing process (e.g. when the layout of a show's main page changes)

This lack of maintenance explains why some information is wrong or has stopped updating in the live version, though it has been running consistently for ~1.5yr.

## Connect as admin [reminder for future me]

1. Run a remote Elixir shell on the host machine : `sudo su media_watch -c "/home/media_watch/otp/bin/media_watch remote"`
1. Generate an admin_key `MediaWatch.Auth.generate_admin_key()`
1. Login to the site using URL "/admin?token=xxxx"
