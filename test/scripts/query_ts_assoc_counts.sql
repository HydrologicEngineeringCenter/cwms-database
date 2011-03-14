--delete -- select substr(prop_id, 0, 100), substr(prop_value,0,50)
--from at_properties
--where prop_category = 'LOCATION TIME SERIES ASSOCIATION';
---- and prop_id like '%Elev%';
--
--
select substr(p.prop_id,0,100), substr(mv.cwms_ts_id,0,50), count(*)
from av_tsv_dqu av
inner join mv_cwms_ts_id mv on (av.ts_code = mv.ts_code)
inner join at_properties p on (mv.cwms_ts_id = p.prop_value and p.prop_id like '%') 
where av.unit_id = 'ft' group by substr(p.prop_id,0,100), substr(mv.cwms_ts_id,0,50)


