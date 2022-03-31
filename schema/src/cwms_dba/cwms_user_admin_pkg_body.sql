CREATE OR REPLACE PACKAGE BODY CWMS_DBA.cwms_user_admin
AS
    /******************************************************************************
    NAME:   cwms_admin
    PURPOSE:

      REVISIONS:
     Ver   Date   Author     Description
    --------- ---------- --------------- ------------------------------------
    1.0    10/6/2008     1. Created this package body.
    ******************************************************************************/


    PROCEDURE lock_db_account (p_username IN VARCHAR2 DEFAULT NULL)
    AS
        l_sql_string   VARCHAR2 (400);
    BEGIN
        l_sql_string := 'ALTER user ' || p_username || ' account lock';
        --DBMS_OUTPUT.put_line (l_sql_string);
        cwms_util.check_dynamic_sql (l_sql_string);

        EXECUTE IMMEDIATE l_sql_string;
    END;

    PROCEDURE unlock_db_account (p_username IN VARCHAR2 DEFAULT NULL)
    AS
        l_sql_string   VARCHAR2 (400);
	l_status VARCHAR2(64);
    BEGIN
	l_sql_string := 'SELECT account_status FROM dba_users where username='''||p_username||'''';
        cwms_util.check_dynamic_sql (l_sql_string);
	execute immediate l_sql_string into l_status;
	if(l_status = 'LOCKED')
	then
          l_sql_string := 'ALTER user ' || p_username || ' account unlock';
          --DBMS_OUTPUT.put_line (l_sql_string);
          cwms_util.check_dynamic_sql (l_sql_string);

          EXECUTE IMMEDIATE l_sql_string;
	end if;
    END;


    PROCEDURE grant_cwms_permissions (p_username IN VARCHAR2)
    AS
        l_sql_string   VARCHAR2 (400);
    BEGIN

        l_sql_string :=
               'ALTER USER  '
            || DBMS_ASSERT.simple_sql_name (p_username)
            || ' PROFILE CWMS_PROF';
        --DBMS_OUTPUT.put_line (l_sql_string);
        cwms_util.check_dynamic_sql (l_sql_string);

        EXECUTE IMMEDIATE l_sql_string;
    END;



    PROCEDURE grant_rdl_role (p_role VARCHAR2, p_username VARCHAR2)
    IS
        l_cmd   VARCHAR2 (64);
    BEGIN
        l_cmd := 'GRANT ' || p_role || ' TO ' || p_username;

        EXECUTE IMMEDIATE l_cmd;
    EXCEPTION
        WHEN OTHERS
        THEN
            NULL;
    END grant_rdl_role;

    PROCEDURE revoke_rdl_role (p_role VARCHAR2, p_username VARCHAR2)
    IS
        l_cmd   VARCHAR2 (64);
    BEGIN
        BEGIN
            l_cmd := 'REVOKE ' || p_role || ' FROM ' || p_username;

            EXECUTE IMMEDIATE l_cmd;
        EXCEPTION
            WHEN OTHERS
            THEN
                NULL;
        END;
    END revoke_rdl_role;

    PROCEDURE update_service_password (p_username   VARCHAR2,
                                       p_password   VARCHAR2)
    IS
        l_cmd   VARCHAR2 (128);
    BEGIN
        l_cmd :=
               'ALTER USER '
            || p_username
            || ' IDENTIFIED BY "'
            || p_password
            || '"';

        EXECUTE IMMEDIATE l_cmd;
    END update_service_password;
END cwms_user_admin;
/
