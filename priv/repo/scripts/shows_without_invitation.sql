select so.airing_time, i.module
from show_occurrences so
join catalog_shows s on so.show_id = s.id
join catalog_items i on i.id = s.id
left join show_occurrences_invitations soi on so.id = soi.show_occurrence_id
where soi.person_id IS NULL
order by so.airing_time DESC, s.name
