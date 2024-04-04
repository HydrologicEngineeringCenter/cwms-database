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
           24,
           04,
           05,
           to_date ('05APR2024', 'DDMONYYYY'),
           'CWMS Database Release 24.04.05',
           'Updated from 23.03.16'
          );
   commit;
end;
/

