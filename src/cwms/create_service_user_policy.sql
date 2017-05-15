CREATE OR REPLACE FUNCTION CHECK_SESSION_USER(
  schema_p   IN VARCHAR2,
  table_p    IN VARCHAR2)
 RETURN VARCHAR2
 AS
  
 BEGIN
   if dbms_mview.i_am_a_refresh then
   return null;
  end if;
  IF ((SYS_CONTEXT ('CWMS_ENV', 'CWMS_USER') IS NULL) AND (USER = 'CWMS9999'))
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
        DBMS_RLS.ADD_POLICY (
        object_schema    => '&cwms_schema', 
        object_name      => c.table_name, 
        policy_name      => 'SERVICE_USER_POLICY', 
        function_schema  => '&cwms_schema',
        policy_function  => 'CHECK_SESSION_USER', 
        statement_types  => 'select');
    end loop;
END;
/

exec cwms_sec.create_cwms_service_user
