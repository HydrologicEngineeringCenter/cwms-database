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
           7,
           to_date ('04SEP2020', 'DDMONYYYY'),
           'CWMS Database Release 18.1.7',
           'PKI column changes; Add yearly tables; get_user_tab function added;'
          );
   commit;
end;
/

