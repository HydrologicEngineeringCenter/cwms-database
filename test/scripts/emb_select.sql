select o.office_id,bl.base_location_id, pl.sub_location_id, e.*
from at_embankment e, at_physical_location pl, at_base_location bl, cwms_office o
where
e.embankment_location_code = pl.location_code
and pl.base_location_code = bl.base_location_code
and bl.db_office_code = o.office_code