select substr(r.location_id,0,16),
  '"',substr(r.rating_id,0,100),'",',
  min(rv.ind_value_1),',',max(rv.ind_value_1),',',
  min(rv.ind_value_2),',',max(rv.ind_value_2),',',
  min(rv.dep_value),',',max(rv.dep_value),','

from av_rating_values_native rv
inner join av_rating r on (rv.rating_code = r.rating_code and r.location_id = 'KEYS')

group by substr(r.location_id,0,16), '"', substr(r.rating_id,0,100), '",', ',', ',', ',', ',', ',', ',';