# Changelog

## 1.8.0 (2021-12-10)

* Internals: Change computation of airing time
* [BREAKING] Internals: Use a more precise and less costly unique index for snapshots

## 1.7.0 (2021-12-05)

* UI: Add a welcome page with various info summaries
* UI: Add an icon to display invitation confirmation status
* UI: Make the invitations' edit interface nicer
* UI: Display show schedule in "human language" (e.g. "on weekdays, at 7.30")
* Fix: When showing show occurrences for a given person, all the invitations are now displayed
* Fix: Snapshots that do not produce any new slice are now retried, which should
ensure more reliability for shows that publish their information rather late
* [BREAKING] Feature: Keep track of show occurrence and invitation duration
* [BREAKING] Internals: Rename some tables and add some fields that might eventually be useful

## 1.6.0 (2021-11-28)

* UI: Get rid of all "default" CSS and improve site design
* UI: Make site mobile-friendly
* UI: Make site [a bit more] accessible
* UI: Set page title to a relevant value instead of default
* [BREAKING] Internals: Review entity recognition and slice analysis
* Internals: Remove GenServers used in pipelines
* Fix: Resolve most dialyzer warnings

## 1.5.0 (2021-11-22)

* UI: Add a search-by-name feature in persons' index
* UI: Allow admins to add/delete invitations on each show
* UI: Add a toggle for admin commands
* [BREAKING] Internals: Mark show occurrences / invitations as auto edited or verified by hand
* Internals: Add "pipeline" modules for workers'  operations
* Internals: Wrap some operations into a database transaction, for consistency

## 1.4.0 (2021-11-16)

* Fix: Fix non-determinism bug in slice/occurrence association that made guest detection fuzzy
* Internals: Move complex kinda-stateful code into "operation" modules
* [BREAKING] Internals: Reorganize code into main/utils/inventory and change Item's modules
names
* Internals: Better separation of behaviours from implementations
* Internals: Insert all inventory items through a unique transaction on startup

## 1.3.1 (2021-11-12)

* Fix: Ensure only integer values are used in snapshot scheduling
* Internals: Keep track of pending snapshots

## 1.3.0 (2021-11-11)

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
