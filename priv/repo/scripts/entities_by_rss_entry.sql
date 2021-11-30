select re.guid, i.module, er.label
from slices sl
join slices_rss_entries re on re.id = sl.id
join catalog_sources s on sl.source_id = s.id
join catalog_items i on i.id = s.item_id
left join entities_recognized er on er.slice_id = sl.id
order by re.guid, i.module, er.label
