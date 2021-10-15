/* Formatted on 7/10/2009 1:37:43 PM (QP5 v5.115.810.9015) */
CREATE OR REPLACE PACKAGE BODY cwms_dba.cwms_user_admin
AS
	/******************************************************************************
				NAME: 		cwms_admin
				PURPOSE:

				  REVISIONS:
				 Ver			Date			Author			  Description
		  --------- ----------	---------------	------------------------------------
				1.0		  10/6/2008 				1. Created this package body.
			 ******************************************************************************/
   procedure check_dynamic_sql(
      p_sql in varchar)
   is 
      l_sql_no_quotes varchar2(32767);
      
      function remove_quotes(p_text in varchar2) return varchar2
      as
         l_test varchar2(32767);
         l_result varchar2(32767);
         l_pos    pls_integer;
      begin
         l_test := p_text;
         loop
            l_pos := regexp_instr(l_test, '[''"]');
            if l_pos > 0 then
               if substr(l_test, l_pos, 1) = '"' then 
                  ------------------------
                  -- double-quote first --
                  ------------------------
                  l_result := regexp_replace(l_test, '"[^"]*?"', '#', 1, 1);
                  l_result := regexp_replace(l_result, '''[^'']*?''', '$', 1, 1);
               else
                  ------------------------
                  -- single-quote first --
                  ------------------------
                  l_result := regexp_replace(l_test, '''[^'']*?''', '$', 1, 1);
                  l_result := regexp_replace(l_result, '"[^"]*?"', '#', 1, 1);
               end if;
            else
              -----------------------
              -- no quotes in text --
              -----------------------
               l_result := l_test;
            end if;
            exit when l_result = l_test;
            l_test := l_result;
         end loop;
         return l_result;
      end;
   begin
      l_sql_no_quotes := remove_quotes(p_sql);
      if regexp_instr(l_sql_no_quotes, '([''";]|--|/\*)') > 0 then
         raise_application_error(-20998, 'ERROR: UNSAFE DYNAMIC SQL : '||p_sql);
      end if;
   end check_dynamic_sql;
         
   PROCEDURE lock_db_account (p_username IN VARCHAR2 DEFAULT NULL )
	AS
		l_sql_string						VARCHAR2 (400);
	BEGIN
		l_sql_string := 'ALTER user ' || p_username || ' account lock';
		--DBMS_OUTPUT.put_line (l_sql_string);
      check_dynamic_sql(l_sql_string);

		EXECUTE IMMEDIATE l_sql_string;
	END;

	PROCEDURE unlock_db_account (p_username IN VARCHAR2 DEFAULT NULL )
	AS
		l_sql_string						VARCHAR2 (400);
	BEGIN
		l_sql_string := 'ALTER user ' || p_username || ' account unlock';
		--DBMS_OUTPUT.put_line (l_sql_string);
      check_dynamic_sql(l_sql_string);

		EXECUTE IMMEDIATE l_sql_string;
	END;


	PROCEDURE create_db_account (p_username	IN VARCHAR2,
										  p_password	IN VARCHAR2
										 )
	AS
		l_sql_string						VARCHAR2 (400);
		l_username							VARCHAR2 (30);
		l_password							VARCHAR2 (50);
		l_account_status					VARCHAR2 (156) := NULL;
		l_username_exists 				BOOLEAN;
	BEGIN
		l_username := UPPER (TRIM (p_username));
		l_password := p_password;

		BEGIN
			SELECT	account_status
			  INTO	l_account_status
			  FROM	dba_users
			 WHERE	username = l_username;

			l_username_exists := TRUE;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				l_username_exists := FALSE;
		END;


		IF l_username_exists
		THEN
			IF l_account_status != 'OPEN'
			THEN
				l_sql_string := 'alter user ' || dbms_assert.simple_sql_name(l_username) || ' account unlock';
            check_dynamic_sql(l_sql_string);

				EXECUTE IMMEDIATE l_sql_string;
			--
			END IF;
		ELSE
			IF l_password IS NULL
			THEN
				l_sql_string :=
					'create user ' || dbms_assert.simple_sql_name(l_username)
					|| ' PROFILE CWMS_PROF IDENTIFIED BY values ''FEDCBA9876543210''
									 DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP ACCOUNT UNLOCK';
			ELSE
				l_sql_string :=
						'create user '
					|| dbms_assert.simple_sql_name(l_username)
					|| ' PROFILE CWMS_PROF IDENTIFIED BY '
					|| dbms_assert.enquote_name(l_password, false)
					|| ' DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP ACCOUNT UNLOCK';
			END IF;

			--DBMS_OUTPUT.put_line (l_sql_string);
         check_dynamic_sql(l_sql_string);

			EXECUTE IMMEDIATE l_sql_string;
		--
		END IF;
	END;

       PROCEDURE create_cwms_service_account (p_username 		IN VARCHAR2,
                                          p_password 		IN VARCHAR2                                          
												)
	AS
		l_sql_string						VARCHAR2 (400);
	BEGIN
		create_db_account (p_username, p_password);

		l_sql_string := 'GRANT CONNECT TO ' || dbms_assert.simple_sql_name(p_username);
		--DBMS_OUTPUT.put_line (l_sql_string);
        check_dynamic_sql(l_sql_string);

		EXECUTE IMMEDIATE l_sql_string;

		l_sql_string := 'GRANT CWMS_USER TO ' || dbms_assert.simple_sql_name(p_username);
		--DBMS_OUTPUT.put_line (l_sql_string);
        check_dynamic_sql(l_sql_string);

		EXECUTE IMMEDIATE l_sql_string;

	END create_cwms_service_account;


        PROCEDURE grant_cwms_permissions(p_username IN VARCHAR2)
        AS
		l_sql_string VARCHAR2 (400);
	BEGIN
		l_sql_string := 'GRANT CONNECT TO ' || dbms_assert.simple_sql_name(p_username);
		--DBMS_OUTPUT.put_line (l_sql_string);
      		check_dynamic_sql(l_sql_string);

		EXECUTE IMMEDIATE l_sql_string;

		l_sql_string := 'GRANT CWMS_USER TO ' || dbms_assert.simple_sql_name(p_username);
		--DBMS_OUTPUT.put_line (l_sql_string);
      		check_dynamic_sql(l_sql_string);

		EXECUTE IMMEDIATE l_sql_string;

		l_sql_string := 'ALTER USER  ' || dbms_assert.simple_sql_name(p_username) || ' PROFILE CWMS_PROF';
		--DBMS_OUTPUT.put_line (l_sql_string);
      		check_dynamic_sql(l_sql_string);

		EXECUTE IMMEDIATE l_sql_string;
	END;

	PROCEDURE create_cwms_db_account (p_username 		IN VARCHAR2,
                                          p_password 		IN VARCHAR2)
												
	AS
		l_sql_string						VARCHAR2 (400);
	BEGIN
		create_db_account (p_username, p_password);

		l_sql_string := 'GRANT CONNECT TO ' || dbms_assert.simple_sql_name(p_username);
		--DBMS_OUTPUT.put_line (l_sql_string);
      		check_dynamic_sql(l_sql_string);

		EXECUTE IMMEDIATE l_sql_string;

		l_sql_string := 'GRANT CWMS_USER TO ' || dbms_assert.simple_sql_name(p_username);
		--DBMS_OUTPUT.put_line (l_sql_string);
      		check_dynamic_sql(l_sql_string);

		EXECUTE IMMEDIATE l_sql_string;

	END;

	PROCEDURE delete_db_account (p_username IN VARCHAR2 DEFAULT NULL )
	AS
	BEGIN
		NULL;
	END;

	PROCEDURE set_user_password (p_username	IN VARCHAR2,
										  p_password	IN VARCHAR2
										 )
	AS
      l_sql_string VARCHAR2 (400);
   BEGIN
      l_sql_string := 'alter user '
                       || dbms_assert.simple_sql_name(p_username)
                       || ' identified by '
                       || dbms_assert.enquote_name(p_password);
      check_dynamic_sql(l_sql_string);                        
		EXECUTE IMMEDIATE l_sql_string;   
	END;
   PROCEDURE grant_rdl_role (p_role VARCHAR2, p_username VARCHAR2)
   IS
      l_cmd     VARCHAR2 (64);
   BEGIN
      l_cmd := 'GRANT ' || p_role || ' TO ' || p_username;

      EXECUTE IMMEDIATE l_cmd;
   EXCEPTION WHEN OTHERS
   THEN 
	NULL;
   END grant_rdl_role;

   PROCEDURE revoke_rdl_role (p_role VARCHAR2, p_username VARCHAR2)
   IS
      l_cmd     VARCHAR2 (64);
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
   PROCEDURE update_service_password(p_username VARCHAR2,p_password VARCHAR2)
   IS
    l_cmd VARCHAR2(128);
   BEGIN
    l_cmd := 'ALTER USER ' ||  p_username || ' IDENTIFIED BY "' || p_password || '"';
    execute immediate l_cmd;
   END update_service_password;
END cwms_user_admin;
/
