BEGIN
    for c IN (select table_name from all_tables WHERE owner = '${CWMS_SCHEMA}' and table_name <> 'AT_SEC_SESSION')
    loop
        BEGIN
          DBMS_RLS.DROP_POLICY(
        object_schema    => '${CWMS_SCHEMA}',
        object_name      => '"'||c.table_name||'"',
        policy_name      => 'SERVICE_USER_POLICY');
       EXCEPTION WHEN OTHERS THEN
        NULL;
       END;
      -- Quote table_name to make sure it's used exactly as provided.
        DBMS_RLS.ADD_POLICY (
        object_schema    => '${CWMS_SCHEMA}',
        object_name      => '"'||c.table_name||'"',
        policy_name      => 'SERVICE_USER_POLICY',
        function_schema  => '${CWMS_SCHEMA}',
        policy_function  => 'CWMS_SEC_POLICY.CHECK_SESSION_USER',
        policy_type      => DBMS_RLS.SHARED_CONTEXT_SENSITIVE,
        statement_types  => 'select');
    end loop;

    for c IN (select table_name from all_tables WHERE owner = '${CWMS_SCHEMA}' and table_name in ('CWMS_DURATION','CWMS_INTERVAL','CWMS_PARAMETER_TYPE'))
    loop
        BEGIN
          DBMS_RLS.DROP_POLICY(
        object_schema    => '${CWMS_SCHEMA}',
        object_name      => c.table_name,
        policy_name      => 'FILTER_'||c.table_name||'_POLICY');
       EXCEPTION WHEN OTHERS THEN
        NULL;
       END;

        DBMS_RLS.ADD_POLICY (
        object_schema    => '${CWMS_SCHEMA}',
        object_name      => c.table_name,
        policy_name      => 'FILTER_'||c.table_name||'_POLICY', 
        function_schema  => '${CWMS_SCHEMA}',
        policy_function  => 'CWMS_SEC_POLICY.'||c.table_name||'_FILTER',
        policy_type      => DBMS_RLS.SHARED_CONTEXT_SENSITIVE,
        statement_types  => 'select');
    end loop;

    for c IN (select view_name from all_views where owner = '${CWMS_SCHEMA}' and view_name like 'AV_SEC%')
    loop
        BEGIN
          DBMS_RLS.DROP_POLICY(
        object_schema    => '${CWMS_SCHEMA}',
        object_name      => c.view_name,
        policy_name      => 'ADMIN_VIEW_POLICY');
       EXCEPTION WHEN OTHERS THEN
        NULL;
       END;

        DBMS_RLS.ADD_POLICY (
        object_schema    => '${CWMS_SCHEMA}',
        object_name      => c.view_name,
        policy_name      => 'ADMIN_VIEW_POLICY',
        function_schema  => '${CWMS_SCHEMA}',
        policy_function  => 'CWMS_SEC_POLICY.CHECK_IS_PD_OR_DBA',
        policy_type      => DBMS_RLS.SHARED_CONTEXT_SENSITIVE,
        statement_types  => 'select');
    end loop;
    
END;
/
