----------------------------------------------------------
-- verify that the schema is the version that we expect --
----------------------------------------------------------
begin
   for rec in
      (select version,
              to_char(version_date, 'DDMONYYYY') as version_date
         from &cwms_schema..av_db_change_log
        where version_date = (select max(version_date) from &cwms_schema..av_db_change_log where application = 'CWMS')
      )
   loop
      if rec.version !=  '18.1.18' then
        cwms_err.raise('ERROR', 'Expected version 18.1.18, got version '||rec.version||' ('||rec.version_date||')');
      end if;
   end loop;
end;
/

