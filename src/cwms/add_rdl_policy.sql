CREATE OR REPLACE FUNCTION RDL_FILTER (p_schema   IN VARCHAR2,
                                       p_table    IN VARCHAR2)
   RETURN VARCHAR2
IS
   l_ret     VARCHAR2 (400);
   l_count   NUMBER;
BEGIN
   SELECT COUNT (*)
     INTO l_count
     FROM dba_roles
    WHERE role IN ('RDLREAD', 'RDLCRUD');

   IF (l_count <> 2)
   THEN
      l_ret := 'user_group_id NOT IN (''RDL Reviewer'',''RDL Mgr'')';
   ELSE
      l_ret := '1=1';
   END IF;

   RETURN l_ret;
END RDL_FILTER;
/

BEGIN
  DBMS_RLS.ADD_POLICY (
    object_schema    => 'CWMS_20',
    object_name      => 'AT_SEC_USER_GROUPS',
    policy_name      => 'rdl_policy',
    function_schema  => 'CWMS_20',
    policy_function  => 'RDL_FILTER',
    statement_types  => 'select'
   );
 END;
/
