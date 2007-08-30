/* Formatted on 2007/08/30 15:38 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE BODY cwms_sec
AS
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
END cwms_sec;
/