SET DEFINE ON
@@defines.sql
/* Formatted on 11/18/2021 10:57:21 AM (QP5 v5.374) */
CREATE OR REPLACE PACKAGE BODY CWMS_20.cwms_sec
AS
    FUNCTION is_user_cwms_locked (p_db_office_code IN NUMBER)
        RETURN BOOLEAN
    IS
        l_is_locked   VARCHAR2 (1);
        l_username    VARCHAR2 (31) := cwms_util.get_user_id;
    BEGIN
        --
        -- CWMS_20, system, sys are ok
        --
        IF l_username IN ('CWMS_20', 'SYSTEM', 'SYS')
        THEN
            RETURN FALSE;
        END IF;

        --
        -- Check if user's account is locked for the p_db_office_code
        -- portion of the database...
        --

        BEGIN
            SELECT atslu.is_locked
              INTO l_is_locked
              FROM "AT_SEC_LOCKED_USERS" atslu
             WHERE     atslu.db_office_code = p_db_office_code
                   AND atslu.username = UPPER (l_username);
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                RETURN TRUE;
        END;

        IF l_is_locked = 'T'
        THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    END is_user_cwms_locked;

    FUNCTION is_user_admin (p_db_office_code IN NUMBER)
        RETURN BOOLEAN
    IS
        l_count       INTEGER := 0;
        l_is_locked   VARCHAR2 (1);
        l_username    VARCHAR2 (31) := cwms_util.get_user_id;
    BEGIN
        --
        -- CWMS_20, system, sys are ok
        --
        IF l_username IN ('CWMS_20', 'SYSTEM', 'SYS')
        THEN
            RETURN TRUE;
        END IF;

        --
        -- Check if user's account is locked for the p_db_office_code
        -- portion of the database...
        --

        IF is_user_cwms_locked (p_db_office_code)
        THEN
            RETURN FALSE;
        END IF;

        --
        -- Check if user's account has either "dba" or "CWMS User Admins"
        -- privileges.
        --
        SELECT COUNT (*)
          INTO l_count
          FROM "AT_SEC_USERS" atsu
         WHERE     atsu.db_office_code = p_db_office_code
               AND atsu.user_group_code IN
                       (user_group_code_dba_users,
                        user_group_code_user_admins)
               AND atsu.username = UPPER (l_username);

        IF l_count > 0
        THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    END is_user_admin;

    FUNCTION is_user_admin (p_db_office_id IN VARCHAR2 DEFAULT NULL)
        RETURN BOOLEAN
    IS
        l_db_office_id     VARCHAR2 (16)
                               := cwms_util.get_db_office_id (p_db_office_id);
        l_db_office_code   NUMBER
            := cwms_util.get_db_office_code (l_db_office_id);
    BEGIN
        RETURN is_user_admin (p_db_office_code => l_db_office_code);
    END is_user_admin;



    PROCEDURE confirm_user_admin_priv (p_db_office_code IN NUMBER)
    AS
    BEGIN
        IF is_user_admin (p_db_office_code => p_db_office_code)
        THEN
            NULL;
        ELSE
            cwms_err.raise (
                'ERROR',
                'Permission Denied. Your account needs "CWMS DBA" or "CWMS User Admin" privileges to use the cwms_sec package.');
        END IF;
    END confirm_user_admin_priv;

    PROCEDURE set_user_office_id (p_username       IN VARCHAR2,
                                  p_db_office_id   IN VARCHAR2)
    AS
        l_db_office_code   NUMBER
            := cwms_util.get_db_office_code (p_db_office_id);
        l_count            NUMBER;
        l_username         VARCHAR2 (31);
    BEGIN
        confirm_user_admin_priv (l_db_office_code);

        SELECT COUNT (*)
          INTO l_count
          FROM at_sec_user_office
         WHERE username = UPPER (TRIM (p_username));

        IF l_count > 0
        THEN
            UPDATE at_sec_user_office
               SET db_office_code = l_db_office_code
             WHERE username = UPPER (TRIM (p_username));
        ELSE
            cwms_err.raise (
                'ERROR',
                   'User: '
                || UPPER (TRIM (p_username))
                || ' is not a valid CWMS account name.');
        END IF;
    END;

    FUNCTION get_max_cwms_ts_group_code
        RETURN NUMBER
    AS
    BEGIN
        RETURN max_cwms_ts_group_code;
    END get_max_cwms_ts_group_code;

    FUNCTION find_lowest_code (p_list_of_codes   IN SYS_REFCURSOR,
                               p_lowest_code     IN NUMBER)
        RETURN NUMBER
    AS
        l_lowest_code   NUMBER;
        l_count         NUMBER;
        l_codes_array   number_tab_t;
    BEGIN
        NULL;

        FETCH p_list_of_codes BULK COLLECT INTO l_codes_array;

        CLOSE p_list_of_codes;


        BEGIN
            l_count := l_codes_array.COUNT;
        EXCEPTION
            WHEN COLLECTION_IS_NULL
            THEN
                l_count := 0;
        END;

        IF l_count = 0
        THEN
            RETURN p_lowest_code;
        END IF;

        SELECT MIN (COLUMN_VALUE)
          INTO l_lowest_code
          FROM TABLE (l_codes_array);

        IF l_lowest_code != p_lowest_code
        THEN
            RETURN p_lowest_code;
        END IF;

        --
        SELECT MIN (l_code)
          INTO l_lowest_code
          FROM (SELECT COLUMN_VALUE      l_code,
                         LEAD (COLUMN_VALUE) OVER (ORDER BY COLUMN_VALUE)
                       - COLUMN_VALUE    dif_value
                  FROM TABLE (l_codes_array))
         WHERE dif_value > 1;

        IF l_lowest_code IS NULL
        THEN
              SELECT MAX (COLUMN_VALUE)
                INTO l_lowest_code
                FROM TABLE (l_codes_array)
            ORDER BY COLUMN_VALUE;
        END IF;

        RETURN l_lowest_code + 1;
    --
    END find_lowest_code;

    --



    FUNCTION is_member_user_group (p_user_group_code   IN NUMBER,
                                   p_username          IN VARCHAR2,
                                   p_db_office_code    IN NUMBER)
        RETURN BOOLEAN
    AS
        l_count   NUMBER := 0;
    BEGIN
        SELECT COUNT (*)
          INTO l_count
          FROM at_sec_users a
         WHERE     a.db_office_code = p_db_office_code
               AND a.user_group_code = p_user_group_code
               AND a.username = UPPER (TRIM (p_username));

        IF l_count > 0
        THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    END is_member_user_group;

    PROCEDURE get_user_office_data (p_office_id          OUT VARCHAR2,
                                    p_office_long_name   OUT VARCHAR2)
    IS
    BEGIN
        cwms_util.get_user_office_data (p_office_id, p_office_long_name);
    END get_user_office_data;



    /*  cwms_sec.get_my_user_priv_groups(p_priv_groups  OUT sys_refcursor,
                                         p_db_office_id IN  VARCHAR2 DEFAULT NULL)

    This call is callable by anyone and returns a listing of that users
    priv_groups for the identified and/or the users default db_office_id.

    Returns a refcursor of:

    USERNAME
    USER_DB_OFFICE_ID
    USER_GROUP_TYPE     (either "Privelege User Group" or "TS Collection User Group"
    USER_GROUP_OWNER  ("CWMS" or the owning DB_OFFICE_ID)
    USER_GROUP_ID
    IS_MEMBER            ("T" or "F")
    USER_GROUP_DESC
    */

    FUNCTION get_assigned_priv_groups_tab (
        p_db_office_id   IN VARCHAR2 DEFAULT NULL)
        RETURN cat_priv_groups_tab_t
        PIPELINED
    IS
        query_cursor   SYS_REFCURSOR;
        output_row     cat_priv_groups_rec_t;
    BEGIN
        get_assigned_priv_groups (query_cursor, p_db_office_id);

        LOOP
            FETCH query_cursor INTO output_row;

            EXIT WHEN query_cursor%NOTFOUND;
            PIPE ROW (output_row);
        END LOOP;

        CLOSE query_cursor;

        RETURN;
    END get_assigned_priv_groups_tab;

    --

    PROCEDURE get_assigned_priv_groups (
        p_priv_groups       OUT SYS_REFCURSOR,
        p_db_office_id   IN     VARCHAR2 DEFAULT NULL)
    IS
        l_username         VARCHAR2 (31) := cwms_util.get_user_id;
        l_db_office_id     VARCHAR2 (16);
        l_db_office_code   NUMBER;
    BEGIN
        --
        IF p_db_office_id IS NULL
        THEN
            OPEN p_priv_groups FOR
                SELECT username,
                       db_office_id,
                       user_group_type,
                       user_group_owner,
                       user_group_id,
                       is_member,
                       user_group_desc
                  FROM av_sec_users
                 WHERE username = l_username AND is_member = 'T';
        ELSE
            l_db_office_id := cwms_util.get_db_office_id (p_db_office_id);
            l_db_office_code := cwms_util.get_db_office_code (l_db_office_id);

            OPEN p_priv_groups FOR
                SELECT username,
                       db_office_id,
                       user_group_type,
                       user_group_owner,
                       user_group_id,
                       is_member,
                       user_group_desc
                  FROM av_sec_users
                 WHERE     db_office_code = l_db_office_code
                       AND username = l_username
                       AND is_member = 'T';
        END IF;
    END get_assigned_priv_groups;

    /*--------------------------------------------------------------------------------
    The get_user_priv_groups procedure returns a refcursor of:

    USERNAME
    USER_DB_OFFICE_ID
    DB_OFFICE_ID
    USER_GROUP_TYPE  (either "Privelege User Group" or "TS Collection User Group"
    USER_GROUP_OWNER  ("CWMS" or the owning DB_OFFICE_ID)
    USER_GROUP_ID
    IS_MEMBER   ("T" or "F")
    USER_GROUP_DESC

    If p_username is null, then all usernames are returned
    If p_db_office_id is null, then the priv groups for all db_office_id's
    associated with the calling username's admin privileges.

    */

    FUNCTION get_user_priv_groups_tab (
        p_username       IN VARCHAR2 DEFAULT NULL,
        p_db_office_id   IN VARCHAR2 DEFAULT NULL)
        RETURN cat_priv_groups_tab_t
        PIPELINED
    IS
        query_cursor   SYS_REFCURSOR;
        output_row     cat_priv_groups_rec_t;
    BEGIN
        get_user_priv_groups (query_cursor, p_username, p_db_office_id);

        LOOP
            FETCH query_cursor INTO output_row;

            EXIT WHEN query_cursor%NOTFOUND;
            PIPE ROW (output_row);
        END LOOP;

        CLOSE query_cursor;

        RETURN;
    END get_user_priv_groups_tab;

    --

    PROCEDURE get_user_priv_groups (
        p_priv_groups       OUT SYS_REFCURSOR,
        p_username       IN     VARCHAR2 DEFAULT NULL,
        p_db_office_id   IN     VARCHAR2 DEFAULT NULL)
    IS
        l_db_office_id            VARCHAR2 (16);
        l_username                VARCHAR2 (31);
        l_db_office_code          NUMBER;
        l_retrieve_all_username   BOOLEAN;
        l_retrieve_all_offices    BOOLEAN;
        l_count                   NUMBER;
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
            SELECT COUNT (*)
              INTO l_count
              FROM at_sec_users
             WHERE     username = cwms_util.get_user_id
                   AND user_group_code IN
                           (user_group_code_dba_users,
                            user_group_code_user_admins);

            IF l_count = 0
            THEN
                cwms_err.raise (
                    'ERROR',
                    'Permission Denied. Your account needs "CWMS DBA" or "CWMS User Admin" privileges to use the cwms_sec package.');
            END IF;

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
                SELECT username,
                       db_office_id,
                       user_group_type,
                       user_group_owner,
                       user_group_id,
                       is_member,
                       user_group_desc
                  FROM av_sec_users
                 WHERE db_office_code IN
                           (SELECT UNIQUE db_office_code
                              FROM at_sec_users
                             WHERE     username = cwms_util.get_user_id
                                   AND user_group_code IN
                                           (user_group_code_dba_users,
                                            user_group_code_user_admins));
        ELSIF (l_retrieve_all_username AND NOT l_retrieve_all_offices)
        THEN
            OPEN p_priv_groups FOR SELECT username,
                                          db_office_id,
                                          user_group_type,
                                          user_group_owner,
                                          user_group_id,
                                          is_member,
                                          user_group_desc
                                     FROM av_sec_users
                                    WHERE db_office_code = l_db_office_code;
        ELSIF (NOT l_retrieve_all_username AND NOT l_retrieve_all_offices)
        THEN
            OPEN p_priv_groups FOR
                SELECT username,
                       db_office_id,
                       user_group_type,
                       user_group_owner,
                       user_group_id,
                       is_member,
                       user_group_desc
                  FROM av_sec_users
                 WHERE     db_office_code = l_db_office_code
                       AND username = l_username;
        ELSE
            OPEN p_priv_groups FOR
                SELECT username,
                       db_office_id,
                       user_group_type,
                       user_group_owner,
                       user_group_id,
                       is_member,
                       user_group_desc
                  FROM av_sec_users
                 WHERE     username = l_username
                       AND user_group_code != 10
                       AND db_office_code IN
                               (SELECT db_office_code
                                  FROM at_sec_locked_users
                                 WHERE     username = cwms_util.get_user_id
                                       AND db_office_code IN
                                               (SELECT UNIQUE
                                                       a.db_office_code
                                                  FROM at_sec_users a --, at_sec_locked_users b
                                                 WHERE     a.username =
                                                           cwms_util.get_user_id
                                                       AND a.user_group_code IN
                                                               (user_group_code_dba_users,
                                                                user_group_code_user_admins))
                                       AND is_locked = 'F');
        END IF;
    END get_user_priv_groups;

    ---
    ---
    /* get_ts_user_group_code return the user_group code for valid
    user_groups that can be coupled with ts_groups.

    Exception is thrown if the user_group is one of the primary
    privilege user groups.

    */

    FUNCTION get_ts_user_group_code (p_user_group_id    IN VARCHAR2,
                                     p_db_office_code   IN NUMBER)
        RETURN NUMBER
    AS
        l_user_group   NUMBER;
    BEGIN
        l_user_group :=
            get_user_group_code (p_user_group_id, p_db_office_code);

        IF l_user_group < 10
        THEN
            cwms_err.raise (
                'ERROR',
                   'User Group: '
                || p_user_group_id
                || ' is a primary privilege group, which cannot be paired with a TS Group.');
        ELSE
            RETURN l_user_group;
        END IF;
    END get_ts_user_group_code;

    FUNCTION get_ts_group_code (p_ts_group_id      IN VARCHAR2,
                                p_db_office_code   IN NUMBER)
        RETURN NUMBER
    AS
        l_ts_group_code   NUMBER;
    BEGIN
        BEGIN
            SELECT ts_group_code
              INTO l_ts_group_code
              FROM at_sec_ts_groups
             WHERE     UPPER (ts_group_id) = UPPER (TRIM (p_ts_group_id))
                   AND db_office_code = p_db_office_code;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                cwms_err.raise (
                    'ERROR',
                    'The ' || p_ts_group_id || ' is not a valid TS Group.');
        END;

        RETURN l_ts_group_code;
    END get_ts_group_code;

    FUNCTION get_user_office_id
        RETURN VARCHAR2
    IS
    BEGIN
        RETURN cwms_util.user_office_id;
    END get_user_office_id;

    PROCEDURE confirm_cwms_user (p_username IN VARCHAR2)
    IS
        l_count      NUMBER;
        l_username   VARCHAR2 (64);
    BEGIN
        IF (p_username is null)
        THEN
          cwms_err.raise('NULL_ARGUMENT', 'p_user_id');
        END IF;

        l_username := UPPER (TRIM (p_username));

        SELECT COUNT (*)
          INTO l_count
          FROM at_sec_user_office
         WHERE username = l_username;

        IF (l_count = 0 AND l_username <> cac_service_user)
        THEN
            raise_application_error (
                -20999,
                'The user ' || p_username || ' is not a valid CWMS user',
                TRUE);
        END IF;
    END confirm_cwms_user;

    PROCEDURE lock_db_account (p_username IN VARCHAR2)
    IS
        l_db_office_code   NUMBER := cwms_util.get_db_office_code (NULL);
    BEGIN
        confirm_user_admin_priv (l_db_office_code);
        confirm_cwms_user (p_username);

        cwms_dba.cwms_user_admin.lock_db_account (p_username);
    END lock_db_account;

    PROCEDURE unlock_db_account (p_username IN VARCHAR2)
    IS
        l_db_office_code   NUMBER := cwms_util.get_db_office_code (NULL);
    BEGIN
        confirm_user_admin_priv (l_db_office_code);
        confirm_cwms_user (p_username);

        cwms_dba.cwms_user_admin.unlock_db_account (p_username);
    END unlock_db_account;

    PROCEDURE create_cwms_db_account (
        p_username       IN VARCHAR2,
        p_db_office_id   IN VARCHAR2 DEFAULT NULL)
    IS
        l_username         VARCHAR2 (31) := UPPER (TRIM (p_username));
        l_is_locked        VARCHAR2 (1);
        l_db_office_id     VARCHAR2 (16)
                               := cwms_util.get_db_office_id (p_db_office_id);
        l_db_office_code   NUMBER
            := cwms_util.get_db_office_code (l_db_office_id);
        l_count            NUMBER;
    --
    BEGIN
        confirm_user_admin_priv (l_db_office_code);

        SELECT COUNT (*)
          INTO l_count
          FROM AT_SEC_CWMS_USERS
         WHERE userid = UPPER (p_username);

        IF (l_count = 0)
        THEN
            cwms_upass.update_user_data (p_username,
                                         NULL,
                                         NULL,
                                         NULL,
                                         NULL,
                                         NULL);
        END IF;


        BEGIN
            INSERT INTO at_sec_user_office (username, db_office_code)
                 VALUES (l_username, l_db_office_code);
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX
            THEN
                NULL;
        END;

        BEGIN
            SELECT is_locked
              INTO l_is_locked
              FROM at_sec_locked_users
             WHERE     db_office_code = l_db_office_code
                   AND username = l_username;

            IF l_is_locked != 'F'
            THEN
                UPDATE at_sec_locked_users
                   SET is_locked = 'F'
                 WHERE     db_office_code = l_db_office_code
                       AND username = l_username;
            END IF;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                INSERT INTO at_sec_locked_users (db_office_code,
                                                 username,
                                                 is_locked)
                     VALUES (l_db_office_code, l_username, 'F');
        END;

        BEGIN
            INSERT INTO at_sec_users (db_office_code,
                                      user_group_code,
                                      username)
                     VALUES (l_db_office_code,
                             user_group_code_all_users,
                             l_username);
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX
            THEN
                NULL;
        END;

        COMMIT;
    END create_cwms_db_account;

    PROCEDURE delete_cwms_db_account (p_username IN VARCHAR2)
    IS
    BEGIN
        cwms_err.raise (
            'ERROR',
            'Unable to delete user DB account - see your DBA to delete a DB account.');
    END delete_cwms_db_account;

    FUNCTION does_db_account_exist (p_username IN VARCHAR2)
        RETURN BOOLEAN
    IS
        l_count   NUMBER := 0;
    BEGIN
        SELECT COUNT (*)
          INTO l_count
          FROM dba_users
         WHERE username = UPPER (p_username);

        IF l_count = 0
        THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    END does_db_account_exist;

    PROCEDURE update_edipi (p_username       IN VARCHAR2,
                            p_edipi          IN NUMBER,
                            p_db_office_id   IN VARCHAR2 DEFAULT NULL)
    IS
        l_db_office_id     VARCHAR2 (16)
                               := cwms_util.get_db_office_id (p_db_office_id);
        l_db_office_code   NUMBER
            := cwms_util.get_db_office_code (l_db_office_id);
    BEGIN
        confirm_user_admin_priv (l_db_office_code);

        IF (p_edipi = 0)
        THEN
            RETURN;
        END IF;

        IF (LENGTH (TO_CHAR (p_edipi)) <> 10)
        THEN
            cwms_err.raise (
                'ERROR',
                'Invalid EDIPI (length not 10 digits): ' || p_edipi);
        END IF;

        UPDATE AT_SEC_CWMS_USERS
           SET principle_name = p_edipi || '@mil'
         WHERE USERID = UPPER (p_username);

        COMMIT;
    END update_edipi;

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
    -  If the user runing this procedure is not a member of the "CWMS DBA
    Users" privilege group or the "Users Admin" privilege group for the
    p_db_office_id.
    - If the p_username does not have any exiting privileges on the
    p_db_office_id data.
    -   If the p_username is already unlocked for the p_db_office_id data.
    -   If the p_username's Oracle Account is locked or if the p_username
    does not have an Oracle Account in the database.
    */
    PROCEDURE unlock_user (p_username       IN VARCHAR2,
                           p_db_office_id   IN VARCHAR2 DEFAULT NULL)
    IS
        l_db_office_code   NUMBER
            := cwms_util.get_db_office_code (p_db_office_id);
        l_count            NUMBER;
        l_username         VARCHAR2 (31);
    BEGIN
        confirm_user_admin_priv (l_db_office_code);
        confirm_cwms_user (p_username);


        l_username := UPPER (TRIM (p_username));

        SELECT COUNT (*)
          INTO l_count
          FROM at_sec_locked_users
         WHERE username = l_username AND db_office_code = l_db_office_code;

        IF l_count = 0
        THEN
            INSERT INTO at_sec_locked_users (db_office_code,
                                             username,
                                             is_locked)
                 VALUES (l_db_office_code, l_username, 'F');
        ELSE
            UPDATE at_sec_locked_users
               SET is_locked = 'F'
             WHERE     db_office_code = l_db_office_code
                   AND username = l_username;
        END IF;
    END unlock_user;

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

    FUNCTION get_user_group_code (p_user_group_id    IN VARCHAR2,
                                  p_db_office_code   IN NUMBER)
        RETURN NUMBER
    IS
        l_user_group_code   NUMBER;
    BEGIN
        BEGIN
            SELECT user_group_code
              INTO l_user_group_code
              FROM at_sec_user_groups
             WHERE     UPPER (user_group_id) = UPPER (p_user_group_id)
                   AND db_office_code = p_db_office_code;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                cwms_err.raise (
                    'ERROR',
                       'The '
                    || p_user_group_id
                    || ' is not a valid user group.');
        END;

        RETURN l_user_group_code;
    END get_user_group_code;

    PROCEDURE insert_noaccess_entry (p_username         IN VARCHAR2,
                                     p_db_office_code      NUMBER)
    IS
        l_count   NUMBER;
    BEGIN
        SELECT COUNT (*)
          INTO l_count
          FROM AT_SEC_CWMS_USERS
         WHERE userid = UPPER (p_username);

        IF (l_count = 0)
        THEN
            cwms_upass.update_user_data (p_username,
                                         NULL,
                                         NULL,
                                         NULL,
                                         NULL,
                                         NULL);
        END IF;

        SELECT COUNT (*)
          INTO L_count
          FROM AT_SEC_USER_OFFICE
         WHERE     USERNAME = UPPER (p_username)
               AND db_office_code = p_db_office_code;

        IF l_count = 0
        THEN
            INSERT INTO AT_SEC_USER_OFFICE (USERNAME, DB_OFFICE_CODE)
                 VALUES (UPPER (p_username), p_db_office_code);

            COMMIT;
        END IF;
    END insert_noaccess_entry;

    PROCEDURE add_user_to_group (p_username         IN VARCHAR2,
                                 p_user_group_id    IN VARCHAR2,
                                 p_db_office_code   IN NUMBER)
    IS
        l_user_group_code   NUMBER;
        l_username          VARCHAR2 (31) := UPPER (TRIM (p_username));
    BEGIN
        confirm_user_admin_priv (p_db_office_code);


        l_user_group_code :=
            get_user_group_code (p_user_group_id, p_db_office_code);

        BEGIN
            INSERT INTO at_sec_users (db_office_code,
                                      user_group_code,
                                      username)
                 VALUES (p_db_office_code, l_user_group_code, l_username);

            insert_noaccess_entry (p_username, p_db_office_code);
            COMMIT;

            IF (p_user_group_id = 'RDL Reviewer')
            THEN
                cwms_dba.cwms_user_admin.grant_rdl_role ('RDLREAD',
                                                         l_username);
            END IF;

            IF (p_user_group_id = 'RDL Mgr')
            THEN
                cwms_dba.cwms_user_admin.grant_rdl_role ('RDLCRUD',
                                                         l_username);
            END IF;
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX
            THEN
                NULL;
        END;
    END add_user_to_group;

    PROCEDURE add_user_to_group (p_username        IN VARCHAR2,
                                 p_user_group_id   IN VARCHAR2,
                                 p_db_office_id    IN VARCHAR2 DEFAULT NULL)
    IS
        l_db_office_code   NUMBER
            := cwms_util.get_db_office_code (p_db_office_id);
    BEGIN
        add_user_to_group (p_username         => p_username,
                           p_user_group_id    => p_user_group_id,
                           p_db_office_code   => l_db_office_code);
    END add_user_to_group;

    PROCEDURE confirm_db_user (p_username IN VARCHAR2)
    IS
        l_count   NUMBER;
    BEGIN
        SELECT COUNT (*)
          INTO l_count
          FROM dba_users
         WHERE username = UPPER (p_username);

        IF (l_count > 0)
        THEN
            RETURN;
        ELSE
            raise_application_error (
                -20999,
                   'The user '
                || p_username
                || ' doesn''t exist in the database',
                TRUE);
        END IF;
    END confirm_db_user;

    /*
    * Adds a read-only user to all offices in a database. Mainly meant for National CWMS Database

    *
    * @param p_username Oracle userid of the user that needs this privelege
    */

    PROCEDURE add_read_only_user_all_offices (p_username IN VARCHAR2)
    IS
        group_exists   EXCEPTION;
        PRAGMA EXCEPTION_INIT (group_exists, -20998);
        l_sql_string VARCHAR2(128); 
    BEGIN
        confirm_cwms_schema_user;

        CONFIRM_DB_USER (p_username);

        FOR c IN (SELECT office_code, office_id FROM cwms_office)
        LOOP
            insert_noaccess_entry (p_username, c.office_code);

            BEGIN
                create_user_group ('Viewer Users',
                                   'Limited Access CWMS Users.',
                                   c.office_id);
            EXCEPTION
                WHEN group_exists
                THEN
                    NULL;
            END;

            BEGIN
                create_user_group ('CWMS Users',
                                   'Routine CWMS Users.',
                                   c.office_id);
            EXCEPTION
                WHEN group_exists
                THEN
                    NULL;
            END;

            add_user_to_group (p_username         => p_username,
                               p_user_group_id    => 'Viewer Users',
                               p_db_office_code   => c.office_code);
            add_user_to_group (p_username         => p_username,
                               p_user_group_id    => 'CWMS Users',
                               p_db_office_code   => c.office_code);
        END LOOP;

        create_logon_trigger (p_username);
        l_sql_string :=
            'GRANT CWMS_USER TO ' || DBMS_ASSERT.simple_sql_name (p_username);
        --DBMS_OUTPUT.put_line (l_sql_string);
        cwms_util.check_dynamic_sql (l_sql_string);

        EXECUTE IMMEDIATE l_sql_string;
        cwms_dba.cwms_user_admin.grant_cwms_permissions (p_username);
        COMMIT;
    END add_read_only_user_all_offices;


    PROCEDURE create_logon_trigger (p_username IN VARCHAR2)
    IS
        l_cmd   VARCHAR (1024);
    BEGIN
        l_cmd :=
               'CREATE OR REPLACE TRIGGER '
            || p_username
            || '_logon_trigger AFTER LOGON ON '
            || p_username
            || '.SCHEMA BEGIN CWMS_20.cwms_env.set_session_privileges; END;';

        EXECUTE IMMEDIATE l_cmd;

        COMMIT;
    END;

----------------------------------------------------------------------------
   -- create_user
   ----------------------------------------------------------------------------

   /*

   From cwmsdb.CwmsSecJdbc
   createUser(String username, p_password,List<String> userGroupList,
                   String officeId)

   This procedure is deprecated. Create the database user separately and then call add_cwms_user
   */

   PROCEDURE create_user (p_username             IN VARCHAR2,
                          p_password             IN VARCHAR2,
                          p_user_group_id_list   IN char_32_array_type,
                          p_db_office_id         IN VARCHAR2 DEFAULT NULL)
   IS
   BEGIN
     add_cwms_user(p_username,p_user_group_id_list,p_db_office_id); 
   END create_user;
    ----------------------------------------------------------------------------
    -- add_cwms_user 
    ----------------------------------------------------------------------------

    /*

    From cwmsdb.CwmsSecJdbc
    add_cwms_user(String username, List<String> userGroupList,
                    String officeId)

    This procedure will add a CWMS user associated with the
    identified db_office_id.

    If the p_username is not an existing Oracle username/account,
    then a new warning message is logged. 

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

    PROCEDURE add_cwms_user (p_username             IN VARCHAR2,
                           p_user_group_id_list   IN char_32_array_type,
                           p_db_office_id         IN VARCHAR2 DEFAULT NULL)
    IS
        l_db_office_id      VARCHAR2 (16)
                                := cwms_util.get_db_office_id (p_db_office_id);
        l_db_office_code    NUMBER
            := cwms_util.get_db_office_code (l_db_office_id);
        l_username          VARCHAR2 (31) := UPPER (TRIM (p_username));
        l_user_group_code   NUMBER;
        l_count             NUMBER;
        l_user_exists       BOOLEAN;
        l_msg               VARCHAR2(1024);
	l_sql_string        VARCHAR2(128);
    BEGIN
        confirm_user_admin_priv (l_db_office_code);

        SELECT COUNT (username)
          INTO l_count
          FROM dba_users
         WHERE username = UPPER (p_username);

        IF (l_count = 0)
        THEN
            l_msg := 'Warning: User: ' || upper(p_username) || ' doesn''t exist in the database';
            dbms_output.put_line(l_msg);
            cwms_msg.log_db_message (cwms_msg.msg_level_basic,l_msg);
            l_user_exists := FALSE;
        ELSE
            l_user_exists := TRUE;
        END IF;

        SELECT COUNT (*)
         INTO l_count
         FROM AT_SEC_CWMS_USERS
        WHERE userid = UPPER (p_username);

        IF (l_count = 0)
        THEN
         cwms_upass.update_user_data (p_username,
                           NULL,
                           NULL,
                           NULL,
                           NULL,
                           NULL);
        END IF;

        BEGIN
          INSERT INTO at_sec_user_office (username, db_office_code)
              VALUES   (l_username, l_db_office_code);
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX
            THEN
                NULL;
        END;
        
        BEGIN
         INSERT INTO at_sec_users (db_office_code, user_group_code, username)
              VALUES (
                        l_db_office_code,
                        user_group_code_all_users,
                        l_username);
      EXCEPTION
         WHEN DUP_VAL_ON_INDEX
         THEN
            NULL;
      END;

        IF (p_user_group_id_list IS NOT NULL)
        THEN
            IF p_user_group_id_list.COUNT > 0
            THEN
                FOR i IN p_user_group_id_list.FIRST ..
                         p_user_group_id_list.LAST
                LOOP
                    l_user_group_code :=
                        get_user_group_code (p_user_group_id_list (i),
                                             l_db_office_code);
                END LOOP;
            END IF;
        END IF;


        IF (p_user_group_id_list IS NOT NULL)
        THEN
            IF p_user_group_id_list.COUNT > 0
            THEN
                FOR i IN p_user_group_id_list.FIRST ..
                         p_user_group_id_list.LAST
                LOOP
                    add_user_to_group (l_username,
                                       p_user_group_id_list (i),
                                       l_db_office_code);
                END LOOP;
            END IF;
        END IF;

        insert_noaccess_entry (UPPER (p_username), l_db_office_code);

        -- Do this only when DB user exists 
        if(l_user_exists) 
        then
            create_logon_trigger (p_username);
            l_sql_string :=
            	'GRANT CWMS_USER TO ' || DBMS_ASSERT.simple_sql_name (p_username);
            --DBMS_OUTPUT.put_line (l_sql_string);
           cwms_util.check_dynamic_sql (l_sql_string);

            EXECUTE IMMEDIATE l_sql_string;
            cwms_dba.cwms_user_admin.grant_cwms_permissions(p_username);
        end if;

        unlock_user(p_username,p_db_office_id);
        COMMIT;
    END add_cwms_user;

    FUNCTION generate_dod_password
        RETURN VARCHAR2
    IS
    --l_limit   VARCHAR2 (128) := NULL;
    BEGIN
        /*BEGIN
            SELECT CASE
                       WHEN LIMIT = 'DEFAULT'
                       THEN
                           (SELECT LIMIT
                              FROM dba_profiles
                             WHERE     resource_name =
                                       'PASSWORD_VERIFY_FUNCTION'
                                   AND profile = 'DEFAULT')
                       ELSE
                           LIMIT
                   END    LIMIT
              INTO l_limit
              FROM dba_profiles
             WHERE     resource_name = 'PASSWORD_VERIFY_FUNCTION'
                   AND profile IN (SELECT profile
                                     FROM dba_users
                                    WHERE username = cac_service_user);
        EXCEPTION
            WHEN OTHERS
            THEN
                NULL;
        END;*/

        --IF (l_limit IS NULL OR l_limit = 'NULL')
        --THEN
        --RETURN cwms_crypt.encrypt (
        --DBMS_RANDOM.string ('u', 13)
        --|| TRUNC(DBMS_RANDOM.VALUE (100, 1000)));
        --ELSE
        RETURN cwms_crypt.encrypt (
                      DBMS_RANDOM.string ('u', 5)
                   || '_'
                   || DBMS_RANDOM.string ('l', 5)
                   || '^'
                   || TRUNC (DBMS_RANDOM.VALUE (100, 1000)));
    --END IF;
    END generate_dod_password;


    /*

        From cwmsdb.CwmsSecJdbc
          deleteUser(String username)

        This procedure will delete the p_username from current session office id

        Exceptions are thrown if:
            - If the user running this procedure is not CWMS admin user

    */

    PROCEDURE delete_user (p_username IN VARCHAR2)
    IS
        l_username         VARCHAR2 (31);
        l_db_office_id     VARCHAR2 (16) := cwms_util.get_db_office_id (NULL);
        l_db_office_code   NUMBER
            := cwms_util.get_db_office_code (l_db_office_id);
    BEGIN
        l_username := UPPER (TRIM (p_username));

        IF (is_user_admin)
        THEN
            DELETE FROM
                at_sec_users
                  WHERE     username = l_username
                        AND db_office_code = l_db_office_code;


            DELETE FROM
                at_sec_locked_users
                  WHERE     username = l_username
                        AND db_office_code = l_db_office_code;

            DELETE FROM
                at_sec_user_office
                  WHERE     username = l_username
                        AND db_office_code = l_db_office_code;

            COMMIT;
        ELSE
            cwms_err.raise (
                'ERROR',
                'Permission Denied. Your account needs "CWMS DBA" or "CWMS User Admin" privileges to use the cwms_sec package.');
        END IF;
    END delete_user;

    ----------------------------------------------------------------------------
    -- delete_user
    ----------------------------------------------------------------------------
    /*

        From cwmsdb.CwmsSecJdbc
          deleteUser_from_all_offices(String username)

        This procedure will delete the p_username from all offices

        Exceptions are thrown if:
            - If the user running this procedure is not CWMS schema user

    */

    PROCEDURE delete_user_from_all_offices (p_username IN VARCHAR2)
    IS
        l_username   VARCHAR2 (31);
        l_count      NUMBER := 0;
    BEGIN
        l_username := UPPER (TRIM (p_username));
        confirm_cwms_schema_user;

        DELETE FROM at_sec_users
              WHERE username = l_username;


        DELETE FROM at_sec_locked_users
              WHERE username = l_username;

        DELETE FROM at_sec_user_office
              WHERE username = l_username;

        COMMIT;
    END delete_user_from_all_offices;

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

    PROCEDURE lock_user (p_username       IN VARCHAR2,
                         p_db_office_id   IN VARCHAR2 DEFAULT NULL)
    IS
        l_db_office_id     VARCHAR2 (16)
                               := cwms_util.get_db_office_id (p_db_office_id);
        l_db_office_code   NUMBER
            := cwms_util.get_db_office_code (l_db_office_id);
        l_count            NUMBER;
        l_username         VARCHAR2 (31);
    BEGIN
        confirm_user_admin_priv (l_db_office_code);

        l_username := UPPER (TRIM (p_username));

        -- Check if user has a DB Account...

        IF does_db_account_exist (l_username)
        THEN
            --   cwms_err.raise (
            --    'ERROR',
            --    'WARNING: ' || l_username
            --    || ' does not have a valid account, so unable to place a Lock on this username.'
            --   );


            -- Check if this user has any privileges on the p_db_office_id's data...

            --  SELECT COUNT ( * )
            --    INTO l_count
            --    FROM at_sec_users
            --   WHERE username = l_username AND db_office_code = l_db_office_code;
            --
            --  IF l_count = 0
            --  THEN
            --   cwms_err.raise (
            --    'ERROR',
            --     'WARNING: '
            --    || l_username
            --    || ' has no privileges assigned to the '
            --    || l_db_office_id
            --    || '''s data, so unable to place a Lock on this username for this office''s data.'
            --   );
            --  END IF;

            UPDATE at_sec_locked_users
               SET is_locked = 'T'
             WHERE     username = l_username
                   AND db_office_code = l_db_office_code;
        END IF;
    END lock_user;


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

    */
    PROCEDURE remove_user_from_group (
        p_username        IN VARCHAR2,
        p_user_group_id   IN VARCHAR2,
        p_db_office_id    IN VARCHAR2 DEFAULT NULL)
    IS
        l_db_office_code    NUMBER
            := cwms_util.get_db_office_code (p_db_office_id);
        l_user_group_code   NUMBER;
    BEGIN
        confirm_user_admin_priv (l_db_office_code);

        l_user_group_code :=
            get_user_group_code (p_user_group_id, l_db_office_code);

        IF l_user_group_code = user_group_code_all_users
        THEN
            cwms_err.raise (
                'ERROR',
                'Cannot remove users from the "All Users" User Group.');
        END IF;

        DELETE FROM
            at_sec_users
              WHERE     db_office_code = l_db_office_code
                    AND user_group_code = l_user_group_code
                    AND username = UPPER (p_username);

        COMMIT;

        IF (p_user_group_id = 'RDL Reviewer')
        THEN
            cwms_dba.cwms_user_admin.revoke_rdl_role ('RDLREAD', p_username);
        END IF;

        IF (p_user_group_id = 'RDL Mgr')
        THEN
            cwms_dba.cwms_user_admin.revoke_rdl_role ('RDLCRUD', p_username);
        END IF;
    END remove_user_from_group;

    ----------------------------------------------------------------------------
    -- get_user_state
    ----------------------------------------------------------------------------

    /*

     getUserState(String username, String officeId)
         */
    FUNCTION get_user_state (p_username       IN VARCHAR2,
                             p_db_office_id   IN VARCHAR2 DEFAULT NULL)
        RETURN VARCHAR2
    IS
        l_db_office_id     VARCHAR2 (16)
                               := cwms_util.get_db_office_id (p_db_office_id);
        l_db_office_code   NUMBER
            := cwms_util.get_db_office_code (l_db_office_id);
        l_account_status   VARCHAR2 (32) := NULL;
        l_is_locked        VARCHAR2 (1);
        l_username         VARCHAR2 (31) := UPPER (TRIM (p_username));
    BEGIN
        confirm_user_admin_priv (l_db_office_code);

        BEGIN
            SELECT userid
              INTO l_account_status
              FROM at_sec_cwms_users
             WHERE userid = l_username;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                RETURN acc_state_no_account;
        END;
                
        BEGIN
            SELECT is_locked
                INTO l_is_locked
                FROM at_sec_locked_users
                WHERE     username = l_username
                    AND db_office_code = l_db_office_code;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                RETURN acc_state_locked;
        END;

        IF l_is_locked = 'T'
        THEN
            RETURN acc_state_locked;
        ELSE
            RETURN acc_state_unlocked;
        END IF;
        
    END get_user_state;


    PROCEDURE assign_ts_group_user_group (
        p_ts_group_id     IN VARCHAR2,
        p_user_group_id   IN VARCHAR2,
        p_privilege       IN VARCHAR2,                  -- none, read or write
        p_db_office_id    IN VARCHAR2 DEFAULT NULL)
    AS
        l_db_office_id      VARCHAR2 (16)
                                := cwms_util.get_db_office_id (p_db_office_id);
        l_db_office_code    NUMBER
            := cwms_util.get_db_office_code (l_db_office_id);
        l_privilege         VARCHAR2 (10);
        l_user_group_code   NUMBER;
        l_ts_group_code     NUMBER;
        l_sum_priv_bit      NUMBER := NULL;
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
                   'Unrecognized p_privilege: '
                || p_privilege
                || ' "None", "Read" or "Read-Write" are the only valid privileges.');
        END IF;

        l_user_group_code :=
            get_ts_user_group_code (p_user_group_id, l_db_office_code);

        l_ts_group_code :=
            get_ts_group_code (p_ts_group_id, l_db_office_code);

        -- Determine if read/write priv's are already set for this group pair..

        SELECT SUM (privilege_bit)
          INTO l_sum_priv_bit
          FROM at_sec_allow
         WHERE     db_office_code = l_db_office_code
               AND ts_group_code = l_ts_group_code
               AND user_group_code = l_user_group_code;

        IF l_sum_priv_bit IS NOT NULL
        THEN
            DELETE FROM
                at_sec_allow
                  WHERE     db_office_code = l_db_office_code
                        AND ts_group_code = l_ts_group_code
                        AND user_group_code = l_user_group_code;
        END IF;

        IF l_privilege IN ('READ', 'READ-WRITE')
        THEN
            INSERT INTO at_sec_allow (db_office_code,
                                      ts_group_code,
                                      user_group_code,
                                      privilege_bit)
                 VALUES (l_db_office_code,
                         l_ts_group_code,
                         l_user_group_code,
                         2);
        END IF;

        IF l_privilege IN ('WRITE', 'READ-WRITE')
        THEN
            INSERT INTO at_sec_allow (db_office_code,
                                      ts_group_code,
                                      user_group_code,
                                      privilege_bit)
                 VALUES (l_db_office_code,
                         l_ts_group_code,
                         l_user_group_code,
                         4);
        END IF;
    END assign_ts_group_user_group;

    PROCEDURE cat_at_sec_allow (
        p_at_sec_allow      OUT SYS_REFCURSOR,
        p_db_office_id   IN     VARCHAR2 DEFAULT NULL)
    AS
        l_db_office_code   NUMBER
            := cwms_util.get_db_office_code (p_db_office_id);
    BEGIN
        confirm_user_admin_priv (l_db_office_code);

        OPEN p_at_sec_allow FOR
              SELECT db_office_code,
                     user_group_code,
                     ts_group_code,
                     db_office_id,
                     user_group_id,
                     ts_group_id,
                     priv_sum,
                     DECODE (priv_sum,
                             2, 'READ',
                             4, 'WRITE',
                             6, 'READ-WRITE',
                             NULL)    priv
                FROM (  SELECT db_office_code,
                               user_group_code,
                               ts_group_code,
                               db_office_id,
                               user_group_id,
                               ts_group_id,
                               SUM (b.privilege_bit)     priv_sum
                          FROM (SELECT a.db_office_code,
                                       a.user_group_code,
                                       c.ts_group_code,
                                       b.office_id     db_office_id,
                                       a.user_group_id,
                                       c.ts_group_id
                                  FROM at_sec_user_groups a,
                                       cwms_office     b,
                                       at_sec_ts_groups c
                                 WHERE     a.db_office_code = b.office_code
                                       AND a.db_office_code = l_db_office_code
                                       AND c.db_office_code = l_db_office_code
                                       AND a.user_group_code >
                                           max_cwms_priv_ugroup_code) a
                               LEFT OUTER JOIN at_sec_allow b
                                   USING (db_office_code,
                                          user_group_code,
                                          ts_group_code)
                      GROUP BY db_office_code,
                               user_group_code,
                               ts_group_code,
                               db_office_id,
                               user_group_id,
                               ts_group_id) a
            ORDER BY user_group_id, ts_group_id;
    END cat_at_sec_allow;

    FUNCTION cat_at_sec_allow_tab (p_db_office_id IN VARCHAR2 DEFAULT NULL)
        RETURN cat_at_sec_allow_tab_t
        PIPELINED
    IS
        query_cursor   SYS_REFCURSOR;
        output_row     cat_at_sec_allow_rec_t;
    BEGIN
        cat_at_sec_allow (query_cursor, p_db_office_id);

        LOOP
            FETCH query_cursor INTO output_row;

            EXIT WHEN query_cursor%NOTFOUND;
            PIPE ROW (output_row);
        END LOOP;

        CLOSE query_cursor;

        RETURN;
    END cat_at_sec_allow_tab;


    PROCEDURE start_sec_job (p_job_id         VARCHAR2,
                             p_run_interval   NUMBER,
                             p_action         VARCHAR2,
                             p_comment        VARCHAR2)
    IS
        l_count     BINARY_INTEGER;
        l_user_id   VARCHAR2 (30);

        FUNCTION job_count
            RETURN BINARY_INTEGER
        IS
        BEGIN
            SELECT COUNT (*)
              INTO l_count
              FROM sys.dba_scheduler_jobs
             WHERE job_name = p_job_id AND owner = l_user_id;

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
                'Must be CWMS_20 user to start job ' || p_job_id,
                TRUE);
        END IF;

        -------------------------------------------
        -- drop the job if it is already running --
        -------------------------------------------
        IF job_count > 0
        THEN
            DBMS_OUTPUT.put ('Dropping existing job ' || p_job_id || '...');
            DBMS_SCHEDULER.drop_job (p_job_id);

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
                    job_name          => p_job_id,
                    job_type          => 'stored_procedure',
                    job_action        => p_action,
                    start_date        => NULL,
                    repeat_interval   =>
                        'freq=minutely; interval=' || p_run_interval,
                    end_date          => NULL,
                    job_class         => 'default_job_class',
                    enabled           => TRUE,
                    auto_drop         => FALSE,
                    comments          => p_comment);

                IF job_count = 1
                THEN
                    DBMS_OUTPUT.put_line (
                           'Job '
                        || p_job_id
                        || ' successfully scheduled to execute every '
                        || p_run_interval
                        || ' minutes.');
                ELSE
                    cwms_err.raise ('ITEM_NOT_CREATED', 'job', p_job_id);
                END IF;
            EXCEPTION
                WHEN OTHERS
                THEN
                    cwms_err.raise ('ITEM_NOT_CREATED',
                                    'job',
                                    p_job_id || ':' || SQLERRM);
            END;
        END IF;
    END start_sec_job;

    PROCEDURE start_clean_session_job
    IS
    BEGIN
        start_sec_job ('CLEAN_SESSION_KEYS_JOB',
                       1,
                       'cwms_sec.clean_session_keys',
                       'Clean expired session keys');
    END start_clean_session_job;

    /*
    storePrivilegeGroups(String username, String officeId,
        List<String> groupNameList, List<String> groupOfficeIdList,
        List<Boolean> groupAssignedList)
    */

    PROCEDURE store_priv_groups (
        p_username             IN VARCHAR2,
        p_user_group_id_list   IN char_32_array_type,
        p_db_office_id_list    IN char_16_array_type,
        p_is_member_list       IN char_16_array_type)
    IS
        l_db_office_code_list   number_tab_t := number_tab_t ();
        l_is_member_list        char_16_array_type := char_16_array_type ();
        l_user_group_code       NUMBER;
        l_username              VARCHAR2 (31);
    BEGIN
        -- confirm user exicuting this call has privileges on all db_offices
        --   in the p_db_office_id_list
        IF p_db_office_id_list.COUNT = 0
        THEN
            RETURN;
        ELSE
            FOR i IN p_db_office_id_list.FIRST .. p_db_office_id_list.LAST
            LOOP
                l_db_office_code_list.EXTEND;
                l_db_office_code_list (i) :=
                    cwms_util.get_db_office_code (p_db_office_id_list (i));
                confirm_user_admin_priv (l_db_office_code_list (i));

                l_user_group_code :=
                    get_user_group_code (p_user_group_id_list (i),
                                         l_db_office_code_list (i));

                l_is_member_list.EXTEND;
                l_is_member_list (i) :=
                    cwms_util.return_t_or_f_flag (p_is_member_list (i));

                IF     l_is_member_list (i) = 'F'
                   AND l_user_group_code = user_group_code_all_users
                THEN
                    cwms_err.raise (
                        'ERROR',
                        'Cannot remove users from the "All Users" User Group.');
                END IF;
            END LOOP;
        END IF;

        --
        l_username := UPPER (TRIM (p_username));

        --
        -- Calling user has USER ADMIN privileges and all user groups are valid so
        -- make the assignements...
        --
        FOR i IN p_db_office_id_list.FIRST .. p_db_office_id_list.LAST
        LOOP
            IF l_is_member_list (i) = 'T'
            THEN
                add_user_to_group (
                    p_username         => l_username,
                    p_user_group_id    => p_user_group_id_list (i),
                    p_db_office_code   => l_db_office_code_list (i));
            ELSE
                remove_user_from_group (
                    p_username        => l_username,
                    p_user_group_id   => p_user_group_id_list (i),
                    p_db_office_id    => p_db_office_id_list (i));
            END IF;
        END LOOP;
    END store_priv_groups;

    --

    PROCEDURE change_user_group_id (
        p_user_group_id_old   IN VARCHAR2,
        p_user_group_id_new   IN VARCHAR2,
        p_db_office_id        IN VARCHAR2 DEFAULT NULL)
    AS
        l_db_office_code        NUMBER
            := cwms_util.get_db_office_code (p_db_office_id);
        l_user_group_code       NUMBER;
        l_user_group_code_new   NUMBER;
    BEGIN
        confirm_user_admin_priv (l_db_office_code);

        --
        BEGIN
            l_user_group_code :=
                get_user_group_code (p_user_group_id    => p_user_group_id_old,
                                     p_db_office_code   => l_db_office_code);
        EXCEPTION
            WHEN OTHERS
            THEN
                cwms_err.raise (
                    'ERROR',
                       'Cannot rename '
                    || TRIM (p_user_group_id_old)
                    || ' because it does not exist.');
        END;

        IF l_user_group_code <= max_cwms_ts_ugroup_code
        THEN
            cwms_err.raise (
                'ERROR',
                   'Cannot rename '
                || TRIM (p_user_group_id_old)
                || ' because it is owned by the system.');
        END IF;

        BEGIN
            l_user_group_code_new :=
                get_user_group_code (p_user_group_id    => p_user_group_id_new,
                                     p_db_office_code   => l_db_office_code);
            l_user_group_code_new := 0;
        EXCEPTION
            WHEN OTHERS
            THEN
                l_user_group_code_new := 1;
        END;

        IF l_user_group_code_new = 0
        THEN
            cwms_err.raise (
                'ERROR',
                   'Cannot rename '
                || TRIM (p_user_group_id_old)
                || ' to '
                || TRIM (p_user_group_id_new)
                || ' because '
                || TRIM (p_user_group_id_new)
                || ' already exists.');
        END IF;

        UPDATE at_sec_user_groups
           SET user_group_id = TRIM (p_user_group_id_new)
         WHERE     user_group_code = l_user_group_code
               AND db_office_code = l_db_office_code;

        COMMIT;
    END change_user_group_id;

    PROCEDURE change_user_group_desc (
        p_user_group_id     IN VARCHAR2,
        p_user_group_desc   IN VARCHAR2,
        p_db_office_id      IN VARCHAR2 DEFAULT NULL)
    AS
        l_db_office_code    NUMBER
            := cwms_util.get_db_office_code (p_db_office_id);
        l_user_group_code   NUMBER;
    BEGIN
        confirm_user_admin_priv (l_db_office_code);

        --
        BEGIN
            l_user_group_code :=
                get_user_group_code (p_user_group_id    => p_user_group_id,
                                     p_db_office_code   => l_db_office_code);
        EXCEPTION
            WHEN OTHERS
            THEN
                cwms_err.raise (
                    'ERROR',
                       'Cannot change the User Group Description of the '
                    || TRIM (p_user_group_id)
                    || ' because the user group does not exist.');
        END;

        IF l_user_group_code <= max_cwms_ts_ugroup_code
        THEN
            cwms_err.raise (
                'ERROR',
                   'Cannot change the User Group Description of the '
                || TRIM (p_user_group_id)
                || ' because it is owned by the system.');
        END IF;

        UPDATE at_sec_user_groups
           SET user_group_desc = TRIM (p_user_group_desc)
         WHERE     user_group_code = l_user_group_code
               AND db_office_code = l_db_office_code;

        COMMIT;
    END change_user_group_desc;


    PROCEDURE delete_user_group (p_user_group_id   IN VARCHAR2,
                                 p_db_office_id    IN VARCHAR2 DEFAULT NULL)
    AS
        l_db_office_code    NUMBER
            := cwms_util.get_db_office_code (p_db_office_id);
        l_user_group_code   NUMBER;
    BEGIN
        confirm_user_admin_priv (l_db_office_code);

        --
        BEGIN
            l_user_group_code :=
                get_user_group_code (p_user_group_id    => p_user_group_id,
                                     p_db_office_code   => l_db_office_code);
        EXCEPTION
            WHEN OTHERS
            THEN
                RETURN;               -- silent when user_group does not exist
        END;

        IF l_user_group_code <= max_cwms_ts_ugroup_code
        THEN
            cwms_err.raise (
                'ERROR',
                   'Cannot delete '
                || TRIM (p_user_group_id)
                || ' because it is owned by the system.');
        END IF;

        --
        -- delete all at_sec_allow pairings with this user_group...
        --
        DELETE FROM
            at_sec_allow
              WHERE     user_group_code = l_user_group_code
                    AND db_office_code = l_db_office_code;

        --
        -- delete all at_sec_users entries with this user_code...
        --
        DELETE FROM
            at_sec_users
              WHERE     user_group_code = l_user_group_code
                    AND db_office_code = l_db_office_code;

        --
        -- finally delete the user_group from at_sec_user_groups...
        --
        DELETE FROM
            at_sec_user_groups
              WHERE     user_group_code = l_user_group_code
                    AND db_office_code = l_db_office_code;

        --
        COMMIT;
    --
    END delete_user_group;


    PROCEDURE create_user_group (
        p_user_group_id     IN VARCHAR2,
        p_user_group_desc   IN VARCHAR2,
        p_db_office_id      IN VARCHAR2 DEFAULT NULL)
    AS
        l_db_office_code     NUMBER
            := cwms_util.get_db_office_code (p_db_office_id);
        l_lowest_code        NUMBER;
        l_user_group_desc    VARCHAR2 (256);
        l_user_group_id      VARCHAR2 (32);
        l_error              BOOLEAN := TRUE;
        l_user_group_codes   SYS_REFCURSOR;
    BEGIN
        confirm_user_admin_priv (l_db_office_code);
        --
        l_user_group_id := TRIM (p_user_group_id);

        --
        -- Confirm that the new user_group_id is unique
        --
        BEGIN
            SELECT user_group_desc
              INTO l_user_group_desc
              FROM at_sec_user_groups
             WHERE     db_office_code = l_db_office_code
                   AND UPPER (user_group_id) = UPPER (l_user_group_id);
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                l_error := FALSE;
        END;

        --
        IF l_error
        THEN
            cwms_err.raise (
                'ERROR',
                   'Unable to create new User Group. The User Group '
                || l_user_group_id
                || ' already exists. The existing User Group Description of: '
                || l_user_group_desc);
        END IF;

        --
        -- Determine lowest available user_group_code
        --
        OPEN l_user_group_codes FOR
            SELECT user_group_code
              FROM at_sec_user_groups
             WHERE     db_office_code = l_db_office_code
                   AND user_group_code > max_cwms_ts_ugroup_code;

        --
        l_lowest_code :=
            find_lowest_code (l_user_group_codes,
                              max_cwms_ts_ugroup_code + 1);

        --
        INSERT INTO at_sec_user_groups (db_office_code,
                                        user_group_code,
                                        user_group_id,
                                        user_group_desc)
             VALUES (l_db_office_code,
                     l_lowest_code,
                     l_user_group_id,
                     TRIM (p_user_group_desc));
    END create_user_group;


    PROCEDURE delete_ts_group (p_ts_group_id    IN VARCHAR2,
                               p_db_office_id   IN VARCHAR2 DEFAULT NULL)
    AS
        l_db_office_code   NUMBER
            := cwms_util.get_db_office_code (p_db_office_id);
        l_ts_group_code    NUMBER;
    BEGIN
        confirm_user_admin_priv (l_db_office_code);

        --
        BEGIN
            l_ts_group_code :=
                get_ts_group_code (p_ts_group_id      => p_ts_group_id,
                                   p_db_office_code   => l_db_office_code);
        EXCEPTION
            WHEN OTHERS
            THEN
                RETURN;               -- silent when user_group does not exist
        END;

        IF l_ts_group_code <= max_cwms_ts_group_code
        THEN
            cwms_err.raise (
                'ERROR',
                   'Cannot delete '
                || TRIM (p_ts_group_id)
                || ' because it is owned by the system.');
        END IF;

        --
        -- delete all at_sec_allow pairings with this user_group...
        --
        DELETE FROM
            at_sec_allow
              WHERE     ts_group_code = l_ts_group_code
                    AND db_office_code = l_db_office_code;

        --
        -- delete all at_sec_users entries with this user_code...
        --
        DELETE FROM
            at_sec_ts_group_masks
              WHERE     ts_group_code = l_ts_group_code
                    AND db_office_code = l_db_office_code;

        --
        -- finally delete the user_group from at_sec_user_groups...
        --
        DELETE FROM
            at_sec_ts_groups
              WHERE     ts_group_code = l_ts_group_code
                    AND db_office_code = l_db_office_code;

        --
        COMMIT;
    --
    END delete_ts_group;

    PROCEDURE change_ts_group_id (
        p_ts_group_id_old   IN VARCHAR2,
        p_ts_group_id_new   IN VARCHAR2,
        p_db_office_id      IN VARCHAR2 DEFAULT NULL)
    AS
        l_db_office_code      NUMBER
            := cwms_util.get_db_office_code (p_db_office_id);
        l_ts_group_code       NUMBER;
        l_ts_group_code_new   NUMBER;
    BEGIN
        confirm_user_admin_priv (l_db_office_code);

        --
        BEGIN
            l_ts_group_code :=
                get_ts_group_code (p_ts_group_id      => p_ts_group_id_old,
                                   p_db_office_code   => l_db_office_code);
        EXCEPTION
            WHEN OTHERS
            THEN
                cwms_err.raise (
                    'ERROR',
                       'Cannot rename '
                    || TRIM (p_ts_group_id_old)
                    || ' because it does not exist.');
        END;

        IF l_ts_group_code <= max_cwms_ts_group_code
        THEN
            cwms_err.raise (
                'ERROR',
                   'Cannot rename '
                || TRIM (p_ts_group_id_old)
                || ' because it is owned by the system.');
        END IF;

        BEGIN
            l_ts_group_code_new :=
                get_ts_group_code (p_ts_group_id      => p_ts_group_id_new,
                                   p_db_office_code   => l_db_office_code);
            l_ts_group_code_new := 0;
        EXCEPTION
            WHEN OTHERS
            THEN
                l_ts_group_code_new := 1;
        END;

        IF l_ts_group_code_new = 0
        THEN
            cwms_err.raise (
                'ERROR',
                   'Cannot rename '
                || TRIM (p_ts_group_id_old)
                || ' to '
                || TRIM (p_ts_group_id_new)
                || ' because '
                || TRIM (p_ts_group_id_new)
                || ' already exists.');
        END IF;

        UPDATE at_sec_ts_groups
           SET ts_group_id = TRIM (p_ts_group_id_new)
         WHERE     ts_group_code = l_ts_group_code
               AND db_office_code = l_db_office_code;

        COMMIT;
    END change_ts_group_id;

    PROCEDURE change_ts_group_desc (
        p_ts_group_id     IN VARCHAR2,
        p_ts_group_desc   IN VARCHAR2,
        p_db_office_id    IN VARCHAR2 DEFAULT NULL)
    AS
        l_db_office_code   NUMBER
            := cwms_util.get_db_office_code (p_db_office_id);
        l_ts_group_code    NUMBER;
    BEGIN
        confirm_user_admin_priv (l_db_office_code);

        --
        BEGIN
            l_ts_group_code :=
                get_ts_group_code (p_ts_group_id      => p_ts_group_id,
                                   p_db_office_code   => l_db_office_code);
        EXCEPTION
            WHEN OTHERS
            THEN
                cwms_err.raise (
                    'ERROR',
                       'Cannot change the TS Group Description of the '
                    || TRIM (p_ts_group_id)
                    || ' because the TS Group does not exist.');
        END;

        IF l_ts_group_code <= max_cwms_ts_group_code
        THEN
            cwms_err.raise (
                'ERROR',
                   'Cannot change the TS Group Description of the '
                || TRIM (p_ts_group_id)
                || ' because it is owned by the system.');
        END IF;

        UPDATE at_sec_ts_groups
           SET ts_group_desc = TRIM (p_ts_group_desc)
         WHERE     ts_group_code = l_ts_group_code
               AND db_office_code = l_db_office_code;

        COMMIT;
    END change_ts_group_desc;

    PROCEDURE create_ts_group (p_ts_group_id     IN VARCHAR2,
                               p_ts_group_desc   IN VARCHAR2,
                               p_db_office_id    IN VARCHAR2 DEFAULT NULL)
    AS
        l_db_office_code   NUMBER
            := cwms_util.get_db_office_code (p_db_office_id);
        l_lowest_code      NUMBER;
        l_ts_group_desc    VARCHAR2 (256);
        l_ts_group_id      VARCHAR2 (32);
        l_error            BOOLEAN := TRUE;
        l_ts_group_codes   SYS_REFCURSOR;
    BEGIN
        confirm_user_admin_priv (l_db_office_code);

        l_ts_group_id := TRIM (p_ts_group_id);

        --
        --Confirm that the new ts_group_id is unique
        --

        BEGIN
            SELECT ts_group_desc
              INTO l_ts_group_desc
              FROM at_sec_ts_groups
             WHERE     db_office_code = l_db_office_code
                   AND ts_group_code > max_cwms_ts_group_code
                   AND UPPER (ts_group_id) = UPPER (l_ts_group_id);
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                l_error := FALSE;
        END;

        --
        IF l_error
        THEN
            cwms_err.raise (
                'ERROR',
                   'Unable to create new TS Collection. The TS Group '
                || l_ts_group_id
                || ' already exists. The existing Collection Group has a Description of: '
                || l_ts_group_desc);
        END IF;

        --
        -- Determine lowest available ts_group_code
        --
        OPEN l_ts_group_codes FOR
            SELECT ts_group_code
              FROM at_sec_ts_groups
             WHERE     db_office_code = l_db_office_code
                   AND ts_group_code > max_cwms_ts_group_code;

        --
        l_lowest_code :=
            find_lowest_code (l_ts_group_codes, max_cwms_ts_group_code + 1);

        --
        INSERT INTO at_sec_ts_groups (db_office_code,
                                      ts_group_code,
                                      ts_group_id,
                                      ts_group_desc)
             VALUES (l_db_office_code,
                     l_lowest_code,
                     l_ts_group_id,
                     TRIM (p_ts_group_desc));
    END create_ts_group;


    PROCEDURE assign_ts_masks_to_ts_group (
        p_ts_group_id       IN VARCHAR2,
        p_ts_mask_list      IN str_tab_t,
        p_add_remove_list   IN char_16_array_type,
        p_db_office_id      IN VARCHAR2 DEFAULT NULL)
    AS
        l_db_office_code   NUMBER
            := cwms_util.get_db_office_code (p_db_office_id);
        l_ts_group_code    NUMBER;
        l_count            NUMBER;
        l_ts_mask          VARCHAR2 (191);
    BEGIN
        confirm_user_admin_priv (l_db_office_code);
        --
        l_ts_group_code :=
            get_ts_group_code (p_ts_group_id, l_db_office_code);

        IF l_ts_group_code <= max_cwms_ts_group_code
        THEN
            cwms_err.raise (
                'ERROR',
                   'Cannot assign/reassign TS Masks from the '
                || TRIM (p_ts_group_id)
                || ' TS Group because it is owned by the system.');
        END IF;

        BEGIN
            l_count := p_ts_mask_list.COUNT;
        EXCEPTION
            WHEN COLLECTION_IS_NULL
            THEN
                cwms_err.raise ('ERROR',
                                'The p_ts_mask_list has not records.');
        END;

        --
        IF p_ts_mask_list.COUNT != p_add_remove_list.COUNT
        THEN
            cwms_err.raise (
                'ERROR',
                   'Unable to assign/reassign TS masks because the p_ts_mask_list and p_add_remove_lists are mismatched. The p_ts_mask_list has '
                || p_ts_mask_list.COUNT
                || ' elements and the p_add_remove_list has '
                || p_add_remove_list.COUNT
                || ' elements.');
        END IF;

        SELECT COUNT (*)
          INTO l_count
          FROM TABLE (p_add_remove_list)
         WHERE UPPER (TRIM (COLUMN_VALUE)) NOT IN ('ADD', 'REMOVE');

        IF l_count > 0
        THEN
            cwms_err.raise (
                'ERROR',
                'Unable to assign/reassign TS Masks because the p_add_remove_list contains invalid values. Valid values are "Add" or "Remove".');
        END IF;

        --
        FOR i IN 1 .. p_add_remove_list.LAST
        LOOP
            l_ts_mask :=
                cwms_util.normalize_wildcards (
                    UPPER (TRIM (p_ts_mask_list (i))));

            IF UPPER (TRIM (p_add_remove_list (i))) = 'ADD'
            THEN
                BEGIN
                    INSERT INTO at_sec_ts_group_masks (db_office_code,
                                                       ts_group_code,
                                                       ts_group_mask)
                             VALUES (l_db_office_code,
                                     l_ts_group_code,
                                     l_ts_mask);
                EXCEPTION
                    WHEN DUP_VAL_ON_INDEX
                    THEN
                        NULL;
                END;
            ELSE
                DELETE FROM
                    at_sec_ts_group_masks
                      WHERE     db_office_code = l_db_office_code
                            AND UPPER (ts_group_mask) = l_ts_mask;
            END IF;

            COMMIT;
        END LOOP;
    END assign_ts_masks_to_ts_group;

    /*
    clear_ts_masks deletes all ts masks from the identified ts_group_id.
    */
    PROCEDURE clear_ts_masks (p_ts_group_id    IN VARCHAR2,
                              p_db_office_id   IN VARCHAR2 DEFAULT NULL)
    AS
        l_db_office_code   NUMBER
            := cwms_util.get_db_office_code (p_db_office_id);
        l_ts_group_code    NUMBER;
    BEGIN
        confirm_user_admin_priv (l_db_office_code);
        --
        l_ts_group_code :=
            get_ts_group_code (p_ts_group_id, l_db_office_code);

        IF l_ts_group_code <= max_cwms_ts_group_code
        THEN
            cwms_err.raise (
                'ERROR',
                   'Cannot clear TS Masks from the '
                || TRIM (p_ts_group_id)
                || ' TS Group because it is owned by the system.');
        END IF;

        DELETE FROM
            at_sec_ts_group_masks
              WHERE     ts_group_code = l_ts_group_code
                    AND db_office_code = l_db_office_code;

        COMMIT;
    END clear_ts_masks;

    FUNCTION get_this_db_office_code
        RETURN NUMBER
    IS
        l_db_office_code   NUMBER;
    BEGIN
        SELECT MOD (min_value, 100)
          INTO l_db_office_code
          FROM user_sequences
         WHERE sequence_name = 'CWMS_SEQ';

        RETURN l_db_office_code;
    END get_this_db_office_code;

    FUNCTION get_this_db_office_id
        RETURN VARCHAR2
    IS
        l_db_office_id     VARCHAR2 (16);
        l_db_office_code   NUMBER := get_this_db_office_code;
    BEGIN
        SELECT office_id
          INTO l_db_office_id
          FROM cwms_office
         WHERE office_code = l_db_office_code;

        RETURN l_db_office_id;
    END get_this_db_office_id;

    FUNCTION get_this_db_office_name
        RETURN VARCHAR2
    IS
        l_db_office_name   VARCHAR2 (80);
        l_db_office_code   NUMBER := get_this_db_office_code;
    BEGIN
        SELECT long_name
          INTO l_db_office_name
          FROM cwms_office
         WHERE office_code = l_db_office_code;

        RETURN l_db_office_name;
    END get_this_db_office_name;

    FUNCTION is_user_admin (P_USERNAME VARCHAR2, P_DB_OFFICE_ID VARCHAR2)
        RETURN BOOLEAN
    IS
        l_count   NUMBER;
    BEGIN
        SELECT COUNT (*)
          INTO l_count
          FROM "AT_SEC_USERS" atsu
         WHERE     atsu.db_office_code =
                   CWMS_UTIL.GET_DB_OFFICE_CODE (P_DB_OFFICE_ID)
               AND atsu.user_group_code IN
                       (user_group_code_dba_users,
                        user_group_code_user_admins)
               AND atsu.username = UPPER (p_username);

        IF l_count > 0
        THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    END is_user_admin;

    FUNCTION is_user_server_admin (P_USERNAME       VARCHAR2,
                                   P_DB_OFFICE_ID   VARCHAR2)
        RETURN BOOLEAN
    IS
        l_count   NUMBER;
    BEGIN
        SELECT COUNT (*)
          INTO l_count
          FROM "AT_SEC_USERS" atsu
         WHERE     atsu.db_office_code =
                   CWMS_UTIL.GET_DB_OFFICE_CODE (P_DB_OFFICE_ID)
               AND atsu.user_group_code IN
                       (user_group_code_dba_users,
                        user_group_code_user_admins)
               AND atsu.username = UPPER (p_username);

        IF l_count > 0
        THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    END is_user_server_admin;


    FUNCTION get_admin_cwms_permissions (p_user_name      IN VARCHAR2,
                                         p_db_office_id   IN VARCHAR2)
        RETURN VARCHAR2
    IS
        l_permissions   VARCHAR2 (128);
    BEGIN
        IF (IS_USER_SERVER_ADMIN (p_user_name, p_db_office_id))
        THEN
            l_permissions := 'serverAdmin-configure';
        ELSE
            l_permissions := 'serverAdmin-No Access';
        END IF;

        IF (IS_USER_ADMIN (p_user_name, p_db_office_id))
        THEN
            l_permissions := l_permissions || ',serverAdminUsers-configure,';
        ELSE
            l_permissions := l_permissions || ',serverAdminUsers-No Access,';
        END IF;

        RETURN l_permissions;
    END get_admin_cwms_permissions;

    PROCEDURE get_user_cwms_permissions (
        p_cwms_permissions      OUT SYS_REFCURSOR,
        p_db_office_id       IN     VARCHAR2,
        p_include_all        IN     BOOLEAN DEFAULT FALSE)
    AS
        l_db_office_id     VARCHAR2 (16)
                               := cwms_util.get_db_office_id (p_db_office_id);
        l_db_office_code   NUMBER
            := cwms_util.get_db_office_code (l_db_office_id);
        l_username         VARCHAR2 (31) := CWMS_UTIL.GET_USER_ID;
        l_is_locked        VARCHAR2 (1);
        l_query            VARCHAR2 (1256);
        l_count            NUMBER;
        l_include_all      BOOLEAN := P_INCLUDE_ALL;
    BEGIN
        SELECT COUNT (*)
          INTO l_count
          FROM at_sec_cwms_users
         WHERE userid = l_username;

        IF l_count = 0 OR l_db_office_id = 'UNK'
        THEN
            cwms_err.raise (
                'ERROR',
                   'No CWMS Permissions Set. Account '
                || l_username
                || ' has no CWMS Permissions set for db_office_id: '
                || l_db_office_id
                || '. Please see your CWMS Application Administrator.');
        END IF;

        IF is_user_cwms_locked (p_db_office_code => l_db_office_code)
        THEN
            cwms_err.raise (
                'ERROR',
                   'Account is Locked. Account '
                || l_username
                || ' is locked for db_office_id: '
                || l_db_office_id
                || '. Please see your CWMS Application Administrator.');
        END IF;

        IF P_INCLUDE_ALL AND NOT IS_USER_ADMIN
        THEN
            L_INCLUDE_ALL := FALSE;
        END IF;

        IF L_INCLUDE_ALL
        THEN
            OPEN p_cwms_permissions FOR
                SELECT    createdby
                       || '|'
                       || p.username
                       || '|x|'
                       || CWMS_SEC.GET_ADMIN_CWMS_PERMISSIONS (
                              p.username,
                              l_db_office_id)
                       || '|'
                       || CASE
                              WHEN fullname IS NULL OR LENGTH (fullname) = 0
                              THEN
                                  ' '
                              ELSE
                                  fullname
                          END
                       || '|'
                       || CASE WHEN u.edipi IS NULL THEN 0 ELSE u.edipi END
                  FROM at_sec_user_office p, at_sec_cwms_users u
                 WHERE     p.username = u.userid
                       AND p.db_office_code = l_db_office_code;
        ELSE
            OPEN p_cwms_permissions FOR
                SELECT    createdby
                       || '|'
                       || p.username
                       || '|x|'
                       || CWMS_SEC.GET_ADMIN_CWMS_PERMISSIONS (
                              p.username,
                              l_db_office_id)
                       || '|'
                       || CASE
                              WHEN fullname IS NULL OR LENGTH (fullname) = 0
                              THEN
                                  ' '
                              ELSE
                                  fullname
                          END
                       || '|'
                       || CASE WHEN u.edipi IS NULL THEN 0 ELSE u.edipi END
                  FROM at_sec_user_office p, at_sec_cwms_users u
                 WHERE     p.username = u.userid
                       AND p.db_office_code = l_db_office_code
                       AND p.username = l_username;
        END IF;
    END get_user_cwms_permissions;

    PROCEDURE get_db_users (p_db_users       OUT SYS_REFCURSOR,
                            p_db_office_id       VARCHAR2)
    IS
        l_upass_id   VARCHAR2 (32);
    BEGIN
        l_upass_id :=
            CWMS_PROPERTIES.GET_PROPERTY ('CWMSDB',
                                          'sec.upass.id',
                                          'UPASSADM',
                                          'CWMS');

        OPEN p_db_users FOR
            SELECT CASE
                       WHEN s.fullname IS NULL
                       THEN
                           a.username
                       ELSE
                              a.username
                           || '|'
                           || s.fullname
                           || '|'
                           || s.createdby
                   END    fullname
              FROM (  SELECT username
                        FROM all_users
                       WHERE     username NOT IN ('ANONYMOUS',
                                                  'APPQOSSYS',
                                                  'CCP',
                                                  'CWMS_20',
                                                  'CWMS_DBX',
                                                  'CWMS_DBA',
                                                  'CWMS_STR_ADM',
                                                  'CTXSYS',
                                                  'DBSNMP',
                                                  'DIP',
                                                  'EXFSYS',
                                                  'FLOWS_FILES',
                                                  'MDDATA',
                                                  'MDSYS',
                                                  'MGMT_VIEW',
                                                  'ORACLE_OCM',
                                                  'ORDDATA',
                                                  'ORDSYS',
                                                  'OUTLN',
                                                  'ORDPLUGINS',
                                                  'RDL',
                                                  'SI_INFORMTN_SCHEMA',
                                                  'SPATIAL_CSW_ADMIN_USR',
                                                  'SPATIAL_WFS_ADMIN_USR',
                                                  'SYS',
                                                  'SYSTEM',
                                                  'SYSMAN',
                                                  l_upass_id,
                                                  'WMSYS',
                                                  'XDB',
                                                  'XS$NULL')
                             AND username NOT LIKE '%DBI'
                             AND username NOT LIKE 'APEX_%'
                             AND username NOT IN
                                     (SELECT username
                                        FROM at_sec_user_office
                                       WHERE DB_OFFICE_CODE =
                                             cwms_util.get_db_office_code (
                                                 p_db_office_id))
                    ORDER BY username) a
                   LEFT JOIN at_sec_cwms_users s ON A.USERNAME = S.userid;
    END get_db_users;

    PROCEDURE set_pd_user_passwd (p_pd_password   IN VARCHAR2,
                                  p_pd_username   IN VARCHAR2)
    IS
    BEGIN
        NULL;
    END;

    PROCEDURE update_user_data (p_userid     IN VARCHAR2,
                                p_fullname   IN VARCHAR2,
                                p_org        IN VARCHAR2,
                                p_office     IN VARCHAR2,
                                p_phone      IN VARCHAR2,
                                p_email      IN VARCHAR2)
    IS
    BEGIN
        cwms_upass.update_user_data (p_userid,
                                     p_fullname,
                                     p_org,
                                     p_office,
                                     p_phone,
                                     p_email);
    END update_user_data;

    PROCEDURE confirm_cwms_schema_user
    IS
    BEGIN
        IF (cwms_util.get_user_id <> 'CWMS_20')
        THEN
            raise_application_error (-20999, 'Insufficient privileges', TRUE);
        END IF;
    END confirm_cwms_schema_user;


    PROCEDURE confirm_pd_or_schema_user (p_user VARCHAR2)
    IS
        l_db_office_code   NUMBER
            := cwms_util.get_db_office_code (get_user_office_id);
    BEGIN
        IF (    (is_member_user_group (user_group_code_pd_users,
                                       p_user,
                                       l_db_office_code) =
                 FALSE)
            AND (p_user <> 'CWMS_20'))
        THEN
            raise_application_error (-20999, 'Insufficient privileges', TRUE);
        END IF;
    END confirm_pd_or_schema_user;

    PROCEDURE confirm_pd_user (p_user VARCHAR2)
    IS
        l_db_office_code   NUMBER
            := cwms_util.get_db_office_code (get_user_office_id);
    BEGIN
        IF (is_member_user_group (user_group_code_pd_users,
                                  p_user,
                                  l_db_office_code) =
            FALSE)
        THEN
            raise_application_error (-20999, 'Insufficient privileges', TRUE);
        END IF;
    END confirm_pd_user;

    PROCEDURE update_service_timeout (p_username VARCHAR2)
    IS
    BEGIN
        UPDATE at_sec_service_user
           SET timeout = (SYSDATE + 1 / 24)
         WHERE userid = p_username AND timeout < (SYSDATE + 1 / 24);

        COMMIT;
    END update_service_timeout;

    PROCEDURE update_service_password (p_username VARCHAR2)
    IS
        l_password   VARCHAR2 (128);
        l_handle     VARCHAR2 (128);
        l_ret        INTEGER := -1;
        l_timeout    DATE := SYSDATE - 1;
    BEGIN
        confirm_cwms_schema_user;

        BEGIN
            SELECT TIMEOUT
              INTO l_timeout
              FROM AT_SEC_SERVICE_USER
             WHERE userid = p_username;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                NULL;
        END;

        CWMS_DBA.CWMS_USER_ADMIN.UNLOCK_DB_ACCOUNT (p_username);

        IF (SYSDATE > l_timeout)
        THEN
            l_password := generate_dod_password;
            DBMS_LOCK.ALLOCATE_UNIQUE (lockname     => 'AT_SEC_SERVICE_USER',
                                       lockhandle   => l_handle);

            IF (DBMS_LOCK.REQUEST (lockhandle => l_handle, timeout => 10) = 0)
            THEN
                CWMS_DBA.CWMS_USER_ADMIN.update_service_password (
                    p_username,
                    cwms_crypt.decrypt (l_password));

                MERGE INTO AT_SEC_SERVICE_USER d
                     USING (SELECT 1 FROM DUAL) s
                        ON (d.userid = p_username)
                WHEN MATCHED
                THEN
                    UPDATE SET
                        passwd = l_password, timeout = (SYSDATE + 1 / 2)
                WHEN NOT MATCHED
                THEN
                    INSERT     (userid, passwd, timeout)
                        VALUES (p_username, l_password, SYSDATE + 1 / 2);

                COMMIT;
                l_ret := DBMS_LOCK.RELEASE (l_handle);
            ELSE
                raise_application_error (
                    -20999,
                    'Error in updating service user credentials',
                    TRUE);
            END IF;
        END IF;
    END update_service_password;

    PROCEDURE get_service_credentials (p_username   OUT VARCHAR2,
                                       p_password   OUT VARCHAR2,
                                       p_duration   OUT VARCHAR2)
    IS
        l_handle     VARCHAR2 (128);
        l_ret        INTEGER := -1;
        l_username   VARCHAR2 (16) := cac_service_user;
    BEGIN
        get_service_credentials (p_username, p_password);

        SELECT cwms_util.minutes_to_duration (
                   TRUNC (TO_NUMBER (timeout - SYSDATE) * 24 * 60))
          INTO p_duration
          FROM AT_SEC_SERVICE_USER;
    END get_service_credentials;

    PROCEDURE get_service_credentials (p_username   OUT VARCHAR2,
                                       p_password   OUT VARCHAR2)
    IS
        l_handle     VARCHAR2 (128);
        l_ret        INTEGER := -1;
        l_username   VARCHAR2 (16) := cac_service_user;
    BEGIN
        confirm_pd_user (CWMS_UTIL.GET_USER_ID);

        DBMS_LOCK.ALLOCATE_UNIQUE (lockname     => 'AT_SEC_SERVICE_USER',
                                   lockhandle   => l_handle);

        IF (DBMS_LOCK.REQUEST (lockhandle => l_handle, timeout => 10) = 0)
        THEN
            BEGIN
                SELECT userid, cwms_crypt.decrypt (passwd)
                  INTO p_username, p_password
                  FROM at_sec_service_user
                 WHERE userid = l_username;

                update_service_timeout (l_username);
            EXCEPTION
                WHEN OTHERS
                THEN
                    NULL;
            END;

            l_ret := DBMS_LOCK.RELEASE (l_handle);
        ELSE
            raise_application_error (
                -20999,
                'Error in getting service user credentials',
                TRUE);
        END IF;
    END get_service_credentials;


    PROCEDURE clean_session_keys
    IS
    BEGIN
        DELETE FROM AT_SEC_SESSION
              WHERE SYSTIMESTAMP > TIMEOUT;

        COMMIT;
        update_service_password (cac_service_user);
    END clean_session_keys;

    PROCEDURE remove_session_key (p_session_key VARCHAR2)
    IS
    BEGIN
        confirm_pd_user (CWMS_UTIL.GET_USER_ID);

        DELETE FROM AT_SEC_SESSION
              WHERE SESSION_KEY = p_session_key;

        COMMIT;
    END remove_session_key;

    PROCEDURE get_user_credentials (p_edipi         IN     NUMBER,
                                    p_user             OUT VARCHAR2,
                                    p_session_key      OUT VARCHAR2)
    IS
        l_count   NUMBER;
    BEGIN
        p_user := NULL;
        p_session_key := NULL;
        confirm_pd_user (CWMS_UTIL.GET_USER_ID);

        BEGIN
            SELECT COUNT (*)
              INTO L_COUNT
              FROM AT_SEC_CWMS_USERS
             WHERE EDIPI = P_EDIPI;

            IF (L_COUNT = 1)
            THEN
                SELECT userid
                  INTO p_user
                  FROM AT_SEC_CWMS_USERS
                 WHERE edipi = p_edipi;

                p_session_key := RAWTOHEX (DBMS_CRYPTO.RANDOMBYTES (8));

                INSERT INTO at_sec_session
                     VALUES (p_user, p_session_key, SYSTIMESTAMP + 1);


                COMMIT;
            ELSIF (L_COUNT > 1)
            THEN
                raise_application_error (
                    -20255,
                       'The edipi '
                    || p_edipi
                    || ' is defined for more than one user, you must delete one of the user accounts.',
                    TRUE);
            END IF;
        END;
    END get_user_credentials;

    PROCEDURE create_session (p_session_key OUT VARCHAR2)
    IS
        l_user          VARCHAR (255);
        l_session_key   VARCHAR (255);
    BEGIN
        p_session_key := NULL;
        l_user := cwms_util.get_user_id;
        confirm_pd_user (l_user);

        BEGIN
            l_session_key := RAWTOHEX (DBMS_CRYPTO.RANDOMBYTES (8));

            INSERT INTO at_sec_session (userid, session_key, timeout)
                 VALUES (l_user, l_session_key, SYSTIMESTAMP + 1);

            p_session_key := l_session_key;
        END;
    END create_session;

    FUNCTION cat_invalid_login_tab (p_username   IN VARCHAR2,
                                    maxrows         NUMBER DEFAULT 3)
        RETURN cat_invalid_login_tab_t
        PIPELINED
    AS
        query_cursor   SYS_REFCURSOR;
        output_row     cat_invalid_login_rec_t;
    BEGIN
        confirm_user_admin_priv (cwms_util.get_db_office_code (NULL));

        OPEN query_cursor FOR
            SELECT *
              FROM (  SELECT userhost,
                             terminal,
                             REGEXP_SUBSTR (
                                 comment$text,
                                 '\d{2,3}\.\d{2,3}\.\d{2,3}\.\d{2,3}\')
                                 AS incoming_ip,
                             ntimestamp#
                                 AS login_time
                        FROM sys.aud$
                       WHERE returncode = 1017 AND userid = p_username
                    ORDER BY ntimestamp# DESC)
             WHERE ROWNUM <= maxrows;

        LOOP
            FETCH query_cursor INTO output_row;

            EXIT WHEN query_cursor%NOTFOUND;
            PIPE ROW (output_row);
        END LOOP;

        CLOSE query_cursor;

        RETURN;
    END cat_invalid_login_tab;

    FUNCTION cat_locked_users_tab
        RETURN cat_locked_users_tab_t
        PIPELINED
    AS
        query_cursor   SYS_REFCURSOR;
        output_row     cat_locked_users_rec_t;
    BEGIN
        confirm_user_admin_priv (cwms_util.get_db_office_code (NULL));

        OPEN query_cursor FOR
              SELECT username,
                     account_status,
                     lock_date,
                     expiry_date
                FROM dba_users
               WHERE     username IN (SELECT username FROM at_sec_users)
                     AND (   account_status LIKE '%LOCKED%'
                          OR account_status LIKE '%EXPIRED%')
            ORDER BY username;

        LOOP
            FETCH query_cursor INTO output_row;

            EXIT WHEN query_cursor%NOTFOUND;
            PIPE ROW (output_row);
        END LOOP;

        CLOSE query_cursor;

        RETURN;
    END cat_locked_users_tab;

    FUNCTION get_users_tab (p_db_office_id IN VARCHAR2 DEFAULT NULL)
        RETURN cat_user_tab_t
        PIPELINED
    AS
        query_cursor   SYS_REFCURSOR;
        output_row     cat_user_rec_t;
        office_code    NUMBER
                           := cwms_util.get_db_office_code (p_db_office_id);
    BEGIN
        confirm_user_admin_priv (office_code);

        OPEN query_cursor FOR
              SELECT userid,
                     fullname,
                     phone,
                     office,
                     org,
                     email,
                     is_locked,
                     edipi
                FROM cwms_20.at_sec_cwms_users users
                     JOIN cwms_20.at_sec_locked_users lcktable
                         ON UPPER (users.userid) = UPPER (lcktable.username)
               WHERE db_office_code = office_code
            ORDER BY userid;

        LOOP
            FETCH query_cursor INTO output_row;

            EXIT WHEN query_cursor%NOTFOUND;
            PIPE ROW (output_row);
        END LOOP;

        RETURN;
    END get_users_tab;
END cwms_sec;
/
show errors
