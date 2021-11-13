select so.airing_time, i.module, er.label
from slices sl
join slices_usages su on su.slice_id = sl.id
join show_occurrences so on so.id = su.show_occurrence_id
join catalog_sources s on sl.source_id = s.id
join catalog_items i on i.id = s.item_id
left join entities_recognized er on er.slice_id = sl.id
order by so.airing_time DESC, i.module, er.label
