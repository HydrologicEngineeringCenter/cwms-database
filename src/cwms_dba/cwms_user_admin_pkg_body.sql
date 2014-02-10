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
	PROCEDURE lock_db_account (p_username IN VARCHAR2 DEFAULT NULL )
	AS
		l_sql_string						VARCHAR2 (400);
	BEGIN
		l_sql_string := 'ALTER user ' || p_username || ' account lock';
		DBMS_OUTPUT.put_line (l_sql_string);

		EXECUTE IMMEDIATE l_sql_string;
	END;

	PROCEDURE unlock_db_account (p_username IN VARCHAR2 DEFAULT NULL )
	AS
		l_sql_string						VARCHAR2 (400);
	BEGIN
		l_sql_string := 'ALTER user ' || p_username || ' account unlock';
		DBMS_OUTPUT.put_line (l_sql_string);

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
				l_sql_string := 'alter user ' || l_username || ' account unlock';

				EXECUTE IMMEDIATE l_sql_string;
			--
			END IF;
		ELSE
			IF l_password IS NULL
			THEN
				l_sql_string :=
					'create user ' || l_username
					|| ' PROFILE CWMS_PROF IDENTIFIED BY values ''FEDCBA9876543210''
									 DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP ACCOUNT UNLOCK';
			ELSE
				l_sql_string :=
						'create user '
					|| l_username
					|| ' PROFILE CWMS_PROF IDENTIFIED BY "'
					|| l_password
					|| '" DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP ACCOUNT UNLOCK';
			END IF;

			--DBMS_OUTPUT.put_line (l_sql_string);

			EXECUTE IMMEDIATE l_sql_string;
		--
		END IF;
	END;



	PROCEDURE create_cwms_db_account (p_username 		IN VARCHAR2,
												 p_password 		IN VARCHAR2
												)
	AS
		l_sql_string						VARCHAR2 (400);
	BEGIN
		create_db_account (p_username, p_password);

		l_sql_string := 'GRANT CONNECT TO ' || p_username;
		DBMS_OUTPUT.put_line (l_sql_string);

		EXECUTE IMMEDIATE l_sql_string;

		l_sql_string := 'GRANT CWMS_USER TO ' || p_username;
		DBMS_OUTPUT.put_line (l_sql_string);

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
		l_username							VARCHAR2 (31);
		l_password							VARCHAR2 (31);
	BEGIN
		l_username := p_username;
		l_password := p_password;

		EXECUTE IMMEDIATE   'alter user '
							  || l_username
							  || ' identified by '
							  || l_password;
	END;
END cwms_user_admin;
/
