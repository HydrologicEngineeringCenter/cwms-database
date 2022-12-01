create or replace view av_active_api_keys as 
select
   userid,
   key_name,
   apikey,
   created,
   expires
from 
    at_api_keys ak
join at_sec_locked_users lu on lu.username = ak.userid
where 
    lu.is_locked = 'F'
    and
    ak.expires > ak.created;