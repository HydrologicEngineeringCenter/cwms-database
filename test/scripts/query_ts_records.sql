select substr(p.prop_id,0,100), substr(mv.cwms_ts_id,0,50), av.date_time, av.value
from av_tsv_dqu av
inner join mv_cwms_ts_id mv on (av.ts_code = mv.ts_code)
inner join at_properties p on (mv.cwms_ts_id = p.prop_value and p.prop_id like 'Regi_project_OUTPUT.Elevation_elevation_pool_rev%') 
where av.unit_id = 'ft'
order by av.date_time desc;