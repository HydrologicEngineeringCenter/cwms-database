/* Formatted on 2008/10/06 14:18 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE BODY cwms_user_admin
AS
/******************************************************************************
   NAME:       cwms_admin
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        10/6/2008             1. Created this package body.
******************************************************************************/
   PROCEDURE lock_db_account (p_username IN VARCHAR2 DEFAULT NULL)
   AS
      l_sql_string   VARCHAR2 (400);
   BEGIN
      l_sql_string := 'ALTER user ' || p_username || ' account lock';
      DBMS_OUTPUT.put_line (l_sql_string);

      EXECUTE IMMEDIATE l_sql_string;
   END;

   PROCEDURE unlock_db_account (p_username IN VARCHAR2 DEFAULT NULL)
   AS
      l_sql_string   VARCHAR2 (400);
   BEGIN
      l_sql_string := 'ALTER user ' || p_username || ' account unlock';
      DBMS_OUTPUT.put_line (l_sql_string);

      EXECUTE IMMEDIATE l_sql_string;
   END;

   PROCEDURE create_cwms_db_account (
      p_username       IN   VARCHAR2,
      p_dbi_username   IN   VARCHAR2
   )
   AS
      l_sql_string   VARCHAR2 (400);
   BEGIN
      l_sql_string :=
            'create user '
         || p_username
         || ' PROFILE DEFAULT IDENTIFIED BY abc123abc123 
              DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP ACCOUNT UNLOCK';
      DBMS_OUTPUT.put_line (l_sql_string);

      EXECUTE IMMEDIATE l_sql_string;

      l_sql_string := 'GRANT CONNECT TO ' || p_username;
      DBMS_OUTPUT.put_line (l_sql_string);

      EXECUTE IMMEDIATE l_sql_string;

      l_sql_string := 'GRANT CWMS_USER TO ' || p_username;
      DBMS_OUTPUT.put_line (l_sql_string);

      EXECUTE IMMEDIATE l_sql_string;

      l_sql_string :=
            'ALTER user '
         || p_username
         || ' GRANT CONNECT THROUGH '
         || p_dbi_username;
      DBMS_OUTPUT.put_line (l_sql_string);

      EXECUTE IMMEDIATE l_sql_string;
   END;

   PROCEDURE delete_db_account (p_username IN VARCHAR2 DEFAULT NULL)
   AS
   BEGIN
      NULL;
   END;
END cwms_user_admin;
/