declare
    user_list     dbms_sql.varchar2_table;
    user_does_not_exist exception;
    pragma exception_init(user_does_not_exist, -1918);
begin
    if '${CWMS_TEST_USERS}' = 'create' then
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

        for i in 1..user_list.count loop
            begin
                execute immediate 'drop user ${CWMS_OFFICE_EROC}' || user_list(i);
            exception
              when user_does_not_exist then null;
            end;

            execute immediate 'create user ${CWMS_OFFICE_EROC}' || user_list(i) || ' identified by "${test_password}"';

            execute immediate 'grant create session to ${CWMS_OFFICE_EROC}' || user_list(i);
            execute immediate 'grant set container to ${CWMS_OFFICE_EROC}' || user_list(i);
        end loop;
        execute immediate 'grant execute on cwms_upass to ${CWMS_OFFICE_EROC}hectest_up';
    end if;
end;
/
    /*drop user ${CWMS_OFFICE_EROC}hectest;
    drop user ${CWMS_OFFICE_EROC}hectest_ro;
    drop user ${CWMS_OFFICE_EROC}.hectest_up;
    drop user ${CWMS_OFFICE_EROC}.hectest_db;
    drop user ${CWMS_OFFICE_EROC}.hectest_ua;
    drop user ${CWMS_OFFICE_EROC}.hectest_pu;
    drop user ${CWMS_OFFICE_EROC}.hectest_ru;
    drop user ${CWMS_OFFICE_EROC}.hectest_dx;
    drop user ${CWMS_OFFICE_EROC}.hectest_da;
    drop user ${CWMS_OFFICE_EROC}.hectest_vt;
    drop user ${CWMS_OFFICE_EROC}.hectest_dv;
    drop user ${CWMS_OFFICE_EROC}.hectest_ccp_p;
    drop user ${CWMS_OFFICE_EROC}.hectest_ccp_m;
    drop user ${CWMS_OFFICE_EROC}.hectest_ccp_r;
    drop user ${CWMS_OFFICE_EROC}.hectest_rdl_m;
    drop user ${CWMS_OFFICE_EROC}.hectest_rdl_r;
    */

    -- create user for UPASS Admin
    /*
    create user ${CWMS_OFFICE_EROC}.hectest_up identified by "${test_password}";
    grant execute on cwms_upass to ${CWMS_OFFICE_EROC}.hectest_up;
    grant create session to ${CWMS_OFFICE_EROC}.hectest_up;
    grant set container to ${CWMS_OFFICE_EROC}.hectest_up;
    create user ${CWMS_OFFICE_EROC}.hectest identified by "${TEST_PASSWORD}";
    grant create session to ${CWMS_OFFICE_EROC}.hectest;
    grant set container to ${CWMS_OFFICE_EROC}.hectest;
    create user ${CWMS_OFFICE_EROC}.hectest_ro identified by "${TEST_PASSWORD}";
    grant create session to ${CWMS_OFFICE_EROC}.hectest_ro;
    grant set container to ${CWMS_OFFICE_EROC}.hectest_ro;
    create user ${CWMS_OFFICE_EROC}.hectest_db identified by "${TEST_PASSWORD}";
    grant create session to ${CWMS_OFFICE_EROC}.hectest_db;
    grant set container to ${CWMS_OFFICE_EROC}.hectest_db;
    create user ${CWMS_OFFICE_EROC}.hectest_ua identified by "${TEST_PASSWORD}";
    grant create session to ${CWMS_OFFICE_EROC}.hectest_ua;
    grant set container to ${CWMS_OFFICE_EROC}.hectest_ua;
    create user ${CWMS_OFFICE_EROC}.hectest_pu identified by "${TEST_PASSWORD}";
    grant create session to ${CWMS_OFFICE_EROC}.hectest_pu;
    grant set container to ${CWMS_OFFICE_EROC}.hectest_pu;
    create user ${CWMS_OFFICE_EROC}.hectest_dx identified by "${TEST_PASSWORD}";
    grant create session to ${CWMS_OFFICE_EROC}.hectest_dx;
    grant set container to ${CWMS_OFFICE_EROC}.hectest_dx;
    create user ${CWMS_OFFICE_EROC}.hectest_da identified by "${TEST_PASSWORD}";
    grant create session to ${CWMS_OFFICE_EROC}.hectest_da;
    grant set container to ${CWMS_OFFICE_EROC}.hectest_da;
    create user ${CWMS_OFFICE_EROC}.hectest_vt identified by "${TEST_PASSWORD}";
    grant create session to ${CWMS_OFFICE_EROC}.hectest_vt;
    grant set container to ${CWMS_OFFICE_EROC}.hectest_vt;
    create user ${CWMS_OFFICE_EROC}.hectest_dv identified by "${TEST_PASSWORD}";
    grant create session to ${CWMS_OFFICE_EROC}.hectest_dv;
    grant set container to ${CWMS_OFFICE_EROC}.hectest_dv;
    create user ${CWMS_OFFICE_EROC}.hectest_ccp_p identified by "${TEST_PASSWORD}";
    grant create session to ${CWMS_OFFICE_EROC}.hectest_ccp_p;
    grant set container to ${CWMS_OFFICE_EROC}.hectest_ccp_p;
    create user ${CWMS_OFFICE_EROC}.hectest_ccp_m identified by "${TEST_PASSWORD}";
    grant create session to ${CWMS_OFFICE_EROC}.hectest_ccp_m;
    grant set container to ${CWMS_OFFICE_EROC}.hectest_ccp_m;
    create user ${CWMS_OFFICE_EROC}.hectest_ccp_r identified by "${TEST_PASSWORD}";
    grant create session to ${CWMS_OFFICE_EROC}.hectest_ccp_r;
    grant set container to ${CWMS_OFFICE_EROC}.hectest_ccp_r;
    create user ${CWMS_OFFICE_EROC}.hectest_rdl_r identified by "${TEST_PASSWORD}";
    grant create session to ${CWMS_OFFICE_EROC}.hectest_rdl_r;
    grant set container to ${CWMS_OFFICE_EROC}.hectest_rdl_r;
    create user ${CWMS_OFFICE_EROC}.hectest_rdl_m identified by "${TEST_PASSWORD}";
    grant create session to ${CWMS_OFFICE_EROC}.hectest_rdl_m;
    grant set container to ${CWMS_OFFICE_EROC}.hectest_rdl_m;
*/
