/* Formatted on 6/1/2009 3:57:27 AM (QP5 v5.115.810.9015) */
CREATE OR REPLACE PACKAGE BODY cwms_20.cwms_sec
AS
	FUNCTION is_user_admin (p_db_office_code IN NUMBER)
		RETURN BOOLEAN
	IS
		l_count								INTEGER := 0;
		l_is_locked 						VARCHAR2 (1);
		l_username							VARCHAR2 (31) := cwms_util.get_user_id;
	BEGIN
		--
		-- Check if user's account is locked for the p_db_office_code
		-- portion of the database...
		--

		BEGIN
			SELECT	atslu.is_locked
			  INTO	l_is_locked
			  FROM	at_sec_locked_users atslu
			 WHERE	atslu.db_office_code = p_db_office_code
						AND atslu.username = UPPER (l_username);
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				l_is_locked := 'F';
		END;

		IF l_is_locked = 'T'
		THEN
			RETURN FALSE;
		END IF;


		--
		-- Check if user's account has either "dba" or "CWMS User Admins"
		-- privileges.
		--
		SELECT	COUNT ( * )
		  INTO	l_count
		  FROM	at_sec_users atsu
		 WHERE		 atsu.db_office_code = p_db_office_code
					AND atsu.user_group_code IN (0, 7)
					AND atsu.user_id = UPPER (l_username);

		IF l_count > 0
		THEN
			RETURN TRUE;
		ELSE
			RETURN FALSE;
		END IF;
	END;

	PROCEDURE get_user_office_data (p_office_id			  OUT VARCHAR2,
											  p_office_long_name   OUT VARCHAR2
											 )
	IS
	BEGIN
		cwms_util.get_user_office_data (p_office_id, p_office_long_name);
	END;

	--------------------------------------------------------------------------------
	--The get_user_priv_groups procedure returns a refcursor of:

	-- 		db_office_id	varchar2(16)
	-- 		username 		varchar2(31)
	-- 		user_group_id	varchar2(32)

	--The user_group_id's returned are ONLY the CWMS system level user groups, not
	--locally created user groups, i.e., "CWMS DBA Users", "Super CWMS Users",
	--"CWMS PD User", "Data Exchange Mgr", "Data Acquisition Mgr", "TS ID Creator",
	--"VT Mgr", and "All Users".

	--If p_username is null, then the system will use the username for the current
	--session. If p_db_office_id is null, then the default db_office_id of the
	--username will be used. Once can also pass in "ALL" for the p_db_office_id,
	--which will return the priv groups for all db_office_id's associated with
	--the username.
	--
	PROCEDURE get_user_priv_groups (
		p_priv_groups		  OUT sys_refcursor,
		p_username		  IN		VARCHAR2 DEFAULT NULL ,
		p_db_office_id   IN		VARCHAR2 DEFAULT NULL
	)
	IS
		l_user_id							VARCHAR2 (31)
				:= UPPER (NVL (TRIM (p_username), cwms_util.get_user_id)) ;
		l_db_office_id 					VARCHAR2 (16)
				:= UPPER (NVL (TRIM (p_db_office_id), cwms_util.user_office_id)) ;
	BEGIN
		IF l_db_office_id = 'ALL'
		THEN
			OPEN p_priv_groups FOR
				SELECT	b.office_id db_office_id, a.user_id username,
							c.user_group_id
				  FROM	at_sec_users a, cwms_office b, cwms_sec_user_groups c
				 WHERE		 a.db_office_code = b.office_code
							AND a.user_group_code = c.user_group_code
							AND user_id = l_user_id;
		ELSE
			OPEN p_priv_groups FOR
				SELECT	b.office_id db_office_id, a.user_id username,
							c.user_group_id
				  FROM	at_sec_users a, cwms_office b, cwms_sec_user_groups c
				 WHERE		 a.db_office_code = b.office_code
							AND a.user_group_code = c.user_group_code
							AND user_id = l_user_id
							AND a.db_office_code =
									cwms_util.get_db_office_code (l_db_office_id);
		END IF;
	END;

	FUNCTION get_user_office_id
		RETURN VARCHAR2
	IS
	BEGIN
		RETURN cwms_util.user_office_id;
	END;

	PROCEDURE lock_db_account (p_username IN VARCHAR2)
	IS
		l_db_office_code					NUMBER
				:= cwms_util.get_db_office_code (NULL) ;
	BEGIN
		IF NOT is_user_admin (l_db_office_code)
		THEN
			cwms_err.raise (
				'ERROR',
				'Permission Denied. Your account needs CWMS DBA or CWMS User Admin privileges to create a user.'
			);
		END IF;

		cwms_dba.cwms_user_admin.lock_db_account (p_username);
	END;

	PROCEDURE unlock_db_account (p_username IN VARCHAR2)
	IS
		l_db_office_code					NUMBER
				:= cwms_util.get_db_office_code (NULL) ;
	BEGIN
		IF NOT is_user_admin (l_db_office_code)
		THEN
			cwms_err.raise (
				'ERROR',
				'Permission Denied. Your account needs CWMS DBA or CWMS User Admin privileges to create a user.'
			);
		END IF;

		cwms_dba.cwms_user_admin.unlock_db_account (p_username);
	END;



	PROCEDURE create_cwms_db_account (p_username 		IN VARCHAR2,
												 p_db_office_id	IN VARCHAR2
												)
	IS
		l_dbi_username 					VARCHAR2 (31);
		l_db_office_code					NUMBER;
	BEGIN
		l_db_office_code := cwms_util.get_db_office_code (p_db_office_id);

		IF NOT is_user_admin (l_db_office_code)
		THEN
			cwms_err.raise (
				'ERROR',
				'Permission Denied. Your account needs CWMS DBA or CWMS User Admin privileges to create a user.'
			);
		END IF;

		SELECT	atsdu.dbi_username
		  INTO	l_dbi_username
		  FROM	at_sec_dbi_user atsdu
		 WHERE	atsdu.db_office_code = l_db_office_code;

		cwms_dba.cwms_user_admin.create_cwms_db_account (p_username,
																		 l_dbi_username
																		);
	END;

	PROCEDURE delete_cwms_db_account (p_username IN VARCHAR2)
	IS
	BEGIN
		NULL;
	END;


	FUNCTION does_db_account_exist (p_username IN VARCHAR2)
		RETURN BOOLEAN
	IS
		l_count								NUMBER := 0;
	BEGIN
		SELECT	COUNT ( * )
		  INTO	l_count
		  FROM	dba_users
		 WHERE	username = UPPER (p_username);

		IF l_count = 0
		THEN
			RETURN FALSE;
		ELSE
			RETURN TRUE;
		END IF;
	END;

	----------------------------------------------------------------------------
	-- unlock_user
	----------------------------------------------------------------------------
	/*

			  From cwmsdb.CwmsSecJdbc
						 unlockUser(String username, String officeId)

				This procedure unlocks p_username for the specified p_db_office_id. This does
				not unock the users Oracle Account, it only unlocks access to data for
			the p_db_office_id.

				Exceptions are thrown if:
			- If the user runing this procedure is not a member of the "CWMS DBA
				 Users" privilege group or the "Users Admin" privilege group for the
				p_db_office_id.
				- If the p_username does not have any exiting privileges on the
				 p_db_office_id data.
			- If the p_username is already unlocked for the p_db_office_id data.
				- If the p_username's Oracle Account is locked or if the p_username
				does not have an Oracle Account in the database.
		  */


	PROCEDURE unlock_user (p_username		 IN VARCHAR2,
								  p_db_office_id	 IN VARCHAR2 DEFAULT NULL
								 )
	IS
		l_db_office_code					NUMBER
				:= cwms_util.get_db_office_code (p_db_office_id) ;
		l_count								NUMBER;
	BEGIN
		IF NOT is_user_admin (l_db_office_code)
		THEN
			cwms_err.raise (
				'ERROR',
				'Permission Denied. Your account needs CWMS DBA or CWMS User Admin privileges to create a user.'
			);
		END IF;

		cwms_dba.cwms_user_admin.unlock_db_account (p_username);

		SELECT	COUNT ( * )
		  INTO	l_count
		  FROM	at_sec_locked_users
		 WHERE	username = p_username AND db_office_code = l_db_office_code;

		IF l_count = 0
		THEN
			INSERT INTO at_sec_locked_users (db_office_code, username, is_locked
													  )
			  VALUES   (l_db_office_code, UPPER (p_username), 'F'
						  );
		ELSE
			UPDATE	at_sec_locked_users
				SET	db_office_code = l_db_office_code,
						username = UPPER (p_username),
						is_locked = 'F';
		END IF;
	END;

	----------------------------------------------------------------------------
	-- add_user_to_group
	----------------------------------------------------------------------------
	/*

				From cwmsdb.CwmsSecJdbc
						  addUserToGroup(String username, String officeId, String group)

				This procedure is used to add p_username to the p_user_group.

				  Exceptions are thrown if:
				  - If the user runing this procedure is not a member of the "CWMS DBA
					 Users" privilege group or the "Users Admin" privilege group for the
					  p_db_office_id.
				- If a non-existing p_user_group_id is passed in.
				  - If the user is already a member of the p_user_group_id.
		  */

	FUNCTION get_user_group_code (p_user_group_id	 IN VARCHAR2,
											p_db_office_code	 IN NUMBER
										  )
		RETURN NUMBER
	IS
		l_user_group_code 				NUMBER;
	BEGIN
		BEGIN
			SELECT	user_group_code
			  INTO	l_user_group_code
			  FROM	at_sec_user_groups
			 WHERE	UPPER (user_group_id) = UPPER (p_user_group_id)
						AND db_office_code = p_db_office_code;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				cwms_err.raise (
					'ERROR',
					'The ' || p_user_group_id || ' is not a valid user group.'
				);
		END;

		RETURN l_user_group_code;
	END;

	PROCEDURE add_user_to_group (p_username			IN VARCHAR2,
										  p_user_group_id 	IN VARCHAR2,
										  p_db_office_code	IN NUMBER
										 )
	IS
		l_user_group_code 				NUMBER;
	BEGIN
		IF NOT is_user_admin (p_db_office_code)
		THEN
			cwms_err.raise (
				'ERROR',
				'Permission Denied. Your account needs CWMS DBA or CWMS User Admin privileges to create a user.'
			);
		END IF;

		l_user_group_code :=
			get_user_group_code (p_user_group_id, p_db_office_code);

		INSERT INTO at_sec_users (db_office_code, user_group_code, user_id
										 )
		  VALUES   (p_db_office_code, l_user_group_code, p_username
					  );
	END;

	PROCEDURE add_user_to_group (p_username		  IN VARCHAR2,
										  p_user_group_id   IN VARCHAR2,
										  p_db_office_id	  IN VARCHAR2 DEFAULT NULL
										 )
	IS
		l_db_office_code					NUMBER
				:= cwms_util.get_db_office_code (p_db_office_id) ;
	BEGIN
		add_user_to_group (p_username 		  => p_username,
								 p_user_group_id	  => p_user_group_id,
								 p_db_office_code   => l_db_office_code
								);
	END;


	----------------------------------------------------------------------------
	-- create_user
	----------------------------------------------------------------------------

	/*

		 From cwmsdb.CwmsSecJdbc
				createUser(String username, List<String> userGroupList,
								String officeId)

		  This procedure will create a new CWMS user associated with the
		 identified db_office_id.

			If the p_username is not an existing Oracle username/account,
		  then a new Oracle account is created.

			Exceptions are thrown if:
		  - If the user runing this procedure is not a member of the "CWMS DBA
			 Users" privilege group or the "Users Admin" privilege group for the
			 p_db_office_id.
			- If the CWMS user already exists for the p_db_office_id, then an
			 exception is thrown that indicates that and and suggest that either
				the add_user_to_group or remove_user_from_group procedures
			  should be called.
			- If one or more of the p_user_group_id_list entries is not a valid
				user_group_id for this p_db_office_id,
		*/



	PROCEDURE create_user (p_username				 IN VARCHAR2,
								  p_user_group_id_list	 IN char_32_array_type,
								  p_db_office_id			 IN VARCHAR2 DEFAULT NULL
								 )
	IS
		l_db_office_code					NUMBER
				:= cwms_util.get_db_office_code (p_db_office_id) ;
		l_dbi_username 					VARCHAR2 (31);
		l_user_group_code 				NUMBER;
		l_count								NUMBER;
	BEGIN
		IF NOT is_user_admin (l_db_office_code)
		THEN
			cwms_err.raise (
				'ERROR',
				'Permission Denied. Your account needs CWMS DBA or CWMS User Admin privileges to create a user.'
			);
		END IF;

		FOR i IN p_user_group_id_list.FIRST .. p_user_group_id_list.LAST
		LOOP
			l_user_group_code :=
				get_user_group_code (p_user_group_id_list (i), l_db_office_code);
		END LOOP;


		BEGIN
			SELECT	dbi_username
			  INTO	l_dbi_username
			  FROM	at_sec_dbi_user
			 WHERE	db_office_code = l_db_office_code;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				cwms_err.raise (
					'ERROR',
					'Unable to create user because a dbi_username was not found for this CWMS Oracle Database.'
				);
		END;

		cwms_dba.cwms_user_admin.create_cwms_db_account (p_username,
																		 l_dbi_username
																		);

		SELECT	COUNT ( * )
		  INTO	l_count
		  FROM	at_sec_user_office
		 WHERE	user_id = UPPER (p_username);

		unlock_user (p_username, l_db_office_code);

		IF l_count = 0
		THEN
			INSERT INTO at_sec_user_office (user_db_office_code, user_id
													 )
			  VALUES   (l_db_office_code, p_username
						  );
		END IF;

		FOR i IN p_user_group_id_list.FIRST .. p_user_group_id_list.LAST
		LOOP
			add_user_to_group (p_username,
									 p_user_group_id_list (i),
									 l_db_office_code
									);
		END LOOP;
	END;

	----------------------------------------------------------------------------
	-- delete_user
	----------------------------------------------------------------------------
	/*

			 From cwmsdb.CwmsSecJdbc
					 deleteUser(String username, String officeId)

			  This procedure will delete the p_username from the identified
			  p_db_office_id. It will not delete the Oracle account associated
			  with the p_username. If the p_username is not associated with another
				 db_office_id, then this procedure will Lock the p_username's Oracle
				Account.

				Exceptions are thrown if:
			  - If the user runing this procedure is not a member of the "CWMS DBA
					Users" privilege group or the "Users Admin" privilege group for the
				  p_db_office_id.
				 - If p_username is not associated with the identified p_db_office_id.
				- If p_username does not have an Oracle Account in the DB, then a Warning
					 exception is thrown indicating that an Oracle Account does not exist
					for this p_username.

		 */

	PROCEDURE delete_user (p_username		 IN VARCHAR2,
								  p_db_office_id	 IN VARCHAR2 DEFAULT NULL
								 )
	IS
	BEGIN
		NULL;
	END;

	----------------------------------------------------------------------------
	-- lock_user
	----------------------------------------------------------------------------
	/*

			From cwmsdb.CwmsSecJdbc
					 lockUser(String username, String officeId)

			 This procedure locks p_username from the specified p_db_office_id. This does
			  not lock the users Oracle Account, it only locks access to data for
			the p_db_office_id.

			 Exceptions are thrown if:
			- If the user runing this procedure is not a member of the "CWMS DBA
				 Users" privilege group or the "Users Admin" privilege group for the
			 p_db_office_id.
				- If the p_username does not have any exiting privileges on the p_db_office_id
				 data.
			 - If the p_username is already locked for the p_db_office_id data.
		  */

	PROCEDURE lock_user (p_username		  IN VARCHAR2,
								p_db_office_id   IN VARCHAR2 DEFAULT NULL
							  )
	IS
	BEGIN
		NULL;
	END;



	----------------------------------------------------------------------------
	-- remove_user_from_group
	----------------------------------------------------------------------------
	/*
		 From cwmsdb.CwmsSecJdbc
				 removeUserFromGroup(String username, String officeId,
											String group)

				 This procedure is used to remove p_username from the p_user_group.

				 Exceptions are thrown if:
				  - If the user runing this procedure is not a member of the "CWMS DBA
					 Users" privilege group or the "Users Admin" privilege group for the
					  p_db_office_id.
				- If a non-existing p_user_group_id is passed in.
				  - If the user is not a member of the p_user_group_id.

			*/


	PROCEDURE remove_user_from_group (
		p_username			IN VARCHAR2,
		p_user_group_id	IN VARCHAR2,
		p_db_office_id 	IN VARCHAR2 DEFAULT NULL
	)
	IS
		l_db_office_code					NUMBER
				:= cwms_util.get_db_office_code (p_db_office_id) ;
		l_user_group_code 				NUMBER;
	BEGIN
		IF NOT is_user_admin (l_db_office_code)
		THEN
			cwms_err.raise (
				'ERROR',
				'Permission Denied. Your account needs CWMS DBA or CWMS User Admin privileges to create a user.'
			);
		END IF;

		l_user_group_code :=
			get_user_group_code (p_user_group_id, l_db_office_code);

		DELETE FROM   at_sec_users
				WHERE 		db_office_code = l_db_office_code
						  AND user_group_code = l_user_group_code
						  AND user_id = UPPER (p_username);
	END;

	----------------------------------------------------------------------------
	-- get_user_state
	----------------------------------------------------------------------------

	/*

	getUserState(String username, String officeId)

	  */

	FUNCTION get_user_state (p_username 		IN VARCHAR2,
									 p_db_office_id	IN VARCHAR2 DEFAULT NULL
									)
		RETURN VARCHAR2
	IS
	BEGIN
		NULL;
	END;
/*

storePrivilegeGroups(String username, String officeId,
		  List<String> groupNameList, List<String> groupOfficeIdList,
		 List<Boolean> groupAssignedList)

		 */
END cwms_sec;
/