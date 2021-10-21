declare
   l_database_id varchar2(30);
begin
   select nvl(primary_db_unique_name, db_unique_name)
     into l_database_id
     from v$database;

   insert
     into cwms_db_change_log
          (office_code,
           database_id,
           application,
           ver_major,
           ver_minor,
           ver_build,
           ver_date,
           title,
           description
          )
   values (cwms_util.user_office_code,
           l_database_id,
           'CWMS',
           99,
           99,
           99,
           to_date ('31DEC2200', 'DDMONYYYY'),
           'CWMS Database Release 99.99.99',
           'Updaed from 21.1.1'
          );
   commit;
end;
/

