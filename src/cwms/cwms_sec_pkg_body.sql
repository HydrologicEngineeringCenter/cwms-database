/* Formatted on 5/28/2013 4:17:36 PM (QP5 v5.163.1008.3004) */
SET DEFINE ON
@@defines.sql
/* Formatted on 7/1/2013 1:09:40 PM (QP5 v5.163.1008.3004) */
CREATE OR REPLACE PACKAGE BODY cwms_sec
AS
   FUNCTION is_user_cwms_locked (p_db_office_code IN NUMBER)
      RETURN BOOLEAN
   IS
      l_is_locked   VARCHAR2 (1);
      l_username    VARCHAR2 (31) := cwms_util.get_user_id;
   BEGIN
      --
      -- &cwms_schema, system, sys are ok
      --
      IF l_username IN ('&cwms_schema', 'SYSTEM', 'SYS')
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
          WHERE atslu.db_office_code = p_db_office_code
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
   END;

   FUNCTION is_user_admin (p_db_office_code IN NUMBER)
      RETURN BOOLEAN
   IS
      l_count       INTEGER := 0;
      l_is_locked   VARCHAR2 (1);
      l_username    VARCHAR2 (31) := cwms_util.get_user_id;
   BEGIN
      --
      -- &cwms_schema, system, sys are ok
      --
      IF l_username IN ('&cwms_schema', 'SYSTEM', 'SYS')
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
       WHERE atsu.db_office_code = p_db_office_code
             AND atsu.user_group_code IN
                    (user_group_code_dba_users, user_group_code_user_admins)
             AND atsu.username = UPPER (l_username);

      IF l_count > 0
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END;

   FUNCTION is_user_admin (p_db_office_id IN VARCHAR2 DEFAULT NULL)
      RETURN BOOLEAN
   IS
      l_db_office_id     VARCHAR2 (16)
                            := cwms_util.get_db_office_id (p_db_office_id);
      l_db_office_code   NUMBER
                            := cwms_util.get_db_office_code (l_db_office_id);
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
            'Permission Denied. Your account needs "CWMS DBA" or "CWMS User Admin" privileges to use the cwms_sec package.');
      END IF;
   END;

   FUNCTION get_max_cwms_ts_group_code
      RETURN NUMBER
   AS
   BEGIN
      RETURN max_cwms_ts_group_code;
   END;

   FUNCTION find_lowest_code (p_list_of_codes   IN SYS_REFCURSOR,
                              p_lowest_code     IN NUMBER)
      RETURN NUMBER
   AS
      l_lowest_code   NUMBER;
      l_count         NUMBER;
      l_codes_array   number_tab_t;
   BEGIN
      NULL;

      FETCH p_list_of_codes
      BULK COLLECT INTO l_codes_array;

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

      SELECT MIN (COLUMN_VALUE) INTO l_lowest_code FROM TABLE (l_codes_array);

      IF l_lowest_code != p_lowest_code
      THEN
         RETURN p_lowest_code;
      END IF;

      --
      SELECT MIN (l_code)
        INTO l_lowest_code
        FROM (SELECT COLUMN_VALUE l_code,
                     LEAD (COLUMN_VALUE) OVER (ORDER BY COLUMN_VALUE)
                     - COLUMN_VALUE
                        dif_value
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
   END;

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
   END;

   PROCEDURE get_user_office_data (p_office_id          OUT VARCHAR2,
                                   p_office_long_name   OUT VARCHAR2)
   IS
   BEGIN
      cwms_util.get_user_office_data (p_office_id, p_office_long_name);
   END;

   PROCEDURE set_dbi_user (p_dbi_username   IN VARCHAR2,
                           p_db_office_id   IN VARCHAR2)
   AS
      l_dbi_username     VARCHAR2 (30) := UPPER (TRIM (p_dbi_username));
      l_db_office_id     VARCHAR2 (16)
                            := cwms_util.get_db_office_id (p_db_office_id);
      l_db_office_code   NUMBER
                            := cwms_util.get_db_office_code (l_db_office_id);
   BEGIN
      confirm_user_admin_priv (l_db_office_code);

      BEGIN
         INSERT INTO at_sec_dbi_user (db_office_code, dbi_username)
              VALUES (l_db_office_code, l_dbi_username);
      EXCEPTION
         WHEN DUP_VAL_ON_INDEX
         THEN
            cwms_err.raise (
               'ERROR',
                  l_dbi_username
               || ' is alrady a registered dbi username for the '
               || l_db_office_id
               || ' db_office_id.');
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

   FUNCTION get_assigned_priv_groups_tab (
      p_db_office_id IN VARCHAR2 DEFAULT NULL)
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
   END;

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
          WHERE username = cwms_util.get_user_id
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
                        WHERE username = cwms_util.get_user_id
                              AND user_group_code IN
                                     (user_group_code_dba_users,
                                      user_group_code_user_admins));
      ELSIF (l_retrieve_all_username AND NOT l_retrieve_all_offices)
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
             WHERE db_office_code = l_db_office_code
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
             WHERE username = l_username AND user_group_code != 10
                   AND db_office_code IN
                          (SELECT db_office_code
                             FROM at_sec_locked_users
                            WHERE username = cwms_util.get_user_id
                                  AND db_office_code IN
                                         (SELECT UNIQUE a.db_office_code
                                            FROM at_sec_users a --, at_sec_locked_users b
                                           WHERE a.username =
                                                    cwms_util.get_user_id
                                                 AND a.user_group_code IN
                                                        (user_group_code_dba_users,
                                                         user_group_code_user_admins))
                                  AND is_locked = 'F');
      END IF;
   END;

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
      l_user_group := get_user_group_code (p_user_group_id, p_db_office_code);

      IF l_user_group < 10
      THEN
         cwms_err.raise (
            'ERROR',
            'User Group: ' || p_user_group_id
            || ' is a primary privilege group, which cannot be paired with a TS Group.');
      ELSE
         RETURN l_user_group;
      END IF;
   END;

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
          WHERE UPPER (ts_group_id) = UPPER (TRIM (p_ts_group_id))
                AND db_office_code = p_db_office_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.raise (
               'ERROR',
               'The ' || p_ts_group_id || ' is not a valid TS Group.');
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
      l_db_office_code   NUMBER := cwms_util.get_db_office_code (NULL);
   BEGIN
      confirm_user_admin_priv (l_db_office_code);

      cwms_dba.cwms_user_admin.lock_db_account (p_username);
   END;

   PROCEDURE unlock_db_account (p_username IN VARCHAR2)
   IS
      l_db_office_code   NUMBER := cwms_util.get_db_office_code (NULL);
   BEGIN
      confirm_user_admin_priv (l_db_office_code);

      cwms_dba.cwms_user_admin.unlock_db_account (p_username);
   END;

   PROCEDURE create_cwms_db_account (
      p_username       IN VARCHAR2,
      p_password       IN VARCHAR2,
      p_db_office_id   IN VARCHAR2 DEFAULT NULL)
   IS
      l_username         VARCHAR2 (31) := UPPER (TRIM (p_username));
      l_password         VARCHAR2 (31) := TRIM (p_password);
      l_is_locked        VARCHAR2 (1);
      l_dbi_username     VARCHAR2 (31);
      l_db_office_id     VARCHAR2 (16)
                            := cwms_util.get_db_office_id (p_db_office_id);
      l_db_office_code   NUMBER
                            := cwms_util.get_db_office_code (l_db_office_id);
      l_count            NUMBER;
   --
   BEGIN
      confirm_user_admin_priv (l_db_office_code);

      BEGIN
         SELECT dbi_username
           INTO l_dbi_username
           FROM at_sec_dbi_user
          WHERE db_office_code = l_db_office_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.raise (
               'ERROR',
               'Unable to create user because a dbi_username was not found for this CWMS Oracle Database.');
      END;

      SELECT COUNT (*)
        INTO l_count
        FROM AT_SEC_CWMS_USERS
       WHERE userid = UPPER (p_username);

      IF (l_count = 0)
      THEN
         update_user_data (p_username,
                           NULL,
                           NULL,
                           NULL,
                           NULL,
                           NULL);
      END IF;

      cwms_dba.cwms_user_admin.create_cwms_db_account (l_username,
                                                       l_password,
                                                       l_dbi_username);

      BEGIN
         SELECT is_locked
           INTO l_is_locked
           FROM at_sec_locked_users
          WHERE db_office_code = l_db_office_code AND username = l_username;

         IF l_is_locked != 'F'
         THEN
            UPDATE at_sec_locked_users
               SET is_locked = 'F'
             WHERE db_office_code = l_db_office_code
                   AND username = l_username;
         END IF;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            INSERT
              INTO at_sec_locked_users (db_office_code, username, is_locked)
            VALUES (l_db_office_code, l_username, 'F');
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

      COMMIT;
   END;

   PROCEDURE delete_cwms_db_account (p_username IN VARCHAR2)
   IS
   BEGIN
      cwms_err.raise (
         'ERROR',
         'Unable to delete user DB account - see your DBA to delete a DB account.');
   END;

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


      l_username := UPPER (TRIM (p_username));
      cwms_dba.cwms_user_admin.unlock_db_account (l_username);

      SELECT COUNT (*)
        INTO l_count
        FROM at_sec_locked_users
       WHERE username = l_username AND db_office_code = l_db_office_code;

      IF l_count = 0
      THEN
         INSERT
           INTO at_sec_locked_users (db_office_code, username, is_locked)
         VALUES (l_db_office_code, l_username, 'F');
      ELSE
         UPDATE at_sec_locked_users
            SET is_locked = 'F'
          WHERE db_office_code = l_db_office_code AND username = l_username;
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
          WHERE UPPER (user_group_id) = UPPER (p_user_group_id)
                AND db_office_code = p_db_office_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.raise (
               'ERROR',
               'The ' || p_user_group_id || ' is not a valid user group.');
      END;

      RETURN l_user_group_code;
   END;

   PROCEDURE insert_noaccess_entry (p_username         IN VARCHAR2,
                                    p_db_office_code      NUMBER)
   IS
      l_cwms_permissions   VARCHAR2 (1024)
         := 'Watershed Configuration-No Access,Data Acquisition-No Access,Data Visualization-No Access,Model Interface-No Access,Res-No Access,FloodOpt-No Access,GridUtil-No Access,FIA-No Access,FDA-No Access,Hfp-No Access,Scripting-No Access';
      l_count              NUMBER;
   BEGIN
      SELECT COUNT (*)
        INTO L_count
        FROM AT_SEC_CWMS_PERMISSIONS
       WHERE USERNAME = p_username AND db_office_code = p_db_office_code;

      IF l_count = 0
      THEN
         INSERT
           INTO AT_SEC_CWMS_PERMISSIONS (USERNAME, PERMISSIONS, DB_OFFICE_CODE)
         VALUES (UPPER (p_username), l_cwms_permissions, p_db_office_code);

         COMMIT;
      END IF;
   END;

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
         INSERT INTO at_sec_users (db_office_code, user_group_code, username)
              VALUES (p_db_office_code, l_user_group_code, l_username);

         insert_noaccess_entry (p_username, p_db_office_code);
         COMMIT;
      EXCEPTION
         WHEN DUP_VAL_ON_INDEX
         THEN
            NULL;
      END;
   END;

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
   END;

   PROCEDURE create_cwmsdbi_db_user (
      p_dbi_username   IN VARCHAR2,
      p_dbi_password   IN VARCHAR2 DEFAULT NULL,
      p_db_office_id   IN VARCHAR2 DEFAULT NULL)
   AS
      l_db_office_id     VARCHAR2 (16)
                            := cwms_util.get_db_office_id (p_db_office_id);
      l_db_office_code   NUMBER
                            := cwms_util.get_db_office_code (l_db_office_id);
   BEGIN
      confirm_user_admin_priv (l_db_office_code);

      cwms_dba.cwms_user_admin.create_cwmsdbi_db_account (p_dbi_username,
                                                          p_dbi_password);

      set_dbi_user (p_dbi_username, p_db_office_id);
   END;

   PROCEDURE update_user_data (p_userid     IN VARCHAR2,
                               p_fullname   IN VARCHAR2,
                               p_org        IN VARCHAR2,
                               p_office     IN VARCHAR2,
                               p_phone      IN VARCHAR2,
                               p_email      IN VARCHAR2)
   IS
      l_count   NUMBER;
   BEGIN
      SELECT COUNT (*)
        INTO l_count
        FROM AT_SEC_CWMS_USERS
       WHERE USERID = p_userid;

      IF (l_count = 0)
      THEN
         INSERT INTO AT_SEC_CWMS_USERS (userid,
                                        fullname,
                                        org,
                                        phone,
                                        email,
                                        createdby)
              VALUES (p_userid,
                      p_fullname,
                      p_org,
                      p_phone,
                      p_email,
                      CWMS_UTIL.GET_USER_ID);
      ELSE
         UPDATE AT_SEC_CWMS_USERS
            SET fullname = p_fullname,
                org = p_org,
                phone = p_phone,
                email = p_email,
                createdby = CWMS_UTIL.GET_USER_ID
          WHERE userid = p_userid;
      END IF;
   END UPDATE_USER_DATA;

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

   PROCEDURE create_user (p_username             IN VARCHAR2,
                          p_password             IN VARCHAR2,
                          p_user_group_id_list   IN char_32_array_type,
                          p_db_office_id         IN VARCHAR2 DEFAULT NULL,
                          p_cwms_permissions     IN VARCHAR2 DEFAULT NULL)
   IS
      l_db_office_id       VARCHAR2 (16)
                              := cwms_util.get_db_office_id (p_db_office_id);
      l_db_office_code     NUMBER
                              := cwms_util.get_db_office_code (l_db_office_id);
      l_dbi_username       VARCHAR2 (31);
      l_username           VARCHAR2 (31) := UPPER (TRIM (p_username));
      l_user_group_code    NUMBER;
      l_count              NUMBER;
      l_cwms_permissions   VARCHAR2 (1024)
         := 'Watershed Configuration-No Access,Data Acquisition-No Access,Data Visualization-No Access,Model Interface-No Access,Res-No Access,FloodOpt-No Access,GridUtil-No Access,FIA-No Access,FDA-No Access,Hfp-No Access,Scripting-No Access';
   BEGIN
      confirm_user_admin_priv (l_db_office_code);

      IF (p_user_group_id_list IS NOT NULL)
      THEN
         IF p_user_group_id_list.COUNT > 0
         THEN
            FOR i IN p_user_group_id_list.FIRST .. p_user_group_id_list.LAST
            LOOP
               l_user_group_code :=
                  get_user_group_code (p_user_group_id_list (i),
                                       l_db_office_code);
            END LOOP;
         END IF;
      END IF;

      create_cwms_db_account (l_username, p_password, p_db_office_id);

      IF (p_user_group_id_list IS NOT NULL)
      THEN
         IF p_user_group_id_list.COUNT > 0
         THEN
            FOR i IN p_user_group_id_list.FIRST .. p_user_group_id_list.LAST
            LOOP
               add_user_to_group (l_username,
                                  p_user_group_id_list (i),
                                  l_db_office_code);
            END LOOP;
         END IF;
      END IF;

      IF (p_cwms_permissions IS NOT NULL)
      THEN
         INSERT
           INTO AT_SEC_CWMS_PERMISSIONS (USERNAME, PERMISSIONS, DB_OFFICE_CODE)
         VALUES (UPPER (p_username), p_cwms_permissions, l_db_office_code);
      ELSE
         insert_noaccess_entry (UPPER (p_username), l_db_office_code);
      END IF;

      SELECT COUNT (*)
        INTO l_count
        FROM AT_SEC_CWMS_USERS
       WHERE userid = UPPER (p_username);

      IF (l_count = 0)
      THEN
         update_user_data (p_username,
                           NULL,
                           NULL,
                           NULL,
                           NULL,
                           NULL);
      END IF;

      COMMIT;
   END CREATE_USER;

   PROCEDURE update_user_cwms_permissions (
      p_username           IN VARCHAR2,
      p_cwms_permissions   IN VARCHAR2,
      p_db_office_id       IN VARCHAR2 DEFAULT NULL)
   IS
      l_db_office_id     VARCHAR2 (16)
                            := cwms_util.get_db_office_id (p_db_office_id);
      l_db_office_code   NUMBER
                            := cwms_util.get_db_office_code (l_db_office_id);
   BEGIN
      UPDATE AT_SEC_CWMS_PERMISSIONS
         SET PERMISSIONS = p_cwms_permissions,
             DB_OFFICE_CODE = l_db_office_code
       WHERE username = p_username AND DB_OFFICE_CODE = l_db_office_code;

      COMMIT;
   END update_user_cwms_permissions;

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
   /*

   */

   PROCEDURE delete_user (p_username IN VARCHAR2)
   IS
      l_username   VARCHAR2 (31);
      l_count      NUMBER := 0;
   BEGIN
      SELECT COUNT (UNIQUE db_office_code)
        INTO l_count
        FROM at_sec_users
       WHERE username = cwms_util.get_user_id
             AND user_group_code IN
                    (user_group_code_dba_users, user_group_code_user_admins);


      IF l_count > 0
      THEN
         l_username := UPPER (TRIM (p_username));

         DELETE FROM at_sec_users
               WHERE username = l_username
                     AND db_office_code IN
                            (SELECT UNIQUE db_office_code
                               FROM at_sec_users
                              WHERE username = cwms_util.get_user_id
                                    AND user_group_code IN
                                           (user_group_code_dba_users,
                                            user_group_code_user_admins));

         DELETE FROM at_sec_locked_users
               WHERE username = l_username
                     AND db_office_code IN
                            (SELECT UNIQUE db_office_code
                               FROM at_sec_users
                              WHERE username = cwms_util.get_user_id
                                    AND user_group_code IN
                                           (user_group_code_dba_users,
                                            user_group_code_user_admins));

         DELETE FROM at_sec_cwms_permissions
               WHERE username = l_username;

         --DELETE FROM at_sec_cwms_users
         --WHERE userid = l_username;


         COMMIT;
      END IF;
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
          WHERE username = l_username AND db_office_code = l_db_office_code;
      END IF;
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

      DELETE FROM at_sec_users
            WHERE     db_office_code = l_db_office_code
                  AND user_group_code = l_user_group_code
                  AND username = UPPER (p_username);

      COMMIT;
   END;

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
         SELECT account_status
           INTO l_account_status
           FROM dba_users
          WHERE username = l_username;
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
            SELECT is_locked
              INTO l_is_locked
              FROM at_sec_locked_users
             WHERE username = l_username
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

   PROCEDURE set_dbi_user_passwd (p_dbi_password   IN VARCHAR2,
                                  p_dbi_username   IN VARCHAR2 DEFAULT NULL,
                                  p_db_office_id   IN VARCHAR2 DEFAULT NULL)
   AS
      l_db_office_id     VARCHAR2 (16)
                            := cwms_util.get_db_office_id (p_db_office_id);
      l_db_office_code   NUMBER
                            := cwms_util.get_db_office_code (l_db_office_id);

      l_dbi_username     VARCHAR2 (31);
   BEGIN
      confirm_user_admin_priv (l_db_office_code);


      -- Confirm that the p_dbi_username is the valid dbi username for the db_office_id
      IF p_dbi_username IS NULL
      THEN
         BEGIN
            SELECT dbi_username
              INTO l_dbi_username
              FROM at_sec_dbi_user
             WHERE db_office_code = l_db_office_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               cwms_err.raise (
                  'ERROR',
                  'Sorry, unable to set the DBI User Password because the '
                  || l_db_office_id
                  || ' database does not have a DBI User set.');
            WHEN TOO_MANY_ROWS
            THEN
               cwms_err.raise (
                  'ERROR',
                  'Sorry, unable to set the DBI User Password because there are more than one set DBI Users set for the '
                  || l_db_office_id
                  || ' database. Please specify which DBI User''''s password you wish to reset.');
         END;
      ELSE
         BEGIN
            SELECT dbi_username
              INTO l_dbi_username
              FROM at_sec_dbi_user
             WHERE dbi_username = UPPER (p_dbi_username)
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
                  || ' database.');
         END;
      END IF;

      -- l_dbi_username should now have a valid username - so reset it's password...

      cwms_dba.cwms_user_admin.set_user_password (l_dbi_username,
                                                  p_dbi_password);
   END;



   PROCEDURE assign_ts_group_user_group (
      p_ts_group_id     IN VARCHAR2,
      p_user_group_id   IN VARCHAR2,
      p_privilege       IN VARCHAR2,                    -- none, read or write
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
            'Unrecognized p_privilege: ' || p_privilege
            || ' "None", "Read" or "Read-Write" are the only valid privileges.');
      END IF;

      l_user_group_code :=
         get_ts_user_group_code (p_user_group_id, l_db_office_code);

      l_ts_group_code := get_ts_group_code (p_ts_group_id, l_db_office_code);

      -- Determine if read/write priv's are already set for this group pair..

      SELECT SUM (privilege_bit)
        INTO l_sum_priv_bit
        FROM at_sec_allow
       WHERE     db_office_code = l_db_office_code
             AND ts_group_code = l_ts_group_code
             AND user_group_code = l_user_group_code;

      IF l_sum_priv_bit IS NOT NULL
      THEN
         DELETE FROM at_sec_allow
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
   END;

   PROCEDURE cat_at_sec_allow (p_at_sec_allow      OUT SYS_REFCURSOR,
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
                          NULL)
                     priv
             FROM (  SELECT db_office_code,
                            user_group_code,
                            ts_group_code,
                            db_office_id,
                            user_group_id,
                            ts_group_id,
                            SUM (b.privilege_bit) priv_sum
                       FROM    (SELECT a.db_office_code,
                                       a.user_group_code,
                                       c.ts_group_code,
                                       b.office_id db_office_id,
                                       a.user_group_id,
                                       c.ts_group_id
                                  FROM at_sec_user_groups a,
                                       cwms_office b,
                                       at_sec_ts_groups c
                                 WHERE     a.db_office_code = b.office_code
                                       AND a.db_office_code = l_db_office_code
                                       AND c.db_office_code = l_db_office_code
                                       AND a.user_group_code >
                                              max_cwms_priv_ugroup_code) a
                            LEFT OUTER JOIN
                               at_sec_allow b
                            USING (db_office_code, user_group_code, ts_group_code)
                   GROUP BY db_office_code,
                            user_group_code,
                            ts_group_code,
                            db_office_id,
                            user_group_id,
                            ts_group_id) a
         ORDER BY user_group_id, ts_group_id;
   END;

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
   END;


   PROCEDURE refresh_mv_sec_ts_privileges
   AS
      l_status   VARCHAR2 (30);
   BEGIN
      SELECT status
        INTO l_status
        FROM dba_objects
       WHERE object_name = 'MV_SEC_TS_PRIVILEGES'
             AND object_type = 'MATERIALIZED VIEW';


      IF l_status != 'VALID'
      THEN
         EXECUTE IMMEDIATE
            'alter materialized view MV_SEC_TS_PRIVILEGES compile';


         DBMS_SNAPSHOT.refresh (
            list                   => '&cwms_schema' || '.MV_SEC_TS_PRIVILEGES',
            push_deferred_rpc      => TRUE,
            refresh_after_errors   => FALSE,
            purge_option           => 1,
            parallelism            => 0,
            atomic_refresh         => TRUE,
            nested                 => FALSE);
      END IF;
   END;

   PROCEDURE start_refresh_mv_sec_privs_job
   IS
      l_count          BINARY_INTEGER;
      l_user_id        VARCHAR2 (30);
      l_job_id         VARCHAR2 (30) := 'REFRESH_MV_SEC_TS_PRIVS_JOB';
      l_run_interval   VARCHAR2 (8) := '5';
      l_comment        VARCHAR2 (256);

      FUNCTION job_count
         RETURN BINARY_INTEGER
      IS
      BEGIN
         SELECT COUNT (*)
           INTO l_count
           FROM sys.dba_scheduler_jobs
          WHERE job_name = l_job_id AND owner = l_user_id;

         RETURN l_count;
      END;
   BEGIN
      --------------------------------------
      -- make sure we're the correct user --
      --------------------------------------
      l_user_id := cwms_util.get_user_id;

      IF l_user_id != '&cwms_schema'
      THEN
         raise_application_error (
            -20999,
            'Must be &cwms_schema user to start job ' || l_job_id,
            TRUE);
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
               job_name          => l_job_id,
               job_type          => 'stored_procedure',
               job_action        => 'cwms_sec.refresh_mv_sec_ts_privileges',
               start_date        => NULL,
               repeat_interval   => 'freq=minutely; interval='
                                   || l_run_interval,
               end_date          => NULL,
               job_class         => 'default_job_class',
               enabled           => TRUE,
               auto_drop         => FALSE,
               comments          => 'Refreshes mv_sec_ts_privileges when needed.');

            IF job_count = 1
            THEN
               DBMS_OUTPUT.put_line (
                     'Job '
                  || l_job_id
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
                               l_job_id || ':' || SQLERRM);
         END;
      END IF;
   END start_refresh_mv_sec_privs_job;

   /*
   storePrivilegeGroups(String username, String officeId,
       List<String> groupNameList, List<String> groupOfficeIdList,
       List<Boolean> groupAssignedList)
   */

   PROCEDURE store_priv_groups (p_username             IN VARCHAR2,
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

            IF l_is_member_list (i) = 'F'
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
   END;

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
       WHERE user_group_code = l_user_group_code
             AND db_office_code = l_db_office_code;

      COMMIT;
   END;

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
       WHERE user_group_code = l_user_group_code
             AND db_office_code = l_db_office_code;

      COMMIT;
   END;


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
            RETURN;                   -- silent when user_group does not exist
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
      DELETE FROM at_sec_allow
            WHERE user_group_code = l_user_group_code
                  AND db_office_code = l_db_office_code;

      --
      -- delete all at_sec_users entries with this user_code...
      --
      DELETE FROM at_sec_users
            WHERE user_group_code = l_user_group_code
                  AND db_office_code = l_db_office_code;

      --
      -- finally delete the user_group from at_sec_user_groups...
      --
      DELETE FROM at_sec_user_groups
            WHERE user_group_code = l_user_group_code
                  AND db_office_code = l_db_office_code;

      --
      COMMIT;
   --
   END;


   PROCEDURE create_user_group (p_user_group_id     IN VARCHAR2,
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
                AND user_group_code > max_cwms_ts_ugroup_code
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
          WHERE db_office_code = l_db_office_code
                AND user_group_code > max_cwms_ts_ugroup_code;

      --
      l_lowest_code :=
         find_lowest_code (l_user_group_codes, max_cwms_ts_ugroup_code + 1);

      --
      INSERT INTO at_sec_user_groups (db_office_code,
                                      user_group_code,
                                      user_group_id,
                                      user_group_desc)
           VALUES (l_db_office_code,
                   l_lowest_code,
                   l_user_group_id,
                   TRIM (p_user_group_desc));
   END;


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
            RETURN;                   -- silent when user_group does not exist
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
      DELETE FROM at_sec_allow
            WHERE ts_group_code = l_ts_group_code
                  AND db_office_code = l_db_office_code;

      --
      -- delete all at_sec_users entries with this user_code...
      --
      DELETE FROM at_sec_ts_group_masks
            WHERE ts_group_code = l_ts_group_code
                  AND db_office_code = l_db_office_code;

      --
      -- finally delete the user_group from at_sec_user_groups...
      --
      DELETE FROM at_sec_ts_groups
            WHERE ts_group_code = l_ts_group_code
                  AND db_office_code = l_db_office_code;

      --
      COMMIT;
   --
   END;

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
       WHERE ts_group_code = l_ts_group_code
             AND db_office_code = l_db_office_code;

      COMMIT;
   END;

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
       WHERE ts_group_code = l_ts_group_code
             AND db_office_code = l_db_office_code;

      COMMIT;
   END;

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
          WHERE db_office_code = l_db_office_code
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
   END;


   PROCEDURE assign_ts_masks_to_ts_group (
      p_ts_group_id       IN VARCHAR2,
      p_ts_mask_list      IN char_183_array_type,
      p_add_remove_list   IN char_16_array_type,
      p_db_office_id      IN VARCHAR2 DEFAULT NULL)
   AS
      l_db_office_code   NUMBER
                            := cwms_util.get_db_office_code (p_db_office_id);
      l_ts_group_code    NUMBER;
      l_count            NUMBER;
      l_ts_mask          VARCHAR2 (183);
   BEGIN
      confirm_user_admin_priv (l_db_office_code);
      --
      l_ts_group_code := get_ts_group_code (p_ts_group_id, l_db_office_code);

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
            cwms_err.raise ('ERROR', 'The p_ts_mask_list has not records.');
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
            cwms_util.normalize_wildcards (UPPER (TRIM (p_ts_mask_list (i))));

         IF UPPER (TRIM (p_add_remove_list (i))) = 'ADD'
         THEN
            BEGIN
               INSERT
                 INTO at_sec_ts_group_masks (db_office_code,
                                             ts_group_code,
                                             ts_group_mask)
               VALUES (l_db_office_code, l_ts_group_code, l_ts_mask);
            EXCEPTION
               WHEN DUP_VAL_ON_INDEX
               THEN
                  NULL;
            END;
         ELSE
            DELETE FROM at_sec_ts_group_masks
                  WHERE db_office_code = l_db_office_code
                        AND UPPER (ts_group_mask) = l_ts_mask;
         END IF;

         COMMIT;
      END LOOP;
   END;

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
      l_ts_group_code := get_ts_group_code (p_ts_group_id, l_db_office_code);

      IF l_ts_group_code <= max_cwms_ts_group_code
      THEN
         cwms_err.raise (
            'ERROR',
               'Cannot clear TS Masks from the '
            || TRIM (p_ts_group_id)
            || ' TS Group because it is owned by the system.');
      END IF;

      DELETE FROM at_sec_ts_group_masks
            WHERE ts_group_code = l_ts_group_code
                  AND db_office_code = l_db_office_code;

      COMMIT;
   END;

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
   END;

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
   END;

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
   END;

   FUNCTION is_user_admin (P_USERNAME VARCHAR2, P_DB_OFFICE_ID VARCHAR2)
      RETURN BOOLEAN
   IS
      l_count   NUMBER;
   BEGIN
      SELECT COUNT (*)
        INTO l_count
        FROM "AT_SEC_USERS" atsu
       WHERE atsu.db_office_code =
                CWMS_UTIL.GET_DB_OFFICE_CODE (P_DB_OFFICE_ID)
             AND atsu.user_group_code IN
                    (user_group_code_dba_users, user_group_code_user_admins)
             AND atsu.username = UPPER (p_username);

      IF l_count > 0
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END;

   FUNCTION is_user_server_admin (P_USERNAME        VARCHAR2,
                                  P_DB_OFFICE_ID    VARCHAR2)
      RETURN BOOLEAN
   IS
      l_count   NUMBER;
   BEGIN
      SELECT COUNT (*)
        INTO l_count
        FROM "AT_SEC_USERS" atsu
       WHERE atsu.db_office_code =
                CWMS_UTIL.GET_DB_OFFICE_CODE (P_DB_OFFICE_ID)
             AND atsu.user_group_code IN
                    (user_group_code_dba_users, user_group_code_user_admins)
             AND atsu.username = UPPER (p_username);

      IF l_count > 0
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END;

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
   END;

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

      l_query :=
         'SELECT    createdby || ''|'' ||  p.username
             || ''|x|''
             || CWMS_SEC.GET_ADMIN_CWMS_PERMISSIONS (p.username,'''
         || p_db_office_id
         || ''')
             || permissions
             || ''|''
             ||  case when fullname is null or length(fullname)=0 then '' '' else fullname end
        FROM at_sec_cwms_permissions p, at_sec_cwms_users u  WHERE p.username=u.userid AND p.db_office_code='
         || l_db_office_code;

      IF NOT L_INCLUDE_ALL
      THEN
         l_query := l_query || ' AND p.username = ''' || l_username || '''';
      END IF;

      DBMS_OUTPUT.PUT_LINE (l_query);

      OPEN p_cwms_permissions FOR l_query;
   END get_user_cwms_permissions;

   PROCEDURE get_db_users (p_db_users       OUT SYS_REFCURSOR,
                           p_db_office_id       VARCHAR2)
   IS
   BEGIN
      OPEN p_db_users FOR
         SELECT CASE
                   WHEN s.fullname IS NULL THEN a.username
                   ELSE a.username || '|' || s.fullname || '|' || s.createdby
                END
                   fullname
           FROM    (  SELECT username
                        FROM all_users
                       WHERE username NOT IN
                                ('ANONYMOUS',
                                 'APPQOSSYS',
                                 '&cwms_schema',
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
                                 'SI_INFORMTN_SCHEMA',
                                 'SPATIAL_CSW_ADMIN_USR',
                                 'SPATIAL_WFS_ADMIN_USR',
                                 'SYS',
                                 'SYSTEM',
                                 'SYSMAN',
                                 'UPASSADM',
                                 'WMSYS',
                                 'XDB',
                                 'XS$NULL')
                             AND username NOT LIKE '%DBI'
                             AND username NOT LIKE 'APEX_%'
                             AND username NOT IN
                                    (SELECT username
                                       FROM AT_SEC_CWMS_PERMISSIONS
                                      WHERE DB_OFFICE_CODE =
                                               cwms_util.get_db_office_code (
                                                  p_db_office_id))
                    ORDER BY username) a
                LEFT JOIN
                   at_sec_cwms_users s
                ON A.USERNAME = S.userid;
   END get_db_users;
END cwms_sec;
/
