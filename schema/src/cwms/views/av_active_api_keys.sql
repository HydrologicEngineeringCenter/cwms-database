create or replace view av_active_api_keys as 
select
   key_id,
   userid,
   key_name,
   secret_hash,
   created,
   expires
from 
    at_api_keys ak
join at_sec_locked_users lu on lu.username = ak.userid
where 
    lu.is_locked = 'F'
    and
    ak.expires > ak.created;