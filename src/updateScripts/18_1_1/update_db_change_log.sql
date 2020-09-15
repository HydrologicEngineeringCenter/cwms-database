declare
   l_database_id varchar2(30);
begin
   select name
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
           1,
           to_date ('15AUG2018', 'DDMONYYYY'),
           'CWMS Database Release 18.1.1',
           'Multiple performance and functionality updates'
          );
   commit;
end;
/

