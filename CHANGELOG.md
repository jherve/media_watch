# Changelog

## In next version..

* UI: Add a UI changelog page
* UI: Update admin token handling to have admin flag available in all live views
* UI: Refresh occurrences/description in view when data has been added/updated by the workers
* Features: Schedule snapshots at airing moment for each item
* Internals: Clarify handling of async tasks in GenServers and start keeping track of
failures/errors

## 1.2.0 (2021-11-09)

* UI: Display items by channel in the index page
* UI: Allow admin access to live dashboard in production version
* Security: Make admin mode freely available in dev mode
* Internals: Rewrite writers' code and use GenServer's to improve reliability
and consistency in the execution of snapshot/parsing/... tasks

## 1.1.1 (2021-11-04)

* Security: Restrict access to admin panel via a signed token

## 1.1.0 (2021-11-04)

* UI: Move administrative tasks to an admin panel

## 1.0.0 (2021-11-04)

* First production release

## 0.1.0 (2021-07-19)

* Initial version
