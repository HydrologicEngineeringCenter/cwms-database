CREATE OR REPLACE FUNCTION CHECK_SESSION_USER(
  schema_p   IN VARCHAR2,
  table_p    IN VARCHAR2)
 RETURN VARCHAR2
 AS

 BEGIN
   if dbms_mview.i_am_a_refresh then
   return null;
  end if;
  IF ((SYS_CONTEXT ('CWMS_ENV', 'CWMS_USER') IS NULL) AND (USER = cwms_sec.cac_service_user))
  THEN
    return '1=0';
  ELSE
    return '1=1';
  END IF;
END CHECK_SESSION_USER;
/

BEGIN
    for c IN (select table_name from user_tables WHERE table_name <> 'AT_SEC_SESSION')
    loop
        BEGIN
          DBMS_RLS.DROP_POLICY(
        object_schema    => '${CWMS_SCHEMA}',
        object_name      => c.table_name,
        policy_name      => 'SERVICE_USER_POLICY');
       EXCEPTION WHEN OTHERS THEN
        NULL;
       END;

        DBMS_RLS.ADD_POLICY (
        object_schema    => '${CWMS_SCHEMA}',
        object_name      => c.table_name,
        policy_name      => 'SERVICE_USER_POLICY',
        function_schema  => '${CWMS_SCHEMA}',
        policy_function  => 'CHECK_SESSION_USER',
        policy_type      => DBMS_RLS.SHARED_CONTEXT_SENSITIVE,
        statement_types  => 'select');
    end loop;
END;
/
