create table at_pool_backup as (select * from at_pool);
drop table at_pool;
@@../../cwms/tables/at_pool
insert
  into at_pool
       (pool_code,
        pool_name_code,
        project_code,
        bottom_level,
        top_level
       )
       (select * from at_pool_backup);
drop table at_pool_backup;

create or replace trigger st_pool 
   before delete or insert or update
   on at_pool 
   referencing new as new old as old
declare
   l_priv   VARCHAR2 (16);
begin
   select sys_context ('CWMS_ENV', 'CWMS_PRIVILEGE') into l_priv from dual;
   if ((l_priv is null or l_priv <> 'CAN_WRITE') and user not in ('SYS', 'CWMS_20')) then
      cwms_20.cwms_err.raise('NO_WRITE_PRIVILEGE');
   end if;
end;
/