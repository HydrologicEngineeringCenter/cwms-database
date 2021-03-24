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
           18,
           1,
           13,
           to_date ('24MAR2021', 'DDMONYYYY'),
           'CWMS Database Release 18.1.13',
           'Fixed bug in CWMS_UTIL.SPLIT_TEXT routines'
          );
   commit;
end;
/

