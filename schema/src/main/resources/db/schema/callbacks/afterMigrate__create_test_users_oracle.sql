/**
    Due to the permissions model, if you add a new user you *must* also add them in the afterMigrate_create_test_uesr_cwms.sql
    script in the data folder.
*/
declare
    group_list ${CWMS_SCHEMA}.char_32_array_type := ${CWMS_SCHEMA}.char_32_array_type('CWMS PD Users');
    user_list     dbms_sql.varchar2_table;
    user_does_not_exist exception;
    user_exists exception;
    pragma exception_init(user_exists, -1920);
    pragma exception_init(user_does_not_exist, -1918);
begin
    if '${CWMS_TEST_USERS}' = 'create' then
        begin
            execute immediate 'create user ${CWMS_OFFICE_EROC}cwmspd identified by "${PD_PASSWORD}"';
            execute immediate 'grant create session to ${CWMS_OFFICE_EROC}cwmspd';
        exception
            when user_exists then null;
        end;

        user_list(1) := 'hectest';--,'hectest_ro','hectest_up,hectest_db,hectest_ua,hectest_pu,hectest_ru,hectest_dx,hec)";
        user_list(2) := 'hectest_ro';
        user_list(3) := 'hectest_up';
        user_list(4) := 'hectest_db';
        user_list(5) := 'hectest_ua';
        user_list(6) := 'hectest_pu';
        user_list(7) := 'hectest_ru';
        user_list(8) := 'hectest_dx';
        user_list(9) := 'hectest_da';
        user_list(10) := 'hectest_vt';
        user_list(11) := 'hectest_dv';
        user_list(12) := 'hectest_ccp_p';
        user_list(13) := 'hectest_ccp_m';
        user_list(14) := 'hectest_ccp_r';
        user_list(15) := 'hectest_rdl_m';
        user_list(16) := 'hectest_rdl_r';
        user_list(17) := 'webtest';

        for i in 1..user_list.count loop
            begin
                execute immediate 'drop user ${CWMS_OFFICE_EROC}' || user_list(i);
            exception
              when user_does_not_exist then null;
            end;

            execute immediate 'create user ${CWMS_OFFICE_EROC}' || user_list(i) || ' identified by "${test_password}"';

            execute immediate 'grant create session to ${CWMS_OFFICE_EROC}' || user_list(i);
        end loop;
        execute immediate 'grant execute on cwms_upass to ${CWMS_OFFICE_EROC}hectest_up';
        execute immediate 'grant web_user to ${CWMS_OFFICE_EROC}webtest';
    end if;
end;
/

DECLARE
   pd_group_list  "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE" := "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE"('CWMS PD Users');
   group_list     "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE";
BEGIN
   if '${CWMS_TEST_USERS}' = 'create' then
      "${CWMS_SCHEMA}"."CWMS_SEC"."ADD_CWMS_USER" ('${CWMS_OFFICE_EROC}cwmspd', pd_group_list, '${CWMS_OFFICE_ID}');

      "${CWMS_SCHEMA}"."CWMS_SEC"."ASSIGN_TS_GROUP_USER_GROUP" ('All Rev TS IDs', 'Viewer Users', 'Read', '${CWMS_OFFICE_ID}');

      "${CWMS_SCHEMA}"."CWMS_SEC"."ASSIGN_TS_GROUP_USER_GROUP" ('All TS IDs', 'CWMS Users', 'Read-Write', '${CWMS_OFFICE_ID}');

         group_list := "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE" ('TS ID Creator', 'CWMS Users');
         "${CWMS_SCHEMA}"."CWMS_SEC"."ADD_CWMS_USER" ('${CWMS_OFFICE_EROC}hectest', group_list, '${CWMS_OFFICE_ID}');
         --
         -- hectest_ro
         group_list := "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE" ('CWMS Users', 'Viewer Users');
         "${CWMS_SCHEMA}"."CWMS_SEC"."ADD_CWMS_USER" ('${CWMS_OFFICE_EROC}hectest_ro', group_list, '${CWMS_OFFICE_ID}');
         --
         -- hectest_dba
         group_list := "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE" ('CWMS DBA Users');
         "${CWMS_SCHEMA}"."CWMS_SEC"."ADD_CWMS_USER" ('${CWMS_OFFICE_EROC}hectest_db', group_list, '${CWMS_OFFICE_ID}');
         --
         -- hectest_ua
         group_list := "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE" ('CWMS User Admins', 'TS ID Creator', 'Viewer Users');
         "${CWMS_SCHEMA}"."CWMS_SEC"."ADD_CWMS_USER" ('${CWMS_OFFICE_EROC}hectest_ua', group_list, '${CWMS_OFFICE_ID}');
         --
         -- hectest_pu
         group_list := "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE" ('CWMS User Admins', 'CWMS PD Users','TS ID Creator', 'Viewer Users');
         "${CWMS_SCHEMA}"."CWMS_SEC"."ADD_CWMS_USER" ('${CWMS_OFFICE_EROC}hectest_pu', group_list, '${CWMS_OFFICE_ID}');
         --
         -- hectest_dx
         group_list := "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE" ('Data Exchange Mgr', 'TS ID Creator', 'CWMS Users');
         "${CWMS_SCHEMA}"."CWMS_SEC"."ADD_CWMS_USER" ('${CWMS_OFFICE_EROC}hectest_dx', group_list, '${CWMS_OFFICE_ID}');
         --
         -- hectest_da
         group_list := "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE" ('Data Acquisition Mgr', 'TS ID Creator', 'CWMS Users');
         "${CWMS_SCHEMA}"."CWMS_SEC"."ADD_CWMS_USER" ('${CWMS_OFFICE_EROC}hectest_da', group_list, '${CWMS_OFFICE_ID}');
         --
         -- hectest_vt
         group_list := "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE" ('VT Mgr', 'TS ID Creator', 'CWMS Users');
         "${CWMS_SCHEMA}"."CWMS_SEC"."ADD_CWMS_USER" ('${CWMS_OFFICE_EROC}hectest_vt', group_list, '${CWMS_OFFICE_ID}');
         --
         -- hectest_dv
         group_list := "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE" ('Data Acquisition Mgr', 'VT Mgr', 'TS ID Creator', 'CWMS Users');
         "${CWMS_SCHEMA}"."CWMS_SEC"."ADD_CWMS_USER" ('${CWMS_OFFICE_EROC}hectest_dv', group_list, '${CWMS_OFFICE_ID}');
         --
         -- hectest_ccp_p
         group_list := "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE" ('CWMS PD Users', 'CCP Proc', 'TS ID Creator', 'CWMS Users');
         "${CWMS_SCHEMA}"."CWMS_SEC"."ADD_CWMS_USER" ('${CWMS_OFFICE_EROC}hectest_ccp_p', group_list, '${CWMS_OFFICE_ID}');
         --
         -- hectest_ccp_m
         group_list := "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE" ('CWMS PD Users', 'CCP Mgr', 'TS ID Creator', 'CWMS Users');
         "${CWMS_SCHEMA}"."CWMS_SEC"."ADD_CWMS_USER" ('${CWMS_OFFICE_EROC}hectest_ccp_m', group_list, '${CWMS_OFFICE_ID}');
         --
         -- hectest_ccp_r
         group_list := "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE" ('CWMS PD Users', 'CCP Reviewer', 'TS ID Creator', 'CWMS Users');
         "${CWMS_SCHEMA}"."CWMS_SEC"."ADD_CWMS_USER" ('${CWMS_OFFICE_EROC}hectest_ccp_r', group_list, '${CWMS_OFFICE_ID}');

         -- hectest_rdl_r
         group_list := "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE" ('CWMS PD Users', 'RDL Reviewer', 'TS ID Creator', 'CWMS Users');
         "${CWMS_SCHEMA}"."CWMS_SEC"."ADD_CWMS_USER" ('${CWMS_OFFICE_EROC}hectest_rdl_r', group_list, '${CWMS_OFFICE_ID}');
         -- hectest_rdl_m
         group_list := "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE" ('CWMS PD Users', 'RDL Mgr', 'TS ID Creator', 'CWMS Users');
         "${CWMS_SCHEMA}"."CWMS_SEC"."ADD_CWMS_USER" ('${CWMS_OFFICE_EROC}hectest_rdl_m', group_list, '${CWMS_OFFICE_ID}');

          -- webtest
        group_list := "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE" ('CWMS User Admins', 'CWMS PD Users','TS ID Creator', 'CWMS Users', 'CWMS DBA Users');
        "${CWMS_SCHEMA}"."CWMS_SEC"."ADD_CWMS_USER" ('${CWMS_OFFICE_EROC}webtest', group_list, '${CWMS_OFFICE_ID}');
        execute immediate 'grant web_user to ${CWMS_OFFICE_EROC}webtest';

        group_list := "${CWMS_SCHEMA}"."CHAR_32_ARRAY_TYPE" ('CWMS User Admins', 'CWMS PD Users','TS ID Creator', 'Viewer Users');
        "${CWMS_SCHEMA}"."CWMS_SEC"."ADD_CWMS_USER" ('${CWMS_OFFICE_EROC}.hectest_multioffice', group_list, '${CWMS_OFFICE_ID}');
        "${CWMS_SCHEMA}"."CWMS_SEC"."ADD_CWMS_USER" ('${CWMS_OFFICE_EROC}.hectest_multioffice', group_list, 'HQ');
        "${CWMS_SCHEMA}"."CWMS_SEC"."ADD_CWMS_USER" ('${CWMS_OFFICE_EROC}.hectest_multioffice', group_list, 'POA');
        
   end if;
END;
/
