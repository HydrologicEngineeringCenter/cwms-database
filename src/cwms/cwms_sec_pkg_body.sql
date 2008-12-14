/* Formatted on 2008/10/23 08:18 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE BODY cwms_sec
AS
   PROCEDURE get_user_office_data (
      p_office_id          OUT   VARCHAR2,
      p_office_long_name   OUT   VARCHAR2
   )
   IS
   BEGIN
      cwms_util.get_user_office_data (p_office_id, p_office_long_name);
   END;

--------------------------------------------------------------------------------
--The get_user_priv_groups procedure returns a refcursor of:

   --        db_office_id   varchar2(16)
--        username       varchar2(31)
--        user_group_id  varchar2(32)

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
      p_priv_groups    OUT      sys_refcursor,
      p_username       IN       VARCHAR2 DEFAULT NULL,
      p_db_office_id   IN       VARCHAR2 DEFAULT NULL
   )
   IS
      l_user_id        VARCHAR2 (31)
                    := UPPER (NVL (TRIM (p_username), cwms_util.get_user_id));
      l_db_office_id   VARCHAR2 (16)
             := UPPER (NVL (TRIM (p_db_office_id), cwms_util.user_office_id));
   BEGIN
      IF l_db_office_id = 'ALL'
      THEN
         OPEN p_priv_groups FOR
            SELECT b.office_id db_office_id, a.user_id username,
                   c.user_group_id
              FROM at_sec_users a, cwms_office b, cwms_sec_user_groups c
             WHERE a.db_office_code = b.office_code
               AND a.user_group_code = c.user_group_code
               AND user_id = l_user_id;
      ELSE
         OPEN p_priv_groups FOR
            SELECT b.office_id db_office_id, a.user_id username,
                   c.user_group_id
              FROM at_sec_users a, cwms_office b, cwms_sec_user_groups c
             WHERE a.db_office_code = b.office_code
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
   BEGIN
      cwms_dba.cwms_user_admin.lock_db_account (p_username);
   END;

   PROCEDURE unlock_db_account (p_username IN VARCHAR2)
   IS
   BEGIN
      cwms_dba.cwms_user_admin.unlock_db_account (p_username);
   END;

   FUNCTION is_user_admin (p_db_office_code IN NUMBER)
      RETURN BOOLEAN
   IS
      l_count      INTEGER       := 0;
      l_username   VARCHAR2 (31) := cwms_util.get_user_id;
   BEGIN
      --
      -- Check if user's account is locked for the p_db_office_code
      -- portion of the database...
      --
      SELECT atslu.is_locked
        INTO l_count
        FROM at_sec_locked_users atslu
       WHERE atslu.db_office_code = p_db_office_code
         AND atslu.username = UPPER (l_username);

      IF l_count > 0
      THEN
         RETURN FALSE;
      END IF;

      l_count := 0;

      --
      -- Check if user's account has either "dba" or "CWMS User Admins"
      -- privileges.
      --
      SELECT COUNT (*)
        INTO l_count
        FROM at_sec_users atsu
       WHERE atsu.db_office_code = p_db_office_code
         AND atsu.user_group_code IN (0, 7)
         AND atsu.user_id = UPPER (l_username);

      IF l_count > 0
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END;

   PROCEDURE create_cwms_db_account (
      p_username       IN   VARCHAR2,
      p_db_office_id   IN   VARCHAR2
   )
   IS
      l_dbi_username     VARCHAR2 (31);
      l_db_office_code   NUMBER;
   BEGIN
      l_db_office_code := cwms_util.get_db_office_code (p_db_office_id);

      SELECT atsdu.dbi_username
        INTO l_dbi_username
        FROM at_sec_dbi_user atsdu
       WHERE atsdu.db_office_code = l_db_office_code;

      cwms_dba.cwms_user_admin.create_cwms_db_account (p_username,
                                                       l_dbi_username
                                                      );
   END;

   PROCEDURE delete_cwms_db_account (p_username IN VARCHAR2)
   IS
   BEGIN
      NULL;
   END;
END cwms_sec;
/

SHOW errors;