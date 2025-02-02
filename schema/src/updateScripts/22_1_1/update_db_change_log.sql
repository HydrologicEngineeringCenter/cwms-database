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
           22,
           1,
           1,
           to_date ('21OCT2022', 'DDMONYYYY'),
           'CWMS Database Release 22.1.1',
           'Updated from 21.1.1/21.1.2/21.1.3' 
          );
   commit;
end;
/

