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
    PROCEDURE check_dynamic_sql (p_sql IN VARCHAR)
    IS
        l_sql_no_quotes   VARCHAR2 (32767);

        FUNCTION remove_quotes (p_text IN VARCHAR2)
            RETURN VARCHAR2
        AS
            l_test     VARCHAR2 (32767);
            l_result   VARCHAR2 (32767);
            l_pos      PLS_INTEGER;
        BEGIN
            l_test := p_text;

            LOOP
                l_pos := REGEXP_INSTR (l_test, '[''"]');

                IF l_pos > 0
                THEN
                    IF SUBSTR (l_test, l_pos, 1) = '"'
                    THEN
                        ------------------------
                        -- double-quote first --
                        ------------------------
                        l_result :=
                            REGEXP_REPLACE (l_test,
                                            '"[^"]*?"',
                                            '#',
                                            1,
                                            1);
                        l_result :=
                            REGEXP_REPLACE (l_result,
                                            '''[^'']*?''',
                                            '$',
                                            1,
                                            1);
                    ELSE
                        ------------------------
                        -- single-quote first --
                        ------------------------
                        l_result :=
                            REGEXP_REPLACE (l_test,
                                            '''[^'']*?''',
                                            '$',
                                            1,
                                            1);
                        l_result :=
                            REGEXP_REPLACE (l_result,
                                            '"[^"]*?"',
                                            '#',
                                            1,
                                            1);
                    END IF;
                ELSE
                    -----------------------
                    -- no quotes in text --
                    -----------------------
                    l_result := l_test;
                END IF;

                EXIT WHEN l_result = l_test;
                l_test := l_result;
            END LOOP;

            RETURN l_result;
        END;
    BEGIN
        l_sql_no_quotes := remove_quotes (p_sql);

        IF REGEXP_INSTR (l_sql_no_quotes, '([''";]|--|/\*)') > 0
        THEN
            raise_application_error (-20998,
                                     'ERROR: UNSAFE DYNAMIC SQL : ' || p_sql);
        END IF;
    END check_dynamic_sql;


    PROCEDURE lock_db_account (p_username IN VARCHAR2 DEFAULT NULL)
    AS
        l_sql_string   VARCHAR2 (400);
    BEGIN
        l_sql_string := 'ALTER user ' || p_username || ' account lock';
        --DBMS_OUTPUT.put_line (l_sql_string);
        check_dynamic_sql (l_sql_string);

        EXECUTE IMMEDIATE l_sql_string;
    END;

    PROCEDURE unlock_db_account (p_username IN VARCHAR2 DEFAULT NULL)
    AS
        l_sql_string   VARCHAR2 (400);
    BEGIN
        l_sql_string := 'ALTER user ' || p_username || ' account unlock';
        --DBMS_OUTPUT.put_line (l_sql_string);
        check_dynamic_sql (l_sql_string);

        EXECUTE IMMEDIATE l_sql_string;
    END;



    PROCEDURE grant_cwms_permissions (p_username IN VARCHAR2)
    AS
        l_sql_string   VARCHAR2 (400);
    BEGIN
        l_sql_string :=
            'GRANT CWMS_USER TO ' || DBMS_ASSERT.simple_sql_name (p_username);
        --DBMS_OUTPUT.put_line (l_sql_string);
        check_dynamic_sql (l_sql_string);

        EXECUTE IMMEDIATE l_sql_string;

        l_sql_string :=
               'ALTER USER  '
            || DBMS_ASSERT.simple_sql_name (p_username)
            || ' PROFILE CWMS_PROF';
        --DBMS_OUTPUT.put_line (l_sql_string);
        check_dynamic_sql (l_sql_string);

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
