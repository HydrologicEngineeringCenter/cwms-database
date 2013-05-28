/* Formatted on 7/6/2009 7:18:08 AM (QP5 v5.115.810.9015) */
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

create or replace context cwms_env using set_cwms_env;
/

CREATE OR REPLACE PROCEDURE set_cwms_env (p_attribute   IN VARCHAR2,
                                          p_value       IN VARCHAR2)
IS
   l_namespace   VARCHAR2 (30) := 'CWMS_ENV';
   l_attribute   VARCHAR2 (30) := NULL;
   l_value       VARCHAR2 (4000) := NULL;
BEGIN
   l_attribute := p_attribute;
   l_value := p_value;

   DBMS_SESSION.set_context (l_namespace, l_attribute, l_value);
   
END set_cwms_env;
/
