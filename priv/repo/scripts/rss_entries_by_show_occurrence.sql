select re.guid, so.airing_time, i.module
from slices_usages su
join slices sl on su.slice_id = sl.id
join slices_rss_entries re on sl.id = re.id
join show_occurrences so on su.show_occurrence_id = so.id
join catalog_shows s on so.show_id = s.id
join catalog_items i on i.id = s.id
order by re.guid