----------------------------------------------------------
-- verify that the schema is the version that we expect --
----------------------------------------------------------
-- Fix date for 18.1.7 release
update cwms_db_change_log set ver_date=to_date ('30NOV2020', 'DDMONYYYY') where application='CWMS' and ver_major=18 and ver_minor=1 and ver_build=7;
commit;
begin
   for rec in
      (select version,
              to_char(version_date, 'DDMONYYYY') as version_date
         from &cwms_schema..av_db_change_log
        where version_date = (select max(version_date) from &cwms_schema..av_db_change_log where application = 'CWMS')
      )
   loop
      if rec.version !=  '18.1.7' then
        cwms_err.raise('ERROR', 'Expected version 18.1.7, got version '||rec.version||' ('||rec.version_date||')');
      end if;
   end loop;
end;
/

