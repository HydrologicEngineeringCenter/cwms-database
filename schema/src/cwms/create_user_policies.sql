BEGIN
    for c IN (select table_name from user_tables WHERE table_name <> 'AT_SEC_SESSION')
    loop
        BEGIN
          DBMS_RLS.DROP_POLICY(
        object_schema    => '&cwms_schema',
        object_name      => c.table_name,
        policy_name      => 'SERVICE_USER_POLICY');
       EXCEPTION WHEN OTHERS THEN
        NULL;
       END;

        DBMS_RLS.ADD_POLICY (
        object_schema    => '&cwms_schema',
        object_name      => c.table_name,
        policy_name      => 'SERVICE_USER_POLICY',
        function_schema  => '&cwms_schema',
        policy_function  => 'CWMS_SEC_POLICY.CHECK_SESSION_USER',
        policy_type      => DBMS_RLS.SHARED_CONTEXT_SENSITIVE,
        statement_types  => 'select');
    end loop;

    -- allow PD and DBA users to view the av_sec views
    for c IN (select view_name from user_views where view_name like 'AV_SEC%')
    loop
        BEGIN
          DBMS_RLS.DROP_POLICY(
        object_schema    => '&cwms_schema',
        object_name      => c.view_name,
        policy_name      => 'ADMIN_VIEW_POLICY');
       EXCEPTION WHEN OTHERS THEN
        NULL;
       END;

        DBMS_RLS.ADD_POLICY (
        object_schema    => '&cwms_schema',
        object_name      => c.view_name,
        policy_name      => 'ADMIN_VIEW_POLICY',
        function_schema  => '&cwms_schema',
        policy_function  => 'CWMS_SEC_POLICY.CHECK_IS_PD_OR_DBA',
        policy_type      => DBMS_RLS.SHARED_CONTEXT_SENSITIVE,
        statement_types  => 'select');
    end loop;
    
END;
/
