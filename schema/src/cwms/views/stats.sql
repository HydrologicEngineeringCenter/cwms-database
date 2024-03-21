create or replace view stats (
   name,
   value)
as 
   select 'STAT...' || a.name name,
          b.value
     from v$statname a,
          v$mystat b
    where a.statistic# = b.statistic#
    union all
   select 'LATCH..' || name,
          gets
     from v$latch
    union all
   select 'STAT...Elapsed Time', 
          hsecs
     from v$timer;

