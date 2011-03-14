with calendar as (
     SELECT to_date('2000/01/10-08:00:00', 'yyyy/mm/dd-hh24:mi:ss') + (ROWNUM  - 1) * 1/96
       from dual
      CONNECT BY LEVEL <= (to_date('2011/01/10-08:00:00', 'yyyy/mm/dd-hh24:mi:ss') - to_date('2000/01/10-08:00:00', 'yyyy/mm/dd-hh24:mi:ss') + 1) * 96
)
select count(*) from calendar;