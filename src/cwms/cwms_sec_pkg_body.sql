/* Formatted on 7/13/2009 5:29:15 PM (QP5 v5.115.810.9015) */
CREATE OR REPLACE PACKAGE BODY cwms_20.cwms_sec
AS
	FUNCTION is_user_admin (p_db_office_code IN NUMBER)
		RETURN BOOLEAN
	IS
		l_count		  INTEGER := 0;
		l_is_locked   VARCHAR2 (1);
		l_username	  VARCHAR2 (31) := cwms_util.get_user_id;
	BEGIN
		--
		-- cwms_20, system, sys are ok
		--
		IF l_username IN ('CWMS_20', 'SYSTEM', 'SYS', 'GERHARD', 'ART')
		THEN
			RETURN TRUE;
		END IF;

		--
		-- Check if user's account is locked for the p_db_office_code
		-- portion of the database...
		--

		BEGIN
			SELECT	atslu.is_locked
			  INTO	l_is_locked
			  FROM	cwms_20.at_sec_locked_users atslu
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
		  FROM	cwms_20.at_sec_users atsu
		 WHERE		 atsu.db_office_code = p_db_office_code
					AND atsu.user_group_code IN (0, 7)
					AND atsu.username = UPPER (l_username);

		IF l_count > 0
		THEN
			RETURN TRUE;
		ELSE
			RETURN FALSE;
		END IF;
	END;

	FUNCTION is_user_admin (p_db_office_id IN VARCHAR2 DEFAULT NULL )
		RETURN BOOLEAN
	IS
		l_db_office_id VARCHAR2 (16)
				:= cwms_util.get_db_office_id (p_db_office_id) ;
		l_db_office_code NUMBER
				:= cwms_util.get_db_office_code (l_db_office_id) ;
	BEGIN
		RETURN is_user_admin (p_db_office_code => l_db_office_code);
	END;

	PROCEDURE confirm_user_admin_priv (p_db_office_code IN NUMBER)
	AS
	BEGIN
		IF is_user_admin (p_db_office_code => p_db_office_code)
		THEN
			NULL;
		ELSE
			cwms_err.raise (
				'ERROR',
				'Permission Denied. Your account needs "CWMS DBA" or "CWMS User Admin" privileges to use the cwms_sec package.'
			);
		END IF;
	END;

	FUNCTION is_member_user_group (p_user_group_code	IN NUMBER,
											 p_username 			IN VARCHAR2,
											 p_db_office_code 	IN NUMBER
											)
		RETURN BOOLEAN
	AS
		l_count	 NUMBER := 0;
	BEGIN
		SELECT	COUNT ( * )
		  INTO	l_count
		  FROM	at_sec_users a
		 WHERE		 a.db_office_code = p_db_office_code
					AND a.user_group_code = p_user_group_code
					AND a.username = UPPER (TRIM (p_username));

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

	PROCEDURE set_dbi_user (p_dbi_username   IN VARCHAR2,
									p_db_office_id   IN VARCHAR2
								  )
	AS
		l_dbi_username   VARCHAR2 (30) := UPPER (TRIM (p_dbi_username));
		l_db_office_id VARCHAR2 (16)
				:= cwms_util.get_db_office_id (p_db_office_id) ;
		l_db_office_code NUMBER
				:= cwms_util.get_db_office_code (l_db_office_id) ;
	BEGIN
		confirm_user_admin_priv (l_db_office_code);

		BEGIN
			INSERT INTO at_sec_dbi_user (db_office_code, dbi_username
												 )
			  VALUES   (l_db_office_code, l_dbi_username
						  );
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX
			THEN
				cwms_err.raise (
					'ERROR',
						l_dbi_username
					|| ' is alrady a registered dbi username for the '
					|| l_db_office_id
					|| ' db_office_id.'
				);
		END;
	END;
    /*  cwms_sec.get_my_user_priv_groups(p_priv_groups  OUT sys_refcursor,
                                         p_db_office_id IN  VARCHAR2 DEFAULT NULL)
        
    This call is callable by anyone and returns a listing of that users
    priv_groups for the identified and/or the users default db_office_id.
    
    Returns a refcursor of:

    USERNAME
    USER_DB_OFFICE_ID
    DB_OFFICE_ID
    USER_GROUP_TYPE     (either "Privelege User Group" or "TS Collection User Group"
    USER_GROUP_OWNER  ("CWMS" or the owning DB_OFFICE_ID)
    USER_GROUP_ID
    IS_MEMBER            ("T" or "F")
    USER_GROUP_DESC
    */
/* Formatted on 7/15/2009 3:22:40 AM (QP5 v5.115.810.9015) */
    FUNCTION get_my_priv_groups_tab (p_db_office_id	 IN VARCHAR2 DEFAULT NULL)
        RETURN cat_priv_groups_tab_t
        PIPELINED
    IS
        query_cursor	sys_refcursor;
        output_row		cat_priv_groups_rec_t;
    BEGIN
        get_my_priv_groups (query_cursor, p_db_office_id);

        LOOP
            FETCH query_cursor INTO   output_row;

            EXIT WHEN query_cursor%NOTFOUND;
            PIPE ROW (output_row);
        END LOOP;

        CLOSE query_cursor;

        RETURN;
    END get_my_priv_groups_tab;
    --
    PROCEDURE get_my_priv_groups (
        p_priv_groups		  OUT sys_refcursor,
        p_db_office_id   IN		VARCHAR2 DEFAULT NULL
    )
    IS
        l_username			 VARCHAR2 (31) := cwms_util.get_user_id;
        l_db_office_id VARCHAR2 (16)
                := cwms_util.get_db_office_id (p_db_office_id) ;
        l_db_office_code	 NUMBER := cwms_util.get_db_office_code (l_db_office_id);
    BEGIN
        OPEN p_priv_groups FOR
            SELECT	username, user_db_office_id, db_office_id, user_group_type,
                        user_group_owner, user_group_id, is_member, user_group_desc
              FROM	av_sec_users
             WHERE	db_office_code = l_db_office_code AND username = l_username;
    END;

    /*--------------------------------------------------------------------------------
    The get_user_priv_groups procedure returns a refcursor of:

    USERNAME
    USER_DB_OFFICE_ID
    DB_OFFICE_ID
    USER_GROUP_TYPE	 (either "Privelege User Group" or "TS Collection User Group"
    USER_GROUP_OWNER  ("CWMS" or the owning DB_OFFICE_ID)
    USER_GROUP_ID
    IS_MEMBER			("T" or "F")
    USER_GROUP_DESC

    If p_username is null, then all usernames are returned
    If p_db_office_id is null, then the priv groups for all db_office_id's
    associated with the calling username's admin privileges.

    */
    /* Formatted on 7/15/2009 6:58:35 AM (QP5 v5.115.810.9015) */
    FUNCTION get_user_priv_groups_tab (p_username		 IN VARCHAR2 DEFAULT NULL ,
                                                  p_db_office_id	 IN VARCHAR2 DEFAULT NULL
                                                 )
        RETURN cat_priv_groups_tab_t
        PIPELINED
    IS
        query_cursor	sys_refcursor;
        output_row		cat_priv_groups_rec_t;
    BEGIN
        get_user_priv_groups (query_cursor, p_username, p_db_office_id);

        LOOP
            FETCH query_cursor INTO   output_row;

            EXIT WHEN query_cursor%NOTFOUND;
            PIPE ROW (output_row);
        END LOOP;

        CLOSE query_cursor;

        RETURN;
    END get_user_priv_groups_tab;
    --

    PROCEDURE get_user_priv_groups (
        p_priv_groups		  OUT sys_refcursor,
        p_username		  IN		VARCHAR2 DEFAULT NULL ,
        p_db_office_id   IN		VARCHAR2 DEFAULT NULL
    )
    IS
        l_db_office_id 			  VARCHAR2 (16);
        l_username					  VARCHAR2 (31);
        l_db_office_code			  NUMBER;
        l_retrieve_all_username   BOOLEAN;
        l_retrieve_all_offices	  BOOLEAN;
    BEGIN
        IF p_username IS NULL
        THEN
            l_retrieve_all_username := TRUE;
        ELSE
            l_retrieve_all_username := FALSE;
            l_username := UPPER (TRIM (p_username));
        END IF;

        IF p_db_office_id IS NULL
        THEN
            l_retrieve_all_offices := TRUE;
        ELSE
            l_retrieve_all_offices := FALSE;
            l_db_office_id := cwms_util.get_db_office_id (p_db_office_id);
            l_db_office_code := cwms_util.get_db_office_code (l_db_office_id);
            confirm_user_admin_priv (l_db_office_code);
        END IF;

        IF (l_retrieve_all_username AND l_retrieve_all_offices)
        THEN
            OPEN p_priv_groups FOR
                SELECT	username, user_db_office_id, db_office_id, user_group_type,
                            user_group_owner, user_group_id, is_member, user_group_desc
                  FROM	av_sec_users
                 WHERE	db_office_code IN
                                    (SELECT	 UNIQUE db_office_code
                                        FROM	 at_sec_users
                                      WHERE	 username = cwms_util.get_user_id
                                                 AND user_group_code IN
                                                             (user_group_code_dba_users,
                                                              user_group_code_user_admins));
        ELSIF (l_retrieve_all_username AND NOT l_retrieve_all_offices)
        THEN
            OPEN p_priv_groups FOR
                SELECT	username, user_db_office_id, db_office_id, user_group_type,
                            user_group_owner, user_group_id, is_member, user_group_desc
                  FROM	av_sec_users
                 WHERE	db_office_code = l_db_office_code;
        ELSIF (NOT l_retrieve_all_username AND NOT l_retrieve_all_offices)
        THEN
            OPEN p_priv_groups FOR
                SELECT	username, user_db_office_id, db_office_id, user_group_type,
                            user_group_owner, user_group_id, is_member, user_group_desc
                  FROM	av_sec_users
                 WHERE	db_office_code = l_db_office_code AND username = l_username;
        ELSE
            OPEN p_priv_groups FOR
                SELECT	username, user_db_office_id, db_office_id, user_group_type,
                            user_group_owner, user_group_id, is_member, user_group_desc
                  FROM	av_sec_users
                 WHERE	username = l_username
                            AND db_office_code IN
                                        (SELECT	 UNIQUE db_office_code
                                            FROM	 at_sec_users
                                          WHERE	 username = cwms_util.get_user_id
                                                     AND user_group_code IN (0, 7));
        END IF;
    END;

	---
	---
    /* get_ts_user_group_code return the user_group code for valid
    user_groups that can be coupled with ts_groups.

    Exception is thrown if the user_group is one of the primary
    privilege user groups.

    */

	FUNCTION get_ts_user_group_code (p_user_group_id	 IN VARCHAR2,
												p_db_office_code	 IN NUMBER
											  )
		RETURN NUMBER
	AS
		l_user_group	NUMBER;
	BEGIN
		l_user_group := get_user_group_code (p_user_group_id, p_db_office_code);

		IF l_user_group < 10
		THEN
			cwms_err.raise (
				'ERROR',
				'User Group: ' || p_user_group_id
				|| ' is a primary privilege group, which cannot be paired with a TS Group.'
			);
		ELSE
			RETURN l_user_group;
		END IF;
	END;

	FUNCTION get_ts_group_code (p_ts_group_id 	  IN VARCHAR2,
										 p_db_office_code   IN NUMBER
										)
		RETURN NUMBER
	AS
		l_ts_group_code	NUMBER;
	BEGIN
		BEGIN
			SELECT	ts_group_code
			  INTO	l_ts_group_code
			  FROM	at_sec_ts_groups
			 WHERE	UPPER (ts_group_id) = UPPER (TRIM (p_ts_group_id))
						AND db_office_code = p_db_office_code;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				cwms_err.raise (
					'ERROR',
					'The ' || p_ts_group_id || ' is not a valid TS Group.'
				);
		END;

		RETURN l_ts_group_code;
	END;

	FUNCTION get_user_office_id
		RETURN VARCHAR2
	IS
	BEGIN
		RETURN cwms_util.user_office_id;
	END;

	PROCEDURE lock_db_account (p_username IN VARCHAR2)
	IS
		l_db_office_code	 NUMBER := cwms_util.get_db_office_code (NULL);
	BEGIN
		confirm_user_admin_priv (l_db_office_code);

		cwms_dba.cwms_user_admin.lock_db_account (p_username);
	END;

	PROCEDURE unlock_db_account (p_username IN VARCHAR2)
	IS
		l_db_office_code	 NUMBER := cwms_util.get_db_office_code (NULL);
	BEGIN
		confirm_user_admin_priv (l_db_office_code);

		cwms_dba.cwms_user_admin.unlock_db_account (p_username);
	END;

    PROCEDURE create_cwms_db_account (p_username 		IN VARCHAR2,
                                                 p_password 		IN VARCHAR2,
                                                 p_db_office_id	IN VARCHAR2 DEFAULT NULL
                                                )
    IS
        l_username			 VARCHAR2 (31) := UPPER (TRIM (p_username));
        l_password			 VARCHAR2 (31) := TRIM (p_password);
        l_is_locked 		 VARCHAR2 (1);
        l_dbi_username 	 VARCHAR2 (31);
        l_db_office_id VARCHAR2 (16)
                := cwms_util.get_db_office_id (p_db_office_id) ;
        l_db_office_code	 NUMBER := cwms_util.get_db_office_code (l_db_office_id);
    --
    BEGIN
        confirm_user_admin_priv (l_db_office_code);

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

        cwms_dba.cwms_user_admin.create_cwms_db_account (l_username,
                                                                         l_password,
                                                                         l_dbi_username
                                                                        );

        BEGIN
            INSERT INTO at_sec_user_office (username, user_db_office_code
                                                     )
              VALUES   (l_username, l_db_office_code
                          );
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX
            THEN
                NULL;
        END;

        BEGIN
            SELECT	is_locked
              INTO	l_is_locked
              FROM	at_sec_locked_users
             WHERE	db_office_code = l_db_office_code AND username = l_username;

            IF l_is_locked != 'F'
            THEN
                UPDATE	at_sec_locked_users
                    SET	is_locked = 'F'
                 WHERE	db_office_code = l_db_office_code AND username = l_username;
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                INSERT INTO at_sec_locked_users (db_office_code, username, is_locked
                                                          )
                  VALUES   (l_db_office_code, l_username, 'F'
                              );
        END;

        BEGIN
            INSERT INTO at_sec_users (db_office_code, user_group_code, username
                                             )
              VALUES   (l_db_office_code, user_group_code_all_users, l_username
                          );
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX
            THEN
                NULL;
        END;

        COMMIT;
    END;
	PROCEDURE delete_cwms_db_account (p_username IN VARCHAR2)
	IS
	BEGIN
		cwms_err.raise (
			'ERROR',
			'Unable to delete user DB account - see your DBA to delete a DB account.'
		);
	END;

	FUNCTION does_db_account_exist (p_username IN VARCHAR2)
		RETURN BOOLEAN
	IS
		l_count	 NUMBER := 0;
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
    -	 If the user runing this procedure is not a member of the "CWMS DBA
    Users" privilege group or the "Users Admin" privilege group for the
    p_db_office_id.
    - If the p_username does not have any exiting privileges on the
    p_db_office_id data.
    -   If the p_username is already unlocked for the p_db_office_id data.
    -   If the p_username's Oracle Account is locked or if the p_username
    does not have an Oracle Account in the database.
    */
    PROCEDURE unlock_user (p_username		 IN VARCHAR2,
                                  p_db_office_id	 IN VARCHAR2 DEFAULT NULL
                                 )
    IS
        l_db_office_code	 NUMBER := cwms_util.get_db_office_code (p_db_office_id);
        l_count				 NUMBER;
        l_username			 VARCHAR2 (31);
    BEGIN
        confirm_user_admin_priv (l_db_office_code);


        l_username := UPPER (TRIM (p_username));
        cwms_dba.cwms_user_admin.unlock_db_account (l_username);

        SELECT	COUNT ( * )
          INTO	l_count
          FROM	at_sec_locked_users
         WHERE	username = l_username AND db_office_code = l_db_office_code;

        IF l_count = 0
        THEN
            INSERT INTO at_sec_locked_users (db_office_code, username, is_locked
                                                      )
              VALUES   (l_db_office_code, l_username, 'F'
                          );
        ELSE
            UPDATE	at_sec_locked_users
                SET	is_locked = 'F'
             WHERE	db_office_code = l_db_office_code AND username = l_username;
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
		l_user_group_code   NUMBER;
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
        l_user_group_code   NUMBER;
        l_username			  VARCHAR2 (31) := UPPER (TRIM (p_username));
    BEGIN
        confirm_user_admin_priv (p_db_office_code);


        l_user_group_code :=
            get_user_group_code (p_user_group_id, p_db_office_code);

        BEGIN
            INSERT INTO at_sec_users (db_office_code, user_group_code, username
                                             )
              VALUES   (p_db_office_code, l_user_group_code, l_username
                          );
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX
            THEN
                NULL;
        END;
    END;
	PROCEDURE add_user_to_group (p_username		  IN VARCHAR2,
										  p_user_group_id   IN VARCHAR2,
										  p_db_office_id	  IN VARCHAR2 DEFAULT NULL
										 )
	IS
		l_db_office_code NUMBER
				:= cwms_util.get_db_office_code (p_db_office_id) ;
	BEGIN
		add_user_to_group (p_username 		  => p_username,
								 p_user_group_id	  => p_user_group_id,
								 p_db_office_code   => l_db_office_code
								);
	END;

	PROCEDURE create_cwmsdbi_db_user (
		p_dbi_username   IN VARCHAR2,
		p_dbi_password   IN VARCHAR2 DEFAULT NULL ,
		p_db_office_id   IN VARCHAR2 DEFAULT NULL
	)
	AS
		l_db_office_id VARCHAR2 (16)
				:= cwms_util.get_db_office_id (p_db_office_id) ;
		l_db_office_code NUMBER
				:= cwms_util.get_db_office_code (l_db_office_id) ;
	BEGIN
		confirm_user_admin_priv (l_db_office_code);

		cwms_dba.cwms_user_admin.create_cwmsdbi_db_account (p_dbi_username,
																			 p_dbi_password
																			);

		set_dbi_user (p_dbi_username, p_db_office_id);
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
                                  p_password				 IN VARCHAR2,
                                  p_user_group_id_list	 IN char_32_array_type,
                                  p_db_office_id			 IN VARCHAR2 DEFAULT NULL
                                 )
    IS
        l_db_office_id VARCHAR2 (16)
                := cwms_util.get_db_office_id (p_db_office_id) ;
        l_db_office_code	  NUMBER := cwms_util.get_db_office_code (l_db_office_id);
        l_dbi_username 	  VARCHAR2 (31);
        l_username			  VARCHAR2 (31) := UPPER (TRIM (p_username));
        l_user_group_code   NUMBER;
        l_count				  NUMBER;
    BEGIN
        confirm_user_admin_priv (l_db_office_code);

        IF p_user_group_id_list is not null
        THEN
            FOR i IN p_user_group_id_list.FIRST .. p_user_group_id_list.LAST
            LOOP
                l_user_group_code :=
                    get_user_group_code (p_user_group_id_list (i), l_db_office_code);
            END LOOP;
        END IF;

        create_cwms_db_account (l_username, p_password, l_db_office_id);

        IF p_user_group_id_list is not null
        THEN
            FOR i IN p_user_group_id_list.FIRST .. p_user_group_id_list.LAST
            LOOP
                add_user_to_group (l_username,
                                         p_user_group_id_list (i),
                                         l_db_office_code
                                        );
            END LOOP;
        END IF;
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
		l_username	 VARCHAR2 (31);
		l_db_office_id VARCHAR2 (16)
				:= cwms_util.get_db_office_id (p_db_office_id) ;
		l_db_office_code NUMBER
				:= cwms_util.get_db_office_code (l_db_office_id) ;
	BEGIN
		confirm_user_admin_priv (l_db_office_code);

		l_username := UPPER (TRIM (p_username));

		DELETE FROM   at_sec_users
				WHERE   username = l_username
						  AND db_office_code = l_db_office_code;

		DELETE FROM   at_sec_locked_users
				WHERE   username = l_username
						  AND db_office_code = l_db_office_code;

		BEGIN
			DELETE FROM   at_sec_user_office
					WHERE   username = l_username;
		EXCEPTION
			WHEN OTHERS
			THEN
				-- If this parent entry is defining rights for other db_office_codes, then
				-- leave an entry for this username
				NULL;
		END;
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
			 - if the username has no privileges on the db_office_id database
			  - If a username that doesn't exist is passed in.
		 */

	PROCEDURE lock_user (p_username		  IN VARCHAR2,
								p_db_office_id   IN VARCHAR2 DEFAULT NULL
							  )
	IS
		l_db_office_id VARCHAR2 (16)
				:= cwms_util.get_db_office_id (p_db_office_id) ;
		l_db_office_code NUMBER
				:= cwms_util.get_db_office_code (l_db_office_id) ;
		l_count		 NUMBER;
		l_username	 VARCHAR2 (31);
	BEGIN
		confirm_user_admin_priv (l_db_office_code);

		l_username := UPPER (TRIM (p_username));

		-- Check if user has a DB Account...

		IF NOT does_db_account_exist (l_username)
		THEN
			cwms_err.raise (
				'ERROR',
				'WARNING: ' || l_username
				|| ' does not have a valid account, so unable to place a Lock on this username.'
			);
		END IF;

		-- Check if this user has any privileges on the p_db_office_id's data...

		SELECT	COUNT ( * )
		  INTO	l_count
		  FROM	at_sec_users
		 WHERE	username = l_username AND db_office_code = l_db_office_code;

		IF l_count = 0
		THEN
			cwms_err.raise (
				'ERROR',
					'WARNING: '
				|| l_username
				|| ' has no privileges assigned to the '
				|| l_db_office_id
				|| '''s data, so unable to place a Lock on this username for this office''s data.'
			);
		END IF;

		UPDATE	at_sec_locked_users
			SET	is_locked = 'T'
		 WHERE	username = l_username AND db_office_code = l_db_office_code;
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
    -	If a non-existing p_user_group_id is passed in.

    */
    PROCEDURE remove_user_from_group (p_username 		 IN VARCHAR2,
                                                 p_user_group_id	 IN VARCHAR2,
                                                 p_db_office_id	 IN VARCHAR2 DEFAULT NULL
                                                )
    IS
        l_db_office_code	  NUMBER := cwms_util.get_db_office_code (p_db_office_id);
        l_user_group_code   NUMBER;
    BEGIN
        confirm_user_admin_priv (l_db_office_code);

        l_user_group_code :=
            get_user_group_code (p_user_group_id, l_db_office_code);

        IF l_user_group_code = user_group_code_all_users
        THEN
            cwms_err.raise ('ERROR',
                                 'Cannot remove users from the "All Users" User Group.'
                                );
        END IF;

        DELETE FROM   at_sec_users
                WHERE 		db_office_code = l_db_office_code
                          AND user_group_code = l_user_group_code
                          AND username = UPPER (p_username);
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
		l_db_office_id VARCHAR2 (16)
				:= cwms_util.get_db_office_id (p_db_office_id) ;
		l_db_office_code NUMBER
				:= cwms_util.get_db_office_code (l_db_office_id) ;
		l_account_status	 VARCHAR2 (32) := NULL;
		l_is_locked 		 VARCHAR2 (1);
		l_username			 VARCHAR2 (31) := UPPER (TRIM (p_username));
	BEGIN
		confirm_user_admin_priv (l_db_office_code);

		BEGIN
			SELECT	account_status
			  INTO	l_account_status
			  FROM	dba_users
			 WHERE	username = l_username;
		EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
				RETURN 'NO ACCOUNT';
		END;

		IF l_account_status != 'OPEN'
		THEN
			RETURN l_account_status;
		ELSE
			BEGIN
				SELECT	is_locked
				  INTO	l_is_locked
				  FROM	at_sec_locked_users
				 WHERE	username = l_username
							AND db_office_code = l_db_office_code;
			EXCEPTION
				WHEN NO_DATA_FOUND
				THEN
					RETURN 'NO ACCOUNT';
			END;

			IF l_is_locked = 'T'
			THEN
				RETURN 'LOCKED';
			ELSE
				RETURN 'OPEN';
			END IF;
		END IF;
	END;

	/*

		storePrivilegeGroups(String username, String officeId,
					List<String> groupNameList, List<String> groupOfficeIdList,
																									  List<Boolean> groupAssignedList)

																			*/



	----------------------------------------------------------------------------
	-- set_dbi_user_passwd
	----------------------------------------------------------------------------

	/*
				From cwmsdb.CwmsSecJdbc
																					setDbiUserPass(String dbiUserName, String dbiUserPass)
																		*/

	PROCEDURE set_dbi_user_passwd (p_dbi_password	IN VARCHAR2,
											 p_dbi_username	IN VARCHAR2 DEFAULT NULL ,
											 p_db_office_id	IN VARCHAR2 DEFAULT NULL
											)
	AS
		l_db_office_id VARCHAR2 (16)
				:= cwms_util.get_db_office_id (p_db_office_id) ;
		l_db_office_code NUMBER
				:= cwms_util.get_db_office_code (l_db_office_id) ;

		l_dbi_username   VARCHAR2 (31);
	BEGIN
		confirm_user_admin_priv (l_db_office_code);


		-- Confirm that the p_dbi_username is the valid dbi username for the db_office_id
		IF p_dbi_username IS NULL
		THEN
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
						'Sorry, unable to set the DBI User Password because the '
						|| l_db_office_id
						|| ' database does not have a DBI User set.'
					);
				WHEN TOO_MANY_ROWS
				THEN
					cwms_err.raise (
						'ERROR',
						'Sorry, unable to set the DBI User Password because there are more than one set DBI Users set for the '
						|| l_db_office_id
						|| ' database. Please specify which DBI User''''s password you wish to reset.'
					);
			END;
		ELSE
			BEGIN
				SELECT	dbi_username
				  INTO	l_dbi_username
				  FROM	at_sec_dbi_user
				 WHERE	dbi_username = UPPER (p_dbi_username)
							AND db_office_code = l_db_office_code;
			EXCEPTION
				WHEN NO_DATA_FOUND
				THEN
					cwms_err.raise (
						'ERROR',
							'Sorry, unable to set the DBI User Password. '
						|| UPPER (p_dbi_username)
						|| ' is not a registered DBI Username for the '
						|| l_db_office_id
						|| ' database.'
					);
			END;
		END IF;

		-- l_dbi_username should now have a valid username - so reset it's password...

		cwms_dba.cwms_user_admin.set_user_password (l_dbi_username,
																  p_dbi_password
																 );
	END;



	PROCEDURE assign_ts_group_user_group (
		p_ts_group_id		IN VARCHAR2,
		p_user_group_id	IN VARCHAR2,
		p_privilege 		IN VARCHAR2,						  -- none, read or write
		p_db_office_id 	IN VARCHAR2 DEFAULT NULL
	)
	AS
		l_db_office_id VARCHAR2 (16)
				:= cwms_util.get_db_office_id (p_db_office_id) ;
		l_db_office_code NUMBER
				:= cwms_util.get_db_office_code (l_db_office_id) ;
		l_privilege 		  VARCHAR2 (10);
		l_user_group_code   NUMBER;
		l_ts_group_code	  NUMBER;
		l_sum_priv_bit 	  NUMBER := NULL;
	BEGIN
		confirm_user_admin_priv (l_db_office_code);

		IF UPPER (TRIM (p_privilege)) = 'READ'
		THEN
			l_privilege := 'READ';
		ELSIF UPPER (TRIM (p_privilege)) = 'READ-WRITE'
		THEN
			l_privilege := 'READ-WRITE';
		ELSIF UPPER (TRIM (p_privilege)) = 'NONE'
		THEN
			l_privilege := 'NONE';
		ELSE
			cwms_err.raise (
				'ERROR',
				'Unrecognized p_privilege: ' || p_privilege
				|| ' "None", "Read" or "Read-Write" are the only valid privileges.'
			);
		END IF;

		l_user_group_code :=
			get_ts_user_group_code (p_user_group_id, l_db_office_code);

		l_ts_group_code := get_ts_group_code (p_ts_group_id, l_db_office_code);

		-- Determine if read/write priv's are already set for this group pair..

		SELECT	SUM (privilege_bit)
		  INTO	l_sum_priv_bit
		  FROM	at_sec_allow
		 WHERE		 db_office_code = l_db_office_code
					AND ts_group_code = l_ts_group_code
					AND user_group_code = l_user_group_code;

		IF l_sum_priv_bit IS NOT NULL
		THEN
			DELETE FROM   at_sec_allow
					WHERE 		db_office_code = l_db_office_code
							  AND ts_group_code = l_ts_group_code
							  AND user_group_code = l_user_group_code;
		END IF;

		IF l_privilege IN ('READ', 'READ-WRITE')
		THEN
			INSERT INTO at_sec_allow (
												  db_office_code,
												  ts_group_code,
												  user_group_code,
												  privilege_bit
						  )
			  VALUES   (l_db_office_code, l_ts_group_code, l_user_group_code, 2
						  );
		END IF;

		IF l_privilege IN ('WRITE', 'READ-WRITE')
		THEN
			INSERT INTO at_sec_allow (
												  db_office_code,
												  ts_group_code,
												  user_group_code,
												  privilege_bit
						  )
			  VALUES   (l_db_office_code, l_ts_group_code, l_user_group_code, 4
						  );
		END IF;
	END;

	PROCEDURE cat_at_sec_allow (p_at_sec_allow		OUT sys_refcursor,
										 p_db_office_id	IN 	 VARCHAR2 DEFAULT NULL
										)
	AS
		l_db_office_code NUMBER
				:= cwms_util.get_db_office_code (p_db_office_id) ;
	BEGIN
		confirm_user_admin_priv (l_db_office_code);

		OPEN p_at_sec_allow FOR
			  SELECT   db_office_code, user_group_code, ts_group_code,
						  db_office_id, user_group_id, ts_group_id, priv_sum,
						  DECODE (priv_sum,
									 2, 'READ',
									 4, 'WRITE',
									 6, 'READ-WRITE',
									 NULL
									)
							  priv
				 FROM   (  SELECT   db_office_code, user_group_code, ts_group_code,
										  db_office_id, user_group_id, ts_group_id,
										  SUM (b.privilege_bit) priv_sum
								 FROM 	  (SELECT	a.db_office_code, a.user_group_code,
															c.ts_group_code,
															b.office_id db_office_id,
															a.user_group_id, c.ts_group_id
												  FROM	at_sec_user_groups a,
															cwms_office b,
															at_sec_ts_groups c
												 WHERE	a.db_office_code = b.office_code
															AND a.db_office_code =
																	l_db_office_code
															AND c.db_office_code =
																	l_db_office_code
															AND a.user_group_code >
																	max_cwms_priv_ugroup_code) a
										  LEFT OUTER JOIN
											  at_sec_allow b
										  USING (db_office_code,
													user_group_code,
													ts_group_code)
							GROUP BY   db_office_code,
										  user_group_code,
										  ts_group_code,
										  db_office_id,
										  user_group_id,
										  ts_group_id) a
			ORDER BY   user_group_id, ts_group_id;
	END;

	FUNCTION cat_at_sec_allow_tab (p_db_office_id IN VARCHAR2 DEFAULT NULL )
		RETURN cat_at_sec_allow_tab_t
		PIPELINED
	IS
		query_cursor	sys_refcursor;
		output_row		cat_at_sec_allow_rec_t;
	BEGIN
		cat_at_sec_allow (query_cursor, p_db_office_id);

		LOOP
			FETCH query_cursor INTO   output_row;

			EXIT WHEN query_cursor%NOTFOUND;
			PIPE ROW (output_row);
		END LOOP;

		CLOSE query_cursor;

		RETURN;
	END;


	PROCEDURE refresh_mv_sec_ts_privileges
	AS
		l_status   VARCHAR2 (30);
	BEGIN
		SELECT	status
		  INTO	l_status
		  FROM	dba_objects
		 WHERE	object_name = 'MV_SEC_TS_PRIVILEGES'
					AND object_type = 'MATERIALIZED VIEW';


		IF l_status != 'VALID'
		THEN
			EXECUTE IMMEDIATE 'alter materialized view MV_SEC_TS_PRIVILEGES compile';


			DBMS_SNAPSHOT.refresh (list						 => 'CWMS_20.MV_SEC_TS_PRIVILEGES',
										  push_deferred_rpc		 => TRUE,
										  refresh_after_errors	 => FALSE,
										  purge_option 			 => 1,
										  parallelism				 => 0,
										  atomic_refresh			 => TRUE,
										  nested 					 => FALSE
										 );
		END IF;
	END;

	PROCEDURE start_refresh_mv_sec_privs_job
	IS
		l_count			  BINARY_INTEGER;
		l_user_id		  VARCHAR2 (30);
		l_job_id 		  VARCHAR2 (30) := 'REFRESH_MV_SEC_TS_PRIVS_JOB';
		l_run_interval   VARCHAR2 (8) := '5';
		l_comment		  VARCHAR2 (256);

		FUNCTION job_count
			RETURN BINARY_INTEGER
		IS
		BEGIN
			SELECT	COUNT ( * )
			  INTO	l_count
			  FROM	sys.dba_scheduler_jobs
			 WHERE	job_name = l_job_id AND owner = l_user_id;

			RETURN l_count;
		END;
	BEGIN
		--------------------------------------
		-- make sure we're the correct user --
		--------------------------------------
		l_user_id := cwms_util.get_user_id;

		IF l_user_id != 'CWMS_20'
		THEN
			raise_application_error (
				-20999,
				'Must be CWMS_20 user to start job ' || l_job_id,
				TRUE
			);
		END IF;

		-------------------------------------------
		-- drop the job if it is already running --
		-------------------------------------------
		IF job_count > 0
		THEN
			DBMS_OUTPUT.put ('Dropping existing job ' || l_job_id || '...');
			DBMS_SCHEDULER.drop_job (l_job_id);

			--------------------------------
			-- verify that it was dropped --
			--------------------------------
			IF job_count = 0
			THEN
				DBMS_OUTPUT.put_line ('done.');
			ELSE
				DBMS_OUTPUT.put_line ('failed.');
			END IF;
		END IF;

		IF job_count = 0
		THEN
			BEGIN
				---------------------
				-- restart the job --
				---------------------

				DBMS_SCHEDULER.create_job (
					job_name 			=> l_job_id,
					job_type 			=> 'stored_procedure',
					job_action			=> 'cwms_sec.refresh_mv_sec_ts_privileges',
					start_date			=> NULL,
					repeat_interval	=> 'freq=minutely; interval='
											  || l_run_interval,
					end_date 			=> NULL,
					job_class			=> 'default_job_class',
					enabled				=> TRUE,
					auto_drop			=> FALSE,
					comments 			=> 'Refreshes mv_sec_ts_privileges when needed.'
				);

				IF job_count = 1
				THEN
					DBMS_OUTPUT.put_line('Job ' || l_job_id
												|| ' successfully scheduled to execute every '
												|| l_run_interval
												|| ' minutes.');
				ELSE
					cwms_err.raise ('ITEM_NOT_CREATED', 'job', l_job_id);
				END IF;
			EXCEPTION
				WHEN OTHERS
				THEN
					cwms_err.raise ('ITEM_NOT_CREATED',
										 'job',
										 l_job_id || ':' || SQLERRM
										);
			END;
		END IF;
	END start_refresh_mv_sec_privs_job;
    
    /*
    storePrivilegeGroups(String username, String officeId,
        List<String> groupNameList, List<String> groupOfficeIdList,
        List<Boolean> groupAssignedList)
    */
/* Formatted on 7/15/2009 8:11:36 AM (QP5 v5.115.810.9015) */
    PROCEDURE store_priv_groups (p_username				 IN VARCHAR2,
                                          p_user_group_id_list	 IN char_32_array_type,
                                          p_db_office_id_list	 IN char_16_array_type,
                                          p_is_member_list		 IN char_16_array_type
                                         )
    IS
    BEGIN
        -- confirm user exicuting this call has privileges on all db_offices
        --   in the p_db_office_id_list
        IF p_db_office_id_list IS NULL
        THEN
            NULL;
        ELSE
            FOR i IN p_db_office_id_list.FIRST .. p_db_office_id_list.LAST
            LOOP
                confirm_user_admin_priv (
                    cwms_util.get_db_office_code (p_db_office_id_list (i))
                );
            END LOOP;
        END IF;
    END;
    --
    
END cwms_sec;
/
