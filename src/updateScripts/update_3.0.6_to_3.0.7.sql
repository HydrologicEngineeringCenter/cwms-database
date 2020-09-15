
define cwms_schema = CWMS_20
set define on
set verify off

spool update_3.0.6_to_3.0.7.log; 
set define on
select systimestamp from dual;
----------------------------------------------------------
-- verify that the schema is the version that we expect --
----------------------------------------------------------
begin
   for rec in
      (select version,
              to_char(version_date, 'DDMONYYYY') as version_date
         from cwms_20.av_db_change_log
        where version_date = (select max(version_date) from cwms_20.av_db_change_log)
      )
   loop
      if rec.version != '3.0.6' then
        cwms_err.raise('ERROR', 'Expected version 3.0.6 (10MAR2017), got version '||rec.version||' ('||rec.version_date||')');
      end if;
   end loop;
end;
/

define cwms_schema = CWMS_20
whenever sqlerror continue 
CREATE TABLE AT_SEC_SESSION
(
  USERID         VARCHAR2(32 BYTE),
  SESSION_KEY    VARCHAR2(128 BYTE),
  TIMEOUT        TIMESTAMP(6)
)
TABLESPACE CWMS_20DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MAXSIZE          UNLIMITED
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
MONITORING;
CREATE TABLE AT_SEC_SERVICE_USER
(
  USERID   VARCHAR2(32 BYTE) PRIMARY KEY,
  PASSWD   VARCHAR2(128 BYTE),
  TIMEOUT  DATE
)
TABLESPACE CWMS_20DATA
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
           )
LOGGING
NOCOMPRESS
NOCACHE
MONITORING;
prompt update for package spec cwms_env
create or replace package cwms_env
AS
/**
 * Routines that manage the cwms environmen variables.
 *
 * @author Various
 *
 * @since CWMS 2.2
 */


   PROCEDURE set_session_office_id (p_office_id IN VARCHAR2);
   PROCEDURE set_session_privileges;
   PROCEDURE set_session_user(p_session_key VARCHAR2);
   PROCEDURE clear_session_privileges;
END cwms_env;
/

SHOW error;

set define on
define cwms_schema = CWMS_20
prompt update for package body cwms_env
create or replace package BODY cwms_env
AS

  PROCEDURE set_cwms_env (p_attribute IN VARCHAR2,p_value IN VARCHAR2)
  IS
   l_namespace   VARCHAR2 (30) := 'CWMS_ENV';
   l_attribute   VARCHAR2 (30) := NULL;
   l_value       VARCHAR2 (4000) := NULL;
  BEGIN
   l_attribute := p_attribute;
   l_value := p_value;

   DBMS_SESSION.set_context (l_namespace, l_attribute, l_value);

   END set_cwms_env;


   PROCEDURE set_session_office_id (p_office_id IN VARCHAR2)
   IS
      l_attribute   VARCHAR2 (30) := 'SESSION_OFFICE_ID';
      l_office_id   VARCHAR2 (16);
      --
      l_cnt         NUMBER;
      l_username    VARCHAR2 (31);
   BEGIN
      BEGIN
         l_office_id := CWMS_UTIL.GET_DB_OFFICE_ID (p_office_id);
      EXCEPTION
         WHEN OTHERS
         THEN
            cwms_err.raise (
               'ERROR',
                  'Unable to set a default SESSION_OFFICE_ID. The user: '
               || l_username
               || ' either has no assigned CWMS database privileges or has privileges to more than one office. Please see your CWMS Application Admin.');
      END;

      --
      -- Check if l_office_id is a valid office_id for this user, i.e.,
      -- does this user have any privileges assigned for the requested
      -- l_office_id.
      --
      SELECT COUNT (*)
        INTO l_cnt
        FROM TABLE (cwms_sec.get_assigned_priv_groups_tab)
       WHERE db_office_id = l_office_id;

      IF l_cnt > 0
      THEN
         SET_CWMS_ENV (l_attribute, l_office_id);
         SET_SESSION_PRIVILEGES; 
      ELSE
         l_username := cwms_util.get_user_id;
         cwms_err.raise (
            'ERROR',
               'Unable to set SESSION_OFFICE_ID to: '
            || l_office_id
            || ' because user: '
            || l_username
            || ' does not have any assigned privileges for that office.');
      END IF;
   END set_session_office_id;

   PROCEDURE clear_session_privileges
   IS
   BEGIN
    set_cwms_env ('CWMS_PRIVILEGE', 'READ_ONLY');
   END;

   PROCEDURE set_session_user(p_session_key VARCHAR2)
   IS
    l_userid VARCHAR2(32);
   BEGIN
    SELECT USERID
    INTO l_userid
    FROM AT_SEC_SESSION
    WHERE session_key = p_session_key;
    set_cwms_env('CWMS_USER',l_userid);
    set_session_privileges;
   END set_session_user;

   PROCEDURE set_session_privileges
   IS
      l_office_id   VARCHAR2 (16);
      l_username    VARCHAR2 (32);
      l_canwrite    BOOLEAN;
      l_cnt         NUMBER;
   BEGIN
      l_canwrite := FALSE;
      l_cnt := 0;
      l_username := CWMS_UTIL.GET_USER_ID;
      set_cwms_env ('CWMS_PRIVILEGE', 'READ_ONLY'); 


      SELECT SYS_CONTEXT ('CWMS_ENV', 'SESSION_OFFICE_ID')
        INTO l_office_id
        FROM DUAL;

      IF l_office_id IS NULL
      THEN
         BEGIN
            SELECT a.office_id
              INTO l_office_id
              FROM cwms_office a, at_sec_user_office b
             WHERE     b.username = l_username
                   AND a.office_code = b.db_office_code;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      SELECT COUNT (*)
        INTO l_cnt
        FROM TABLE (cwms_sec.get_assigned_priv_groups_tab)
       WHERE     db_office_id = l_office_id
             AND user_group_id IN ('CCP Mgr',
                                   'CCP Proc',
                                   'CWMS DBA Users',
                                   'CWMS PD Users',
                                   'CWMS User Admins',
                                   'Data Acquisition Mgr',
                                   'Data Exchange Mgr',
                                   'TS ID Creator',
                                   'VT Mgr');

      IF(l_cnt > 0)
      THEN
         l_canwrite := TRUE;
      END IF;

      IF (l_canwrite)
      THEN
         set_cwms_env ('CWMS_PRIVILEGE', 'CAN_WRITE');
      END IF;
   END set_session_privileges;
END cwms_env;
/

set define on
define cwms_schema = CWMS_20
prompt update for package spec cwms_sec
/* Formatted on 5/28/2013 1:59:38 PM (QP5 v5.163.1008.3004) */
SET DEFINE ON
create or replace package cwms_sec
AS
   max_cwms_priv_ugroup_code     CONSTANT NUMBER := 9;
   max_cwms_ts_ugroup_code       CONSTANT NUMBER := 19;
   max_cwms_ts_group_code        CONSTANT NUMBER := 9;
   --
   user_group_code_all_users     CONSTANT NUMBER := 10;
   user_group_code_dba_users     CONSTANT NUMBER := 0;
   user_group_code_user_admins   CONSTANT NUMBER := 7;
   user_group_code_pd_users      CONSTANT NUMBER:= 1;
   --
   acc_state_locked              CONSTANT VARCHAR2 (16) := 'LOCKED';
   acc_state_unlocked            CONSTANT VARCHAR2 (16) := 'UNLOCKED';
   acc_state_no_account          CONSTANT VARCHAR2 (16) := 'NO ACCOUNT';
   cac_service_user             CONSTANT VARCHAR2(8) := 'CWMS9999';

   TYPE cat_at_sec_allow_rec_t IS RECORD
   (
      db_office_code    NUMBER,
      user_group_code   NUMBER,
      ts_group_code     NUMBER,
      db_office_id      VARCHAR2 (16),
      user_group_id     VARCHAR2 (32),
      ts_group_id       VARCHAR2 (32),
      priv_sum          NUMBER,
      priv              VARCHAR2 (15)
   );

   TYPE cat_at_sec_allow_tab_t IS TABLE OF cat_at_sec_allow_rec_t;

   TYPE cat_priv_groups_rec_t IS RECORD
   (
      username            VARCHAR2 (31),
      db_office_id        VARCHAR2 (16),
      user_group_type     VARCHAR2 (24),
      user_group_owner    VARCHAR2 (16),
      user_group_id       VARCHAR2 (32),
      is_member           VARCHAR2 (1),
      user_group_desc     VARCHAR2 (256)
   );

   TYPE cat_priv_groups_tab_t IS TABLE OF cat_priv_groups_rec_t;

   FUNCTION get_this_db_office_code
      RETURN NUMBER;

   FUNCTION get_this_db_office_id
      RETURN VARCHAR2;

   FUNCTION get_this_db_office_name
      RETURN VARCHAR2;


   FUNCTION get_max_cwms_ts_group_code
      RETURN NUMBER;

   FUNCTION is_user_admin (p_db_office_id IN VARCHAR2 DEFAULT NULL)
      RETURN BOOLEAN;

   FUNCTION is_member_user_group (p_user_group_code   IN NUMBER,
                                  p_username          IN VARCHAR2,
                                  p_db_office_code    IN NUMBER)
      RETURN BOOLEAN;


   PROCEDURE set_user_office_id (p_username                  IN VARCHAR2,
                                 p_db_office_id   IN VARCHAR2);

   PROCEDURE assign_ts_group_user_group (
      p_ts_group_id     IN VARCHAR2,
      p_user_group_id   IN VARCHAR2,
      p_privilege       IN VARCHAR2,                    -- none, read or write
      p_db_office_id    IN VARCHAR2 DEFAULT NULL);

   PROCEDURE lock_db_account (p_username IN VARCHAR2);

   PROCEDURE unlock_db_account (p_username IN VARCHAR2);

   PROCEDURE create_cwms_db_account (
      p_username       IN VARCHAR2,
      p_password       IN VARCHAR2,
      p_db_office_id   IN VARCHAR2 DEFAULT NULL);

   PROCEDURE create_cwmsdbi_db_user (
      p_dbi_username   IN VARCHAR2,
      p_dbi_password   IN VARCHAR2 DEFAULT NULL,
      p_db_office_id   IN VARCHAR2 DEFAULT NULL);

   PROCEDURE set_dbi_user_passwd (p_dbi_password   IN VARCHAR2,
                                  p_dbi_username   IN VARCHAR2 DEFAULT NULL,
                                  p_db_office_id   IN VARCHAR2 DEFAULT NULL);

   PROCEDURE delete_cwms_db_account (p_username IN VARCHAR2);

   PROCEDURE get_assigned_priv_groups (
      p_priv_groups       OUT SYS_REFCURSOR,
      p_db_office_id   IN     VARCHAR2 DEFAULT NULL);

   FUNCTION get_assigned_priv_groups_tab (
      p_db_office_id IN VARCHAR2 DEFAULT NULL)
      RETURN cat_priv_groups_tab_t
      PIPELINED;

   PROCEDURE get_user_priv_groups (
      p_priv_groups       OUT SYS_REFCURSOR,
      p_username       IN     VARCHAR2 DEFAULT NULL,
      p_db_office_id   IN     VARCHAR2 DEFAULT NULL);

   FUNCTION get_user_priv_groups_tab (
      p_username       IN VARCHAR2 DEFAULT NULL,
      p_db_office_id   IN VARCHAR2 DEFAULT NULL)
      RETURN cat_priv_groups_tab_t
      PIPELINED;

   PROCEDURE get_user_office_data (p_office_id          OUT VARCHAR2,
                                   p_office_long_name   OUT VARCHAR2);

   FUNCTION get_user_office_id
      RETURN VARCHAR2;

   PROCEDURE unlock_user (p_username       IN VARCHAR2,
                          p_db_office_id   IN VARCHAR2 DEFAULT NULL);

   FUNCTION get_user_group_code (p_user_group_id    IN VARCHAR2,
                                 p_db_office_code   IN NUMBER)
      RETURN NUMBER;

   PROCEDURE add_user_to_group (p_username         IN VARCHAR2,
                                p_user_group_id    IN VARCHAR2,
                                p_db_office_code   IN NUMBER);

   PROCEDURE add_user_to_group (p_username        IN VARCHAR2,
                                p_user_group_id   IN VARCHAR2,
                                p_db_office_id    IN VARCHAR2 DEFAULT NULL);

   PROCEDURE create_logon_trigger (p_username IN VARCHAR2);
   PROCEDURE create_user (p_username             IN VARCHAR2,
                          p_password             IN VARCHAR2,
                          p_user_group_id_list   IN char_32_array_type,
                          p_db_office_id         IN VARCHAR2 DEFAULT NULL);


   PROCEDURE create_cwms_service_user;

   PROCEDURE delete_user (p_username IN VARCHAR2);

   PROCEDURE lock_user (p_username       IN VARCHAR2,
                        p_db_office_id   IN VARCHAR2 DEFAULT NULL);
   PROCEDURE update_edipi (p_username       IN VARCHAR2,
                        p_edipi   IN NUMBER,p_db_office_id   IN VARCHAR2 DEFAULT NULL);

   PROCEDURE remove_user_from_group (
      p_username        IN VARCHAR2,
      p_user_group_id   IN VARCHAR2,
      p_db_office_id    IN VARCHAR2 DEFAULT NULL);

   FUNCTION get_user_state (p_username       IN VARCHAR2,
                            p_db_office_id   IN VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2;

   PROCEDURE cat_at_sec_allow (p_at_sec_allow      OUT SYS_REFCURSOR,
                               p_db_office_id   IN     VARCHAR2 DEFAULT NULL);

   FUNCTION cat_at_sec_allow_tab (p_db_office_id IN VARCHAR2 DEFAULT NULL)
      RETURN cat_at_sec_allow_tab_t
      PIPELINED;

   PROCEDURE refresh_mv_sec_ts_privileges;

   PROCEDURE start_refresh_mv_sec_privs_job;
   PROCEDURE start_clean_session_job;

   PROCEDURE store_priv_groups (p_username             IN VARCHAR2,
                                p_user_group_id_list   IN char_32_array_type,
                                p_db_office_id_list    IN char_16_array_type,
                                p_is_member_list       IN char_16_array_type);

   PROCEDURE change_user_group_id (
      p_user_group_id_old   IN VARCHAR2,
      p_user_group_id_new   IN VARCHAR2,
      p_db_office_id        IN VARCHAR2 DEFAULT NULL);

   PROCEDURE change_user_group_desc (
      p_user_group_id     IN VARCHAR2,
      p_user_group_desc   IN VARCHAR2,
      p_db_office_id      IN VARCHAR2 DEFAULT NULL);

   PROCEDURE delete_user_group (p_user_group_id   IN VARCHAR2,
                                p_db_office_id    IN VARCHAR2 DEFAULT NULL);

   PROCEDURE create_user_group (p_user_group_id     IN VARCHAR2,
                                p_user_group_desc   IN VARCHAR2,
                                p_db_office_id      IN VARCHAR2 DEFAULT NULL);

   PROCEDURE delete_ts_group (p_ts_group_id    IN VARCHAR2,
                              p_db_office_id   IN VARCHAR2 DEFAULT NULL);

   PROCEDURE change_ts_group_id (
      p_ts_group_id_old   IN VARCHAR2,
      p_ts_group_id_new   IN VARCHAR2,
      p_db_office_id      IN VARCHAR2 DEFAULT NULL);

   PROCEDURE change_ts_group_desc (
      p_ts_group_id     IN VARCHAR2,
      p_ts_group_desc   IN VARCHAR2,
      p_db_office_id    IN VARCHAR2 DEFAULT NULL);

   PROCEDURE clear_ts_masks (p_ts_group_id    IN VARCHAR2,
                             p_db_office_id   IN VARCHAR2 DEFAULT NULL);

   PROCEDURE assign_ts_masks_to_ts_group (
      p_ts_group_id       IN VARCHAR2,
      p_ts_mask_list      IN char_183_array_type,
      p_add_remove_list   IN char_16_array_type,
      p_db_office_id      IN VARCHAR2 DEFAULT NULL);

   PROCEDURE create_ts_group (p_ts_group_id     IN VARCHAR2,
                              p_ts_group_desc   IN VARCHAR2,
                              p_db_office_id    IN VARCHAR2 DEFAULT NULL);

   FUNCTION get_admin_cwms_permissions (p_user_name      IN VARCHAR2,
                                        p_db_office_id   IN VARCHAR2)
      RETURN VARCHAR2;

   PROCEDURE get_user_cwms_permissions (
      p_cwms_permissions      OUT SYS_REFCURSOR,
      p_db_office_id       IN     VARCHAR2,
      p_include_all        IN     BOOLEAN DEFAULT FALSE);

   PROCEDURE get_db_users (p_db_users       OUT SYS_REFCURSOR,
                           p_db_office_id       VARCHAR2);

   PROCEDURE set_pd_user_passwd (p_pd_password   IN VARCHAR2,
                                  p_pd_username   IN VARCHAR2);
   PROCEDURE update_user_data (p_userid     IN VARCHAR2,
                               p_fullname   IN VARCHAR2,
                               p_org        IN VARCHAR2,
                               p_office     IN VARCHAR2,
                               p_phone      IN VARCHAR2,
                               p_email      IN VARCHAR2);
  PROCEDURE remove_session_key(p_session_key VARCHAR2);
  PROCEDURE clean_session_keys;
  PROCEDURE get_user_credentials (p_edipi      IN     NUMBER,
                                   p_user          OUT VARCHAR2,
                                   p_session_key      OUT VARCHAR2);
 PROCEDURE get_service_credentials(p_username OUT VARCHAR2,p_password OUT VARCHAR2);
END cwms_sec;
/

set define on
define cwms_schema = CWMS_20
prompt update for package body cwms_sec
/* Formatted on 5/28/2013 4:17:36 PM (QP5 v5.163.1008.3004) */
SET DEFINE ON

/* Formatted on 7/1/2013 1:09:40 PM (QP5 v5.163.1008.3004) */
create or replace package BODY cwms_sec
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
   END is_user_cwms_locked;

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

    PROCEDURE set_user_office_id (p_username              IN VARCHAR2,
                                            p_db_office_id   IN VARCHAR2
                                          )
    AS
        l_db_office_code         NUMBER := cwms_util.get_db_office_code (p_db_office_id);
        l_count                          NUMBER;
        l_username                       VARCHAR2 (31);
    BEGIN
        confirm_user_admin_priv (l_db_office_code);

        SELECT  COUNT (*)
          INTO  l_count
          FROM  at_sec_user_office
         WHERE  username = UPPER (TRIM (p_username));

        IF l_count > 0
        THEN
            UPDATE      at_sec_user_office
                SET     db_office_code = l_db_office_code
             WHERE      username = UPPER (TRIM (p_username));
        ELSE
            cwms_err.
            raise (
                'ERROR',
                    'User: '
                || UPPER (TRIM (p_username))
                || ' is not a valid CWMS account name.'
            );
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
   END set_dbi_user;

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
   END get_ts_group_code;

   FUNCTION get_user_office_id
      RETURN VARCHAR2
   IS
   BEGIN
      RETURN cwms_util.user_office_id;
   END get_user_office_id;

   PROCEDURE lock_db_account (p_username IN VARCHAR2)
   IS
      l_db_office_code   NUMBER := cwms_util.get_db_office_code (NULL);
   BEGIN
      confirm_user_admin_priv (l_db_office_code);

      cwms_dba.cwms_user_admin.lock_db_account (p_username);
   END lock_db_account;

   PROCEDURE unlock_db_account (p_username IN VARCHAR2)
   IS
      l_db_office_code   NUMBER := cwms_util.get_db_office_code (NULL);
   BEGIN
      confirm_user_admin_priv (l_db_office_code);

      cwms_dba.cwms_user_admin.unlock_db_account (p_username);
   END unlock_db_account;

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
         cwms_upass.update_user_data (p_username,
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
          INSERT INTO at_sec_user_office (username, db_office_code)
              VALUES   (l_username, l_db_office_code);
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX
            THEN
                NULL;
        END;

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

   PROCEDURE update_edipi (p_username IN VARCHAR2, p_edipi IN NUMBER,p_db_office_id   IN VARCHAR2 DEFAULT NULL)
   IS
   	l_db_office_id     VARCHAR2 (16)
                         := cwms_util.get_db_office_id (p_db_office_id);
   	l_db_office_code   NUMBER := cwms_util.get_db_office_code (l_db_office_id);
   BEGIN
   	confirm_user_admin_priv (l_db_office_code);

   	UPDATE AT_SEC_CWMS_USERS
      	SET EDIPI = p_edipi
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
   END get_user_group_code;

   PROCEDURE insert_noaccess_entry (p_username         IN VARCHAR2,
                                    p_db_office_code      NUMBER)
   IS
      l_count              NUMBER;
   BEGIN
      SELECT COUNT (*)
        INTO L_count
        FROM AT_SEC_USER_OFFICE
       WHERE USERNAME = p_username AND db_office_code = p_db_office_code;

      IF l_count = 0
      THEN
         INSERT
           INTO AT_SEC_USER_OFFICE (USERNAME, DB_OFFICE_CODE)
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
         INSERT INTO at_sec_users (db_office_code, user_group_code, username)
              VALUES (p_db_office_code, l_user_group_code, l_username);

         insert_noaccess_entry (p_username, p_db_office_code);
         COMMIT;
         IF (p_user_group_id = 'RDL Reviewer')
         THEN
            cwms_dba.cwms_user_admin.grant_rdl_role ('RDLREAD', l_username);
         END IF;

         IF (p_user_group_id = 'RDL Mgr')
         THEN
            cwms_dba.cwms_user_admin.grant_rdl_role ('RDLCRUD', l_username);
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
   END create_cwmsdbi_db_user;

   PROCEDURE create_logon_trigger (p_username IN VARCHAR2)
   IS
      l_cmd   VARCHAR (1024);
   BEGIN
      l_cmd :=
            'CREATE OR REPLACE TRIGGER '
         || p_username
         || '_logon_trigger AFTER LOGON ON '
         || p_username
         || '.SCHEMA BEGIN &cwms_schema..cwms_env.set_session_privileges; END;';

      EXECUTE IMMEDIATE l_cmd;

      COMMIT;
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

   PROCEDURE create_user (p_username             IN VARCHAR2,
                          p_password             IN VARCHAR2,
                          p_user_group_id_list   IN char_32_array_type,
                          p_db_office_id         IN VARCHAR2 DEFAULT NULL)
   IS
      l_db_office_id       VARCHAR2 (16)
                              := cwms_util.get_db_office_id (p_db_office_id);
      l_db_office_code     NUMBER
                              := cwms_util.get_db_office_code (l_db_office_id);
      l_username           VARCHAR2 (31) := UPPER (TRIM (p_username));
      l_user_group_code    NUMBER;
      l_count              NUMBER;
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

      create_cwms_db_account (l_username, p_password, l_db_office_id);

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

      insert_noaccess_entry (UPPER (p_username), l_db_office_code);

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
      create_logon_trigger(p_username);
      COMMIT;
   END CREATE_USER;

   PROCEDURE create_cwms_service_user
   IS
   BEGIN
    if(sys_context('userenv', 'current_user')='&cwms_schema')
    then
        CWMS_DBA.CWMS_USER_ADMIN.CREATE_CWMS_SERVICE_ACCOUNT(cac_service_user, RAWTOHEX (DBMS_CRYPTO.RANDOMBYTES (8)));
    end if;
   END create_cwms_service_user;

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

         DELETE FROM at_sec_user_office
               WHERE username = l_username
                     AND db_office_code IN
                            (SELECT UNIQUE db_office_code
                               FROM at_sec_users
                              WHERE username = cwms_util.get_user_id
                                    AND user_group_code IN
                                           (user_group_code_dba_users,
                                            user_group_code_user_admins));


         --DELETE FROM at_sec_cwms_users
         --WHERE userid = l_username;


         COMMIT;
      END IF;
   END delete_user;

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

      DELETE FROM at_sec_users
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
   END get_user_state;


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
   END set_dbi_user_passwd;

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
   END assign_ts_group_user_group;

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
   END refresh_mv_sec_ts_privileges;

      PROCEDURE start_sec_job(p_job_id VARCHAR2,p_run_interval NUMBER,p_action VARCHAR2,p_comment VARCHAR2)
   IS
      l_count          BINARY_INTEGER;
      l_user_id        VARCHAR2 (30);
      --l_job_id         VARCHAR2 (30) := 'REFRESH_MV_SEC_TS_PRIVS_JOB';
      --l_run_interval   VARCHAR2 (8) := '5';
      --l_comment        VARCHAR2 (256);

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

      IF l_user_id != '&cwms_schema'
      THEN
         raise_application_error (
            -20999,
            'Must be &cwms_schema user to start job ' || p_job_id,
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
               --job_action        => 'cwms_sec.refresh_mv_sec_ts_privileges',
               job_action        => p_action,
               start_date        => NULL,
               repeat_interval   => 'freq=minutely; interval='
                                   || p_run_interval,
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

   PROCEDURE start_refresh_mv_sec_privs_job
   IS
   BEGIN
    start_sec_job('REFRESH_MV_SEC_TS_PRIVS_JOB',5,'cwms_sec.refresh_mv_sec_ts_privileges','Refreshes mv_sec_ts_privileges when needed.');
   END start_refresh_mv_sec_privs_job;
   
   PROCEDURE start_clean_session_job
   IS
   BEGIN
    start_sec_job('CLEAN_SESSION_KEYS_JOB',1,'cwms_sec.clean_session_keys','Clean expired session keys');
   END start_clean_session_job;
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
       WHERE user_group_code = l_user_group_code
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
       WHERE user_group_code = l_user_group_code
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
   END delete_user_group;


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
       WHERE ts_group_code = l_ts_group_code
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
       WHERE ts_group_code = l_ts_group_code
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
   END create_ts_group;


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
   END is_user_admin;

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

      IF L_INCLUDE_ALL THEN
         open p_cwms_permissions for
            SELECT createdby
                   || '|'
                   ||  p.username
                   || '|x|'
                   || CWMS_SEC.GET_ADMIN_CWMS_PERMISSIONS (p.username, l_db_office_id)
                   || '|'
                   ||  case when fullname is null or length(fullname)=0 then ' ' else fullname end
                   || '|'
                   || case when u.edipi is null then 0 else u.edipi end 
              FROM at_sec_user_office p,
                   at_sec_cwms_users u
             WHERE p.username=u.userid
               AND p.db_office_code=l_db_office_code;
      ELSE
         open p_cwms_permissions for
            SELECT createdby
                   || '|'
                   ||  p.username
                   || '|x|'
                   || CWMS_SEC.GET_ADMIN_CWMS_PERMISSIONS (p.username, l_db_office_id)
                   || '|'
                   ||  case when fullname is null or length(fullname)=0 then ' ' else fullname end
                   || '|'
                   || case when u.edipi is null then 0 else u.edipi end 
              FROM at_sec_user_office p,
                   at_sec_cwms_users u
             WHERE p.username=u.userid
               AND p.db_office_code=l_db_office_code
               AND p.username = l_username;
      END IF;

   END get_user_cwms_permissions;

   PROCEDURE get_db_users (p_db_users       OUT SYS_REFCURSOR,
                           p_db_office_id       VARCHAR2)
   IS
	l_upass_id VARCHAR2(32);
   BEGIN
      l_upass_id := CWMS_PROPERTIES.GET_PROPERTY('CWMSDB','sec.upass.id','UPASSADM','CWMS');
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
				 'CCP',
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
                LEFT JOIN
                   at_sec_cwms_users s
                ON A.USERNAME = S.userid;
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
      cwms_upass.update_user_data(p_userid,p_fullname,p_org,p_office,p_phone,p_email);
   END update_user_data;

   FUNCTION is_cwms_schema_user(p_user VARCHAR2)
   RETURN BOOLEAN
   IS
   BEGIN
    IF(p_user = 'CWMS_20')
    THEN
        return true;
    ELSE
        return false;
    END IF;
   END is_cwms_schema_user;


   FUNCTION is_pd_user(p_user VARCHAR2)
   RETURN BOOLEAN
   IS
    l_db_office_code   NUMBER
                            := cwms_util.get_db_office_code (get_user_office_id);
   BEGIN
    RETURN is_member_user_group(user_group_code_pd_users,p_user,l_db_office_code);
   END is_pd_user;

    PROCEDURE update_service_timeout (p_username VARCHAR2)
    IS
    BEGIN
        UPDATE at_sec_service_user
           SET timeout = (SYSDATE + 1 / 24)
         WHERE userid = p_username;

        COMMIT;
    END update_service_timeout;

    PROCEDURE update_service_password (p_username VARCHAR2)
    IS
        l_password   VARCHAR2 (64) := NULL;
        l_handle     VARCHAR2 (128);
        l_ret        INTEGER := -1;
        l_timeout    DATE := SYSDATE-1;
    BEGIN
        IF is_cwms_schema_user (CWMS_UTIL.GET_USER_ID) = FALSE
        THEN
            RETURN;
        END IF;

        BEGIN
          SELECT TIMEOUT
            INTO l_timeout
            FROM AT_SEC_SERVICE_USER
            WHERE userid = p_username;
        EXCEPTION WHEN NO_DATA_FOUND THEN
          NULL;
        END;

        IF (SYSDATE > l_timeout)
        THEN
            l_password := RAWTOHEX (DBMS_CRYPTO.RANDOMBYTES (8));
            DBMS_LOCK.ALLOCATE_UNIQUE (lockname     => 'AT_SEC_SERVICE_USER',
                                       lockhandle   => l_handle);

            IF (DBMS_LOCK.REQUEST (lockhandle => l_handle, timeout => 10) = 0)
            THEN
                CWMS_DBA.CWMS_USER_ADMIN.update_service_password (p_username,
                                                              l_password);
                MERGE INTO AT_SEC_SERVICE_USER d
		  USING (SELECT 1 FROM DUAL) s
		  ON (d.userid = p_username)
                WHEN MATCHED THEN
                	UPDATE
                   		SET passwd = l_password, timeout = (SYSDATE + 1 / 24)
		WHEN NOT MATCHED THEN
			INSERT (userid,passwd,timeout) VALUES (p_username,l_password,SYSDATE+1/24);
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
                                       p_password   OUT VARCHAR2)
    IS
        l_handle     VARCHAR2 (128);
        l_ret        INTEGER := -1;
        l_username   VARCHAR2 (16) := cac_service_user;
    BEGIN
        IF is_pd_user (CWMS_UTIL.GET_USER_ID) = FALSE
        THEN
            RETURN;
        END IF;

        DBMS_LOCK.ALLOCATE_UNIQUE (lockname     => 'AT_SEC_SERVICE_USER',
                                   lockhandle   => l_handle);

        IF (DBMS_LOCK.REQUEST (lockhandle => l_handle, timeout => 10) = 0)
        THEN
            SELECT userid, passwd
              INTO p_username, p_password
              FROM at_sec_service_user
             WHERE userid = l_username;

            update_service_timeout(l_username);
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
        update_service_password(cac_service_user);
    END clean_session_keys; 

   PROCEDURE remove_session_key(p_session_key VARCHAR2)
   IS
   BEGIN
      IF is_pd_user(CWMS_UTIL.GET_USER_ID) = FALSE
      THEN
        RETURN;
      END IF;
      
      DELETE FROM AT_SEC_SESSION WHERE SESSION_KEY = p_session_key;
      COMMIT;
   END remove_session_key;

   PROCEDURE get_user_credentials (p_edipi      IN     NUMBER,
                                   p_user          OUT VARCHAR2,
                                   p_session_key      OUT VARCHAR2)
   IS
      l_count           NUMBER;
   BEGIN
      p_user := NULL;
      p_session_key := NULL;
      IF is_pd_user(CWMS_UTIL.GET_USER_ID) = FALSE
      THEN
        RETURN;
      END IF;
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
                 VALUES (p_user,
                         p_session_key,
                         SYSTIMESTAMP + 1 );


            COMMIT;
         END IF;
      END;
   END get_user_credentials;
END cwms_sec;
/
show errors

set define on
define cwms_schema = CWMS_20
prompt update for package body cwms_util
SET DEFINE ON



create or replace package BODY cwms_util
AS
   FUNCTION min_dms (p_decimal_degrees IN NUMBER)
      RETURN NUMBER
   IS
      l_sec_dms   NUMBER;
      l_min_dms   NUMBER;
   BEGIN
      l_sec_dms :=
         ROUND (
            ( (ABS (p_decimal_degrees - TRUNC (p_decimal_degrees)) * 60.0)
             - TRUNC (
                  ABS (p_decimal_degrees - TRUNC (p_decimal_degrees)) * 60))
            * 60.0,
            2);
      l_min_dms :=
         TRUNC (ABS (p_decimal_degrees - TRUNC (p_decimal_degrees)) * 60);

      IF l_sec_dms = 60
      THEN
         RETURN l_min_dms + 1;
      ELSE
         RETURN l_min_dms;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         NULL;
      WHEN OTHERS
      THEN
         -- Consider logging the error and then re-raise
         RAISE;
   END min_dms;

   --
   FUNCTION sec_dms (p_decimal_degrees IN NUMBER)
      RETURN NUMBER
   IS
      l_sec_dms   NUMBER;
      l_sec_60    NUMBER;
   BEGIN
      l_sec_dms :=
         ( (ABS (p_decimal_degrees - TRUNC (p_decimal_degrees)) * 60.0)
          - min_dms (p_decimal_degrees))
         * 60.0;
      l_sec_60 := ROUND (l_sec_dms, 2);

      IF l_sec_60 = 60
      THEN
         RETURN 0;
      ELSE
         RETURN l_sec_dms;
      END IF;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         NULL;
      WHEN OTHERS
      THEN
         -- Consider logging the error and then re-raise
         RAISE;
   END sec_dms;

   --
   FUNCTION min_dm (p_decimal_degrees IN NUMBER)
      RETURN NUMBER
   IS
   BEGIN
      RETURN (ABS (p_decimal_degrees - TRUNC (p_decimal_degrees)) * 60);
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         NULL;
      WHEN OTHERS
      THEN
         -- Consider logging the error and then re-raise
         RAISE;
   END min_dm;

   --
   -- Filter out PST and CST
   function get_timezone (p_timezone in varchar2)
   return varchar2
   is
      l_timezone varchar2(28);
   begin
      if p_timezone is not null then
         begin
            select time_zone_name
              into l_timezone
              from cwms_time_zone_alias
             where upper(time_zone_alias) = upper(p_timezone); 
         exception
            when no_data_found then l_timezone := p_timezone;
         end;
      end if;
      return l_timezone;
   end get_timezone;

   FUNCTION get_xml_time (p_local_time IN DATE, p_local_tz IN VARCHAR2)
      RETURN VARCHAR2
   IS
      l_interval        INTERVAL DAY TO SECOND;
      l_tz_designator   VARCHAR2 (6);
      l_xml_time        VARCHAR2 (32);
   BEGIN
      l_xml_time := TO_CHAR (p_local_time, 'yyyy-mm-dd"T"hh24:mi:ss');
      l_interval :=
         CAST (p_local_time AS TIMESTAMP)
         - CAST (
              cwms_util.change_timezone (p_local_time, p_local_tz, 'UTC') AS TIMESTAMP);
      l_tz_designator :=
         CASE l_interval = TO_DSINTERVAL ('00 00:00:00')
            WHEN TRUE
      THEN
               'Z'
         ELSE
                  TO_CHAR (EXTRACT (HOUR FROM l_interval), 'S09')
               || ':'
               || TRIM (TO_CHAR (EXTRACT (MINUTE FROM l_interval), '09'))
         END;
      RETURN l_xml_time || l_tz_designator;
   END get_xml_time;

   FUNCTION FIXUP_TIMEZONE (p_time IN TIMESTAMP WITH TIME ZONE)
      RETURN TIMESTAMP WITH TIME ZONE
   IS
      l_time   TIMESTAMP WITH TIME ZONE;
   BEGIN
      CASE EXTRACT (TIMEZONE_REGION FROM p_time)
         WHEN 'PST'
         THEN
            CASE EXTRACT (TIMEZONE_ABBR FROM p_time)
               WHEN 'PDT'
               THEN
                  l_time :=
                     (p_time + TO_DSINTERVAL ('0 01:00:00'))
                        AT TIME ZONE 'ETC/GMT+8';
               ELSE
                  l_time := p_time;
            END CASE;
         WHEN 'CST'
         THEN
            CASE EXTRACT (TIMEZONE_ABBR FROM p_time)
               WHEN 'CDT'
               THEN
                  l_time :=
                     (p_time + TO_DSINTERVAL ('0 01:00:00'))
                        AT TIME ZONE 'ETC/GMT+6';
               ELSE
                  l_time := p_time;
            END CASE;
         ELSE
            l_time := p_time;
      END CASE;

      RETURN l_time;
   END FIXUP_TIMEZONE;

   --
   -- return the p_in_date which is in p_in_tz as a date in UTC
   FUNCTION date_from_tz_to_utc (p_in_date IN DATE, p_in_tz IN VARCHAR2)
      RETURN DATE
   IS
   BEGIN
      RETURN change_timezone (p_in_date, p_in_tz);
   END date_from_tz_to_utc;

   --
   -- return the input date in a different time zone
   FUNCTION change_timezone (p_in_date   IN TIMESTAMP,
                             p_from_tz   IN VARCHAR2,
                             p_to_tz     IN VARCHAR2 DEFAULT 'UTC')
      RETURN TIMESTAMP
      RESULT_CACHE
   IS
   BEGIN
      RETURN CASE p_to_tz = p_from_tz
                WHEN TRUE
                THEN
                   p_in_date
                ELSE
                   FROM_TZ (p_in_date, get_timezone (p_from_tz))
                      AT TIME ZONE get_timezone (p_to_tz)
             END;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END change_timezone;

   --
   -- return the input date in a different time zone
   FUNCTION change_timezone (p_in_date   IN DATE,
                             p_from_tz   IN VARCHAR2,
                             p_to_tz     IN VARCHAR2 DEFAULT 'UTC')
      RETURN DATE
      RESULT_CACHE
   IS
   BEGIN
      RETURN CASE p_to_tz = p_from_tz
                WHEN TRUE
                THEN
                   p_in_date
                ELSE
                   CAST (
                      FROM_TZ (CAST (p_in_date AS TIMESTAMP),
                               get_timezone (p_from_tz))
                         AT TIME ZONE get_timezone (p_to_tz) AS DATE)
             END;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN NULL;
   END change_timezone;

   FUNCTION get_base_id (p_full_id IN VARCHAR2)
      RETURN VARCHAR2
      RESULT_CACHE
   IS
      l_num          NUMBER
                        := INSTR (p_full_id,
                                  '-',
                                  1,
                                  1);
      l_length       NUMBER := LENGTH (p_full_id);
      l_sub_length   NUMBER := l_length - l_num;
   BEGIN
      IF    INSTR (p_full_id,
                   '.',
                   1,
                   1) > 0
         OR l_num = l_length
         OR l_num = 1
         OR l_sub_length > max_sub_id_length
         OR l_num > max_base_id_length + 1
         OR l_length > max_full_id_length
      THEN
         cwms_err.raise ('INVALID_FULL_ID', p_full_id);
      END IF;

      IF l_num = 0
      THEN
         RETURN p_full_id;
      ELSE
         RETURN SUBSTR (p_full_id, 1, l_num - 1);
      END IF;
   END get_base_id;

   FUNCTION get_base_param_code (p_param_id     IN VARCHAR2,
                                 p_is_full_id   IN VARCHAR2 DEFAULT 'F')
      RETURN NUMBER
      RESULT_CACHE
   IS
      l_base_param_code   NUMBER (10);
      l_base_param_id     VARCHAR2 (16);
   BEGIN
      CASE cwms_util.is_true (p_is_full_id)
         WHEN TRUE
         THEN
            l_base_param_id := get_base_id (p_param_id);
         WHEN FALSE
         THEN
            l_base_param_id := p_param_id;
      END CASE;

      SELECT base_parameter_code
        INTO l_base_param_code
        FROM cwms_base_parameter
       WHERE UPPER (base_parameter_id) = UPPER (TRIM (l_base_param_id));

      RETURN l_base_param_code;
   END get_base_param_code;

   FUNCTION get_sub_id (p_full_id IN VARCHAR2)
      RETURN VARCHAR2
      RESULT_CACHE
   IS
      l_num          NUMBER
                        := INSTR (p_full_id,
                                  '-',
                                  1,
                                  1);
      l_length       NUMBER := LENGTH (p_full_id);
      l_sub_length   NUMBER := l_length - l_num;
   BEGIN
      IF    INSTR (p_full_id,
                   '.',
                   1,
                   1) > 0
         OR l_num = l_length
         OR l_num = 1
         OR l_sub_length > max_sub_id_length
         OR l_num > max_base_id_length + 1
         OR l_length > max_full_id_length
      THEN
         cwms_err.raise ('INVALID_FULL_ID', p_full_id);
      END IF;

      IF l_num = 0
      THEN
         RETURN NULL;
      ELSE
         RETURN SUBSTR (p_full_id, l_num + 1, l_sub_length);
      END IF;
   END get_sub_id;

   FUNCTION is_true (p_true_false IN VARCHAR2)
      RETURN BOOLEAN
      RESULT_CACHE
   IS
   BEGIN
      IF UPPER (p_true_false) = 'T' OR UPPER (p_true_false) = 'TRUE'
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END is_true;

   --
   FUNCTION is_false (p_true_false IN VARCHAR2)
      RETURN BOOLEAN
      RESULT_CACHE
   IS
   BEGIN
      IF UPPER (p_true_false) = 'F' OR UPPER (p_true_false) = 'FALSE'
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END is_false;

   -- Retruns TRUE if p_true_false is T or True
   -- Returns FALSE if p_true_false is F or False.
   FUNCTION return_true_or_false (p_true_false IN VARCHAR2)
      RETURN BOOLEAN
      RESULT_CACHE
   IS
   BEGIN
      IF cwms_util.is_true (p_true_false)
      THEN
         RETURN TRUE;
      ELSIF cwms_util.is_false (p_true_false)
      THEN
         RETURN FALSE;
      ELSE
         cwms_err.raise ('INVALID_T_F_FLAG', p_true_false);
      END IF;
   END return_true_or_false;

   -- Retruns 'T' if p_true_false is T or True
   -- Returns 'F 'if p_true_false is F or False.
   FUNCTION return_t_or_f_flag (p_true_false IN VARCHAR2)
      RETURN VARCHAR2
      RESULT_CACHE
   IS
   BEGIN
      IF cwms_util.is_true (p_true_false)
      THEN
         RETURN 'T';
      ELSIF cwms_util.is_false (p_true_false)
      THEN
         RETURN 'F';
      ELSE
         cwms_err.raise ('INVALID_T_F_FLAG', p_true_false);
      END IF;
   END return_t_or_f_flag;

   --------------------------------------------------------------------------------
   -- function get_real_name
   --
   FUNCTION get_real_name (p_synonym IN VARCHAR2)
      RETURN VARCHAR2
   IS
      l_name             VARCHAR2 (32) := UPPER (p_synonym);
      invalid_sql_name   EXCEPTION;
      PRAGMA EXCEPTION_INIT (invalid_sql_name, -44003);
   BEGIN
      BEGIN
         SELECT DBMS_ASSERT.simple_sql_name (l_name) INTO l_name FROM DUAL;

         SELECT table_name
           INTO l_name
           FROM sys.all_synonyms
          WHERE     synonym_name = l_name
                AND owner = 'PUBLIC'
                AND table_owner = '&cwms_schema';
      EXCEPTION
         WHEN invalid_sql_name
         THEN
            cwms_err.raise ('INVALID_ITEM', p_synonym, 'schema item name');
         WHEN NO_DATA_FOUND
         THEN
            NULL;
      END;

      RETURN l_name;
   END get_real_name;

   --------------------------------------------------------
   -- Return the current session user's primary office id
   --
   FUNCTION user_office_id
      RETURN VARCHAR2
   IS
      l_office_id   VARCHAR2 (16);
      l_username    VARCHAR2 (32);
      l_upass_id    VARCHAR2 (32) := 'UPASSADM';
   BEGIN
      l_username := get_user_id;

      BEGIN
      	SELECT prop_value INTO l_upass_id FROM at_properties where prop_id='sec.upass.id' and prop_category='CWMS' and office_code=53;
      EXCEPTION WHEN OTHERS
      THEN
	NULL;
      END;

      SELECT SYS_CONTEXT ('CWMS_ENV', 'SESSION_OFFICE_ID')
        INTO l_office_id
        FROM DUAL;

      IF l_office_id IS NULL
      THEN
         IF l_username = '&cwms_schema' or l_username = 'NOBODY' or l_username = 'CCP' or l_username = 'SYS' or l_username = l_upass_id
         THEN
            RETURN 'CWMS';
         ELSE
      BEGIN
         SELECT a.office_id
           INTO l_office_id
           FROM cwms_office a, at_sec_user_office b
          WHERE     b.username = l_username
		AND a.office_code=b.db_office_code;
	    EXCEPTION WHEN OTHERS THEN
                cwms_err.raise ('SESSION_OFFICE_ID_NOT_SET');
            END;
         END IF;
         END IF;

      RETURN l_office_id;
   END user_office_id;

   PROCEDURE get_user_office_data (p_office_id          OUT VARCHAR2,
                                   p_office_long_name   OUT VARCHAR2)
   IS
      l_office_id   VARCHAR2 (16) := user_office_id;
   BEGIN
      SELECT office_id, long_name
           INTO p_office_id, p_office_long_name
        FROM cwms_office
       WHERE office_id = l_office_id;
   END get_user_office_data;

   --------------------------------------------------------
   -- Return the current session user's primary office code
   --
   FUNCTION user_office_code
      RETURN NUMBER
   IS
      l_office_code   NUMBER (10) := 0;
      l_office_id     VARCHAR2 (16) := user_office_id;
      BEGIN
      SELECT office_code
        INTO l_office_code
        FROM cwms_office
       WHERE office_id = l_office_id;


      RETURN l_office_code;
   END user_office_code;

   --------------------------------------------------------
   -- Return the office code for the specified office id,
   -- or the user's primary office if the office id is null
   --
   FUNCTION get_office_code (p_office_id IN VARCHAR2 DEFAULT NULL)
      RETURN NUMBER
   IS
      l_office_code   NUMBER := NULL;
   BEGIN
      IF p_office_id IS NULL
      THEN
         l_office_code := user_office_code;
      ELSE
         SELECT office_code
           INTO l_office_code
           FROM cwms_office
          WHERE (office_id) = UPPER (p_office_id);
      END IF;

      RETURN l_office_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.raise ('INVALID_OFFICE_ID', p_office_id);
   END get_office_code;

   --------------------------------------------------------
   -- Return the db host office code for the specified office id,
   -- or the user's primary office if the office id is null
   --
   FUNCTION get_db_office_code (p_office_id IN VARCHAR2 DEFAULT NULL)
      RETURN NUMBER
   IS
      l_db_office_code   NUMBER := NULL;
   BEGIN
      RETURN get_office_code (p_office_id);
   END get_db_office_code;

   FUNCTION get_db_office_id_from_code (p_db_office_code IN NUMBER)
      RETURN VARCHAR2
   IS
      l_db_office_id   VARCHAR2 (64);
   BEGIN
      l_db_office_id := NULL;

      SELECT office_id
        INTO l_db_office_id
        FROM cwms_office
       WHERE office_code = p_db_office_code;


      RETURN l_db_office_id;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RETURN l_db_office_id;
   END get_db_office_id_from_code;

   --------------------------------------------------------
   --------------------------------------------------------
   FUNCTION get_db_office_id (p_db_office_id IN VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2
   IS
      l_db_office_code   NUMBER := NULL;
      l_db_office_id     VARCHAR2 (16);
   BEGIN
      IF p_db_office_id IS NULL
      THEN
         l_db_office_id := user_office_id;
      ELSE
         SELECT office_id
           INTO l_db_office_id
           FROM cwms_office
          WHERE (office_id) = UPPER (p_db_office_id);
      END IF;

      RETURN l_db_office_id;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.raise ('INVALID_OFFICE_ID', p_db_office_id);
   END get_db_office_id;

   --------------------------------------------------------
   --------------------------------------------------------
   FUNCTION get_location_id (p_location_code    IN NUMBER,
                             p_prepend_office   IN VARCHAR2 DEFAULT 'F')
      RETURN VARCHAR2
   IS
      l_location_id   VARCHAR2 (183);
      l_office_id     VARCHAR2 (16);
   BEGIN
      SELECT o.office_id,
                bl.base_location_id
             || SUBSTR ('-', 1, LENGTH (pl.sub_location_id))
             || pl.sub_location_id
        INTO l_office_id, l_location_id
        FROM at_physical_location pl, at_base_location bl, cwms_office o
       WHERE     pl.location_code = p_location_code
             AND bl.base_location_code = pl.base_location_code
             AND o.office_code = bl.db_office_code;

      IF is_true (p_prepend_office)
      THEN
         RETURN l_office_id || '/' || l_location_id;
      END IF;

      RETURN l_location_id;
   END get_location_id;

   --------------------------------------------------------
   --------------------------------------------------------
   FUNCTION get_parameter_id (p_parameter_code IN NUMBER)
      RETURN VARCHAR2
      RESULT_CACHE
   IS
      l_parameter_id   VARCHAR2 (49);
   BEGIN
      BEGIN
         SELECT    cbp.base_parameter_id
                || SUBSTR ('-', 1, LENGTH (atp.sub_parameter_id))
                || atp.sub_parameter_id
           INTO l_parameter_id
           FROM at_parameter atp, cwms_base_parameter cbp
          WHERE atp.parameter_code = p_parameter_code
                AND atp.base_parameter_code = cbp.base_parameter_code;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.raise (
               'ERROR',
               p_parameter_code || ' is not a valid parameter_code.');
      END;

      RETURN l_parameter_id;
   END get_parameter_id;

   --------------------------------------------------------
   -- Replace filename wildcard chars (?,*) with SQL ones
   -- (_,%), using '\' as an escape character.
   --
   --  A null input generates a result of '%'.
   --
   -- +--------------+-------------------------------------------------------------------------+
   -- |     |       Output String                |
   -- |     +------------------------------------------------------------+------------+
   -- |     |          Recognize SQL       |      |
   -- |     |           Wildcards?        |      |
   -- |     +------+---------------------------+-----+-------------------+      |
   -- | Input String | No  : comments        | Yes : comments    | Different? |
   -- +--------------+------+---------------------------+-----+-------------------+------------+
   -- | %    | \%  : literal '%'               | %   : multi-wildcard    | Yes        |
   -- | _    | \_  : literal '_'               | _   : single-wildcard   | Yes        |
   -- | *    | %  : multi-wildcard      | %   : multi-wildcard  | No     |
   -- | ?    | _  : single-wildcard     | _   : single-wildcard  | No     |
   -- | \%    |   : not allowed       | \%  : literal '%'       | Yes        |
   -- | \_    |   : not allowed       | \_  : literal '_'       | Yes        |
   -- | \*    | *  : literal '*'               | *   : literal '*'       | No         |
   -- | \?    | ?  : literal '?'               | ?   : literal '?'       | No         |
   -- | \\%    | \\\% : literal '\' + literal '%' | \\% : literal '\' + mwc | Yes        |
   -- | \\_    | \\\_ : literal '\' + literal '\' | \\_ : literal '\' + swc | Yes        |
   -- | \\*    | \\%  : literal '\' + mwc         | \\% : literal '\' + mwc | No         |
   -- | \\?    | \\_  : literal '\' + swc         | \\_ : literal '\' + swc | No         |
   -- +--------------+------+---------------------------+-----+-------------------+------------+
   --
   FUNCTION normalize_wildcards (p_string          IN VARCHAR2,
                                 p_recognize_sql   IN BOOLEAN DEFAULT FALSE)
      RETURN VARCHAR2
   IS
      l_result              VARCHAR2 (32767);
      c_slash      CONSTANT VARCHAR2 (1) := CHR (1);
      c_star       CONSTANT VARCHAR2 (1) := CHR (2);
      c_question   CONSTANT VARCHAR2 (1) := CHR (3);
   BEGIN
      --------------------------------
      -- default null string to '%' --
      --------------------------------
      IF p_string IS NULL
      THEN
         RETURN '%';
      END IF;

      l_result := REPLACE (p_string, '\\', c_slash);
      l_result := REPLACE (l_result, '\*', c_star);
      l_result := REPLACE (l_result, '\?', c_question);

      IF SUBSTR (l_result, LENGTH (l_result), 1) = '\'
      THEN
         cwms_err.raise (
            'ERROR',
            'Escape characater ''\'' cannot be the last character.');
      END IF;

      IF NOT p_recognize_sql
      THEN
         IF INSTR (l_result, '\%') + INSTR (l_result, '\_') != 0
         THEN
            cwms_err.raise (
               'ERROR',
               'Cannot have ''\%'' or ''\_'' if p_recognize_sql is false.');
         END IF;

         l_result := REGEXP_REPLACE (l_result, '%', '\%');
         l_result := REGEXP_REPLACE (l_result, '_', '\_');
      END IF;

      l_result := REPLACE (l_result, '*', '%');
      l_result := REPLACE (l_result, '?', '_');
      l_result := REPLACE (l_result, c_slash, '\\');
      l_result := REPLACE (l_result, c_star, '*');
      l_result := REPLACE (l_result, c_question, '?');

      RETURN l_result;
   END normalize_wildcards;

   --------------------------------------------------------
   -- Replace SQL ones (_,%) with filename wildcard chars (?,*),
   -- using '\' as an escape character.
   FUNCTION denormalize_wildcards (p_string IN VARCHAR2)
      RETURN VARCHAR2
   IS
      l_result              VARCHAR2 (32767);
      c_slash      CONSTANT VARCHAR2 (1) := CHR (1);
      c_percent    CONSTANT VARCHAR2 (1) := CHR (2);
      c_underbar   CONSTANT VARCHAR2 (1) := CHR (3);
   BEGIN
      --------------------------------
      -- default null string to '*' --
      --------------------------------
      IF p_string IS NULL
      THEN
         RETURN '*';
      END IF;

      l_result := REPLACE (p_string, '\\', c_slash);
      l_result := REPLACE (l_result, '\%', c_percent);
      l_result := REPLACE (l_result, '\_', c_underbar);

      IF SUBSTR (l_result, LENGTH (l_result), 1) = '\'
      THEN
         cwms_err.raise (
            'ERROR',
            'Escape characater ''\'' cannot be the last character.');
      END IF;

      l_result := REPLACE (l_result, '%', '*');
      l_result := REPLACE (l_result, '_', '?');
      l_result := REPLACE (l_result, c_slash, '\\');
      l_result := REPLACE (l_result, c_percent, '%');
      l_result := REPLACE (l_result, c_underbar, '_');

      RETURN l_result;
   END denormalize_wildcards;

   PROCEDURE parse_ts_id (p_base_location_id       OUT VARCHAR2,
                          p_sub_location_id        OUT VARCHAR2,
                          p_base_parameter_id      OUT VARCHAR2,
                          p_sub_parameter_id       OUT VARCHAR2,
                          p_parameter_type_id      OUT VARCHAR2,
                          p_interval_id            OUT VARCHAR2,
                          p_duration_id            OUT VARCHAR2,
                          p_version_id             OUT VARCHAR2,
                          p_cwms_ts_id          IN     VARCHAR2)
   IS
   BEGIN
      cwms_ts.parse_ts (p_cwms_ts_id          => p_cwms_ts_id,
                        p_base_location_id    => p_base_location_id,
                        p_sub_location_id     => p_sub_location_id,
                        p_base_parameter_id   => p_base_parameter_id,
                        p_sub_parameter_id    => p_sub_parameter_id,
                        p_parameter_type_id   => p_parameter_type_id,
                        p_interval_id         => p_interval_id,
                        p_duration_id         => p_duration_id,
                        p_version_id          => p_version_id);
   END parse_ts_id;

   --------------------------------------------------------------------------------
   -- Parses a search string into one or more AND/OR LIKE/NOT LIKE predicate lines.
   -- A search string contains one or more search patterns separated by a blank -
   -- space. When constructing search patterns on can use AND, OR, and NOT between-
   -- search patterns. a blank space between two patterns is assumed to be an AND.
   -- Quotes can be used to aggregate search patterns that contain one or more  -
   -- blank spaces.
   --
   FUNCTION parse_search_string (p_search_patterns   IN VARCHAR2,
                                 p_search_column     IN VARCHAR2,
                                 p_use_upper         IN BOOLEAN DEFAULT TRUE)
      RETURN VARCHAR2
   --------------------------------------------------------------------------------
   -- Usage:                    -
   --   *  - wild card character matches zero or more occurences.   -
   --   ?  - wild card character matches zero or one occurence.   -
   --   and - AND or a blank space, e.g., abc* *123 is eqivalent to   -
   --             abc* AND *123       -
   --   or - OR  e.g., abc* OR *123             -
   --   not - NOT or a dash, e.g., 'NOT abc*' is equivalent to '-abc*'     -
   --   " " - quotes are used to aggregate patters that have blank spaces   -
   --   e.g., "abc 123*"                                              -
   --
   --   One can use the backslash as an escape character for the following  -
   --   special characters:               -
   --   \* used to make an asterisks a literal instead of a wild character  -                    -
   --   \? used to make a question mark a literal instead of a wild   -
   --   character                   -
   --   \- used to start a new parse pattern with a dash instead of a NOT -
   --   \" used to make a quote a literal part of the parse pattern.        -
   --
   -- Example:
   -- p_search_column: COLUMN_OF_INTEREST           -
   -- p_search_patterns: cb* NOT cbt* OR NOT cbk*         -
   --   will return:                  -
   --    AND UPPER(COLUMN_OF_INTEREST)  LIKE 'CB%'                -
   --    AND UPPER(COLUMN_OF_INTEREST) NOT LIKE 'CBT%'            -
   --    OR UPPER(COLUMN_OF_INTEREST) NOT LIKE 'CBK%'             -
   --
   --  if p_use_upper is set to false, the above will return:
   --
   --     AND COLUMN_OF_INTEREST  LIKE 'cb%'                      -
   --     AND COLUMN_OF_INTEREST NOT LIKE 'cbt%'                  -
   --     OR COLUMN_OF_INTEREST NOT LIKE 'cbk%'                   -
   --
   --  A null p_search_patterns generates a result of '%'.
   --
   --     AND COLUMN_OF_INTEREST  LIKE '%'                        -
   --------------------------------------------------------------------------------
   --
   IS
      l_string                VARCHAR2 (256) := TRIM (p_search_patterns);
      l_search_column         VARCHAR2 (30) := UPPER (TRIM (p_search_column));
      l_use_upper             BOOLEAN := NVL (p_use_upper, TRUE);
      l_recognize_sql         BOOLEAN := FALSE;
      l_string_length         NUMBER := NVL (LENGTH (l_string), 0);
      l_skip                  NUMBER := 0;
      l_looking_first_quote   BOOLEAN := TRUE;
      l_sub_string_done       BOOLEAN := FALSE;
      l_first_char            BOOLEAN := TRUE;
      l_char                  VARCHAR2 (1);
      l_sub_string            VARCHAR2 (64) := NULL;
      l_not                   VARCHAR2 (3) := NULL;
      l_and_or                VARCHAR2 (3) := 'AND';
      l_result                VARCHAR2 (1000) := NULL;
      l_open_upper            VARCHAR2 (7);
      l_close_upper           VARCHAR2 (2);
      l_open_paran            VARCHAR2 (10) := NULL;
      l_close_paran           VARCHAR2 (10) := NULL;
      l_space                 VARCHAR2 (1) := ' ';
      l_num_open_paran        NUMBER := 0;
      l_char_position         NUMBER := 0;
      l_num_element           NUMBER := 0;
      l_tmp_string            VARCHAR2 (100) := NULL;
      l_is_closing_quotes     BOOLEAN;
   BEGIN
      --
      -- set the UPPER( ) wrapper...
      IF l_use_upper
      THEN
         l_open_upper := ' UPPER(';
         l_close_upper := ') ';
      ELSE
         l_open_upper := ' ';
         l_close_upper := ' ';
      END IF;

      --
      -- Make sure something was passed in.
      IF l_string_length > 0
      THEN
         FOR i IN 1 .. LENGTH (l_string)
         LOOP
            --   IF l_looking_first_quote
            --   THEN
            --   l_t := 'T';
            --   ELSE
            --   l_t := 'F';
            --   END IF;

            --   DBMS_OUTPUT.put_line (  l_t
            --         || l_char_position
            --         || '>'
            --         || l_sub_string
            --         || '< skip: '
            --         || l_skip
            --        );
            IF l_skip > 0
            THEN
               l_skip := l_skip - 1;
            ELSE
               l_char := SUBSTR (l_string, i, 1);

               --dbms_output.put_line('>>' || l_char || '<<');
               CASE l_char
                  WHEN '\'
                  THEN
                     IF REGEXP_INSTR (NVL (SUBSTR (l_string, i + 1, 1), ' '),
                                      '["*?\(\)]') = 1
                     THEN
                        l_sub_string :=
                           l_sub_string || '\' || SUBSTR (l_string, i + 1, 1);
                        l_char_position := l_char_position + 2;
                     ELSE
                        l_sub_string :=
                           l_sub_string || SUBSTR (l_string, i + 1, 1);
                        l_char_position := l_char_position + 1;
                     END IF;

                     l_skip := l_skip + 1;
                  WHEN '('
                  THEN
                     IF l_char_position = 0
                     THEN
                        l_sub_string := l_sub_string || l_char;
                     ELSE
                        l_sub_string := l_sub_string || l_char;
                        l_char_position := l_char_position + 1;
                     END IF;
                  WHEN ')'
                  THEN
                     l_tmp_string := NULL;

                     FOR j IN i .. l_string_length
                     LOOP
                        l_tmp_string := l_tmp_string || ')';
                        l_skip := l_skip + 1;

                        --DBMS_OUTPUT.put_line (l_tmp_string);
                        IF j = l_string_length
                           OR INSTR (NVL (SUBSTR (l_string, j + 1, 1), ' '),
                                     ' ') = 1
                        THEN
                           l_is_closing_quotes := TRUE;
                           EXIT;
                        ELSIF INSTR (NVL (SUBSTR (l_string, j + 1, 1), ' '),
                                     ')') = 1
                        THEN
                           NULL;
                        ELSE
                           l_is_closing_quotes := FALSE;
                           EXIT;
                        END IF;
                     END LOOP;

                     IF l_is_closing_quotes
                     THEN
                        l_close_paran := l_tmp_string;
                     ELSE
                        l_sub_string := l_sub_string || l_tmp_string;
                     END IF;
                  WHEN '"'
                  THEN
                     IF l_looking_first_quote
                     THEN
                        IF l_char_position = 0
                        THEN
                           l_looking_first_quote := FALSE;
                        ELSE
                           l_sub_string := l_sub_string || l_char;
                           l_char_position := l_char_position + 1;
                        END IF;
                     ELSE                        -- looking for the end quote.
                        --
                        -- An end quote must be followed by a space or end the string.
                        --
                        l_tmp_string := NULL;

                        FOR j IN i .. l_string_length
                        LOOP
                           -- l_tmp_string := l_tmp_string || ')';
                           --l_skip := l_skip + 1;
                           --DBMS_OUTPUT.put_line (l_tmp_string);
                           IF j = l_string_length
                              OR INSTR (
                                    NVL (SUBSTR (l_string, j + 1, 1), ' '),
                                    ' ') = 1
                           THEN
                              l_is_closing_quotes := TRUE;
                              l_sub_string_done := TRUE;
                              --dbms_output.put_line('string is done!');
                              EXIT;
                           ELSIF INSTR (
                                    NVL (SUBSTR (l_string, j + 1, 1), ' '),
                                    ')') = 1
                           THEN
                              l_tmp_string := l_tmp_string || ')';
                              l_skip := l_skip + 1;
                           ELSE
                              l_is_closing_quotes := FALSE;
                              EXIT;
                           END IF;
                        END LOOP;

                        IF l_is_closing_quotes
                        THEN
                           l_close_paran := l_tmp_string;
                        ELSE
                           l_sub_string := '"' || l_sub_string || l_tmp_string;
                        END IF;
                     -----------------
                     --     IF  INSTR (NVL (SUBSTR (l_string, i + 1), ' '), ' ') =
                     --                       1
                     --      OR i = l_string_length
                     --     THEN
                     --      l_skip := l_skip + 1;
                     --      l_sub_string_done := TRUE;
                     --     ELSE
                     --      l_sub_string := l_sub_string || l_char;
                     --      l_char_position := l_char_position + 1;
                     --     END IF;
                     END IF;
                  WHEN ' '
                  THEN
                     IF l_looking_first_quote
                     THEN
                        l_sub_string_done := TRUE;
                     ELSE
                        l_sub_string := l_sub_string || l_char;
                        l_char_position := l_char_position + 1;
                     END IF;
                  ELSE
                     l_sub_string := l_sub_string || l_char;
                     l_char_position := l_char_position + 1;
               END CASE;
            END IF;

            IF l_sub_string_done OR i = l_string_length
            THEN
               IF LENGTH (l_sub_string) > 0
               THEN
                  IF i = l_string_length
                  THEN
                     l_sub_string_done := TRUE;
                  END IF;

                  IF l_looking_first_quote
                  THEN
                     CASE l_sub_string
                        WHEN 'OR'
                        THEN
                           l_and_or := 'OR';
                           l_sub_string_done := FALSE;
                        WHEN 'AND'
                        THEN
                           l_and_or := 'AND';
                           l_sub_string_done := FALSE;
                        WHEN 'NOT'
                        THEN
                           l_not := 'NOT';
                           l_sub_string_done := FALSE;
                        ELSE
                           NULL;
                     END CASE;
                  END IF;

                  IF l_sub_string_done
                  THEN
                     l_sub_string :=
                        cwms_util.normalize_wildcards (
                           p_string          => l_sub_string,
                           p_recognize_sql   => l_recognize_sql);

                     IF l_use_upper
                     THEN
                        l_sub_string := UPPER (l_sub_string);
                     END IF;

                     IF l_num_element = 0
                     THEN
                        l_and_or := ' ( ';
                        l_num_element := 1;
                     END IF;

                     l_result :=
                           l_result
                        || ' '
                        || l_and_or
                        || l_space
                        || l_open_paran
                        || l_open_upper
                        || l_search_column
                        || l_close_upper
                        || l_not
                        || ' LIKE '''
                        || l_sub_string
                        || ''' '
                        || l_close_paran
                        || l_space
                        || CHR (10);
                     l_and_or := 'AND';
                     l_not := NULL;
                     l_open_paran := NULL;
                     l_close_paran := NULL;
                     l_looking_first_quote := TRUE;
                  END IF;
               END IF;

               l_first_char := TRUE;
               l_sub_string := NULL;
               l_sub_string_done := FALSE;
               l_char_position := 0;
            END IF;
         END LOOP;

         l_result := l_result || ' ) ';
      ELSE
         l_result := ' 1 = 1 ';
      END IF;

      RETURN l_result;
   END parse_search_string;

   --------------------------------------------------------------------
   -- Return a string with all leading and trailing whitespace removed.
   --
   FUNCTION strip (p_text IN VARCHAR2)
      RETURN VARCHAR2
   IS
      l_first   PLS_INTEGER := 1;
      l_last    PLS_INTEGER := LENGTH (p_text);
   BEGIN
      if p_text is null then 
         return null; 
      end if;
      FOR i IN l_first .. l_last
      LOOP
         l_first := i;
         EXIT WHEN ASCII (SUBSTR (p_text, i, 1)) BETWEEN 33 AND 126;
      END LOOP;

      FOR i IN REVERSE l_first .. l_last
      LOOP
         l_last := i;
         EXIT WHEN ASCII (SUBSTR (p_text, i, 1)) BETWEEN 33 AND 126;
      END LOOP;

      RETURN SUBSTR (p_text, l_first, l_last - l_first + 1);
   END strip;

   --------------------------------------------------------------------------------
   PROCEDURE test
   IS
   BEGIN
      DBMS_OUTPUT.put_line ('successful test');
   END test;

   FUNCTION concat_base_sub_id (p_base_id IN VARCHAR2, p_sub_id IN VARCHAR2)
      RETURN VARCHAR2
      RESULT_CACHE
   IS
   BEGIN
      RETURN    p_base_id
             || SUBSTR ('-', 1, LENGTH (TRIM (p_sub_id)))
             || TRIM (p_sub_id);
   END concat_base_sub_id;

   FUNCTION concat_ts_id (p_base_location_id    IN VARCHAR2,
                          p_sub_location_id     IN VARCHAR2,
                          p_base_parameter_id   IN VARCHAR2,
                          p_sub_parameter_id    IN VARCHAR2,
                          p_parameter_type_id   IN VARCHAR2,
                          p_interval_id         IN VARCHAR2,
                          p_duration_id         IN VARCHAR2,
                          p_version_id          IN VARCHAR2)
      RETURN VARCHAR2
   IS
      l_base_location_id    VARCHAR2 (16) := TRIM (p_base_location_id);
      l_sub_location_id     VARCHAR2 (32) := TRIM (p_sub_location_id);
      l_base_parameter_id   VARCHAR2 (16) := TRIM (p_base_parameter_id);
      l_sub_parameter_id    VARCHAR2 (32) := TRIM (p_sub_parameter_id);
      l_parameter_type_id   VARCHAR2 (16) := TRIM (p_parameter_type_id);
      l_interval_id         VARCHAR2 (16) := TRIM (p_interval_id);
      l_duration_id         VARCHAR2 (16) := TRIM (p_duration_id);
      l_version_id          VARCHAR2 (32) := TRIM (p_version_id);
   BEGIN
      SELECT cbp.base_parameter_id
        INTO l_base_parameter_id
        FROM cwms_base_parameter cbp
       WHERE UPPER (cbp.base_parameter_id) = UPPER (l_base_parameter_id);

      SELECT cpt.parameter_type_id
        INTO l_parameter_type_id
        FROM cwms_parameter_type cpt
       WHERE UPPER (cpt.parameter_type_id) = UPPER (l_parameter_type_id);

      SELECT interval_id
        INTO l_interval_id
        FROM cwms_interval ci
       WHERE UPPER (ci.interval_id) = UPPER (l_interval_id);

      SELECT duration_id
        INTO l_duration_id
        FROM cwms_duration cd
       WHERE UPPER (cd.duration_id) = UPPER (l_duration_id);

      IF l_parameter_type_id = 'Inst' AND l_duration_id != '0'
      THEN
         cwms_err.raise (
            'ERROR',
               'The Duration Id for an "Inst" record cannot be "'
            || l_duration_id
            || '". The Duration Id must be "0".');
      -----------------------------------------------------------------
      -- This condition is no longer true. A "0" duration indicates  --
      -- a duration from the last irregular value to the current one --
      -----------------------------------------------------------------
      -- ELSIF l_parameter_type_id IN ('Ave', 'Max', 'Min', 'Total') AND l_duration_id = '0'
      -- THEN
      --  cwms_err.raise (
      --   'ERROR',
      --    'A Parameter Type of "'
      --   || l_parameter_type_id
      --   || '" cannot have a "0" Duration Id.'
      --  );
      END IF;

      RETURN    l_base_location_id
             || SUBSTR ('-', 1, LENGTH (l_sub_location_id))
             || l_sub_location_id
             || '.'
             || l_base_parameter_id
             || SUBSTR ('-', 1, LENGTH (l_sub_parameter_id))
             || l_sub_parameter_id
             || '.'
             || l_parameter_type_id
             || '.'
             || l_interval_id
             || '.'
             || l_duration_id
             || '.'
             || l_version_id;
   END concat_ts_id;

   --------------------------------------------------------------------------------
   -- function get_time_zone_code
   --
   FUNCTION get_time_zone_code (p_time_zone_name IN VARCHAR2)
      RETURN NUMBER
   IS
      l_time_zone_code   NUMBER (10);
   BEGIN
      SELECT time_zone_code
        INTO l_time_zone_code
        FROM mv_time_zone
       WHERE time_zone_name = get_timezone (NVL (p_time_zone_name, 'UTC'));

      RETURN l_time_zone_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.raise ('INVALID_TIME_ZONE', p_time_zone_name);
   END get_time_zone_code;

   --------------------------------------------------------------------------------
   -- function get_time_zone_name
   --
   FUNCTION get_time_zone_name (p_time_zone_name IN VARCHAR2)
      RETURN VARCHAR2
   IS
      l_time_zone_name   VARCHAR2 (28);
   BEGIN
      SELECT z.time_zone_name
        INTO l_time_zone_name
        FROM mv_time_zone v, cwms_time_zone z
       WHERE upper(v.time_zone_name) = upper(get_timezone (p_time_zone_name))
             AND z.time_zone_code = v.time_zone_code;

      RETURN l_time_zone_name;
   END get_time_zone_name;

   --------------------------------------------------------------------------------
   -- function get_tz_usage_code
   --
   FUNCTION get_tz_usage_code (p_tz_usage_id IN VARCHAR2)
      RETURN NUMBER
   IS
      l_tz_usage_code   NUMBER (10);
   BEGIN
      SELECT tz_usage_code
        INTO l_tz_usage_code
        FROM cwms_tz_usage
       WHERE UPPER (tz_usage_id) = UPPER (NVL (p_tz_usage_id, 'Standard'));

      RETURN l_tz_usage_code;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.raise ('INVALID_ITEM',
                         p_tz_usage_id,
                         'CWMS time zone usage');
   END get_tz_usage_code;

   ----------------------------------------------------------------------------
   PROCEDURE DUMP (p_str IN VARCHAR2, p_len IN PLS_INTEGER DEFAULT 80)
   IS
      i   PLS_INTEGER;
   BEGIN
      -- Dump (put_line) a character string p_str in chunks of length p_len
      i := 1;

      WHILE i < LENGTH (p_str)
      LOOP
         DBMS_OUTPUT.put_line (SUBSTR (p_str, i, p_len));
         i := i + p_len;
      END LOOP;
   END DUMP;

   ----------------------------------------------------------------------------
   PROCEDURE create_view
   IS
      l_sel   VARCHAR2 (120);
      l_sql   VARCHAR2 (4000);

      CURSOR c1
      IS
         SELECT * FROM at_ts_table_properties;
   BEGIN
      -- Create the partitioned timeseries table view

      -- Note: start_date and end_date are coded as ANSI DATE literals

      -- CREATE OR REPLACE FORCE VIEW AV_TSV AS
      -- select ts_code, date_time, data_entry_date, value, quality,
      --   DATE '2000-01-01' start_date, DATE '2001-01-01' end_date from IOT_2000
      -- union all
      -- select ts_code, date_time, data_entry_date, value, quality,
      --   DATE '2001-01-01' start_date, DATE '2002-01-01' end_date from IOT_2001
      l_sql := 'create or replace force view av_tsv as ';
      l_sel :=
         'select ts_code, date_time, version_date, data_entry_date, value, quality_code, DATE ''';

      FOR rec IN c1
      LOOP
         IF c1%ROWCOUNT > 1
         THEN
            l_sql := l_sql || ' union all ';
         END IF;

         l_sql :=
               l_sql
            || l_sel
            || TO_CHAR (rec.start_date, 'yyyy-mm-dd')
            || ''' start_date, DATE '''
            || TO_CHAR (rec.end_date, 'yyyy-mm-dd')
            || ''' end_date from '
            || rec.table_name;
      END LOOP;

      cwms_util.DUMP (l_sql);
      EXECUTE IMMEDIATE l_sql;
   EXCEPTION
      -- ORA-24344: success with compilation error
      WHEN OTHERS
      THEN
         --dbms_output.put_line(SQLERRM);
         RAISE;
   END create_view;

   -------------------------------------------------------------------------------
   -- function split_text(...) overload to return a single element of the split
   --
   --
   FUNCTION split_text (p_text           IN VARCHAR2,
                        p_return_index   IN INTEGER,
                        p_separator      IN VARCHAR2 DEFAULT NULL,
                        p_max_split      IN INTEGER DEFAULT NULL)
      RETURN VARCHAR2
   IS
      l_str_tab        str_tab_t;
      l_return_index   INTEGER;
   BEGIN
      -- default index is first.
      IF p_return_index IS NULL
      THEN
         l_return_index := 1;
      ELSE
         l_return_index := p_return_index;
      END IF;

      --split the text.
      l_str_tab := split_text (p_text, p_separator, p_max_split);

      --error handle indexes.
      IF l_return_index <= 0 OR l_return_index > l_str_tab.COUNT
      THEN
         RETURN NULL;
      END IF;

      --grab element.
      RETURN l_str_tab (p_return_index);
   END split_text;

   -------------------------------------------------------------------------------
   -- function split_text(...)
   --
   --
   FUNCTION split_text (p_text        IN VARCHAR2,
                        p_separator   IN VARCHAR2 DEFAULT NULL,
                        p_max_split   IN INTEGER DEFAULT NULL)
      RETURN str_tab_t
      RESULT_CACHE
   IS
      l_str_tab        str_tab_t := str_tab_t ();
      l_str            VARCHAR2 (32767);
      l_field          VARCHAR2 (32767);
      l_pos            PLS_INTEGER;
      l_sep            VARCHAR2 (32767);
      l_sep_len        PLS_INTEGER;
      l_split_count    PLS_INTEGER := 0;
      l_count_splits   BOOLEAN;
   BEGIN
      IF p_text IS NOT NULL
      THEN
         l_count_splits := p_max_split IS NOT NULL;

         IF p_separator IS NULL
         THEN
            l_str := REGEXP_REPLACE (p_text, '\s+', ' ');
            l_sep := ' ';
         ELSE
            l_str := p_text;
            l_sep := p_separator;
         END IF;

         l_sep_len := LENGTH (l_sep);

         LOOP
            l_pos := INSTR (l_str, l_sep);

            IF l_count_splits AND l_split_count = p_max_split
            THEN
               l_pos := 0;
            END IF;

            IF l_pos = 0
            THEN
               l_field := l_str;
               l_str := NULL;
            ELSE
               l_split_count := l_split_count + 1;
               l_field := SUBSTR (l_str, 1, l_pos - 1);
               l_str := SUBSTR (l_str, l_pos + l_sep_len);
            END IF;

            l_str_tab.EXTEND;
            l_str_tab (l_str_tab.LAST) := l_field;
            EXIT WHEN l_pos = 0;

            IF l_str IS NULL
            THEN
               l_str_tab.EXTEND;
               l_str_tab (l_str_tab.LAST) := l_str;
               EXIT;
            END IF;
         END LOOP;
      END IF;

      RETURN l_str_tab;
   END split_text;

   -------------------------------------------------------------------------------
   -- function split_text(...)
   --
   --
   FUNCTION split_text (p_text        IN CLOB,
                        p_separator   IN VARCHAR2 DEFAULT NULL,
                        p_max_split   IN INTEGER DEFAULT NULL)
      RETURN str_tab_t
   IS
      l_clob                CLOB := p_text;
      l_rows                str_tab_t := str_tab_t ();
      l_new_rows            str_tab_t;
      l_buf                 VARCHAR2 (32767) := '';
      l_chunk               VARCHAR2 (4000);
      l_clob_offset         BINARY_INTEGER := 1;
      l_buf_offset          BINARY_INTEGER := 1;
      l_amount              BINARY_INTEGER;
      l_clob_len            BINARY_INTEGER;
      l_last                BINARY_INTEGER;
      l_done_reading        BOOLEAN;
      chunk_size   CONSTANT BINARY_INTEGER := 4000;
   BEGIN
      IF p_text IS NULL
      THEN
         RETURN NULL;
      END IF;

      l_clob_len := DBMS_LOB.getlength (l_clob);
      l_amount := LEAST (chunk_size, l_clob_len);
      DBMS_LOB.open (l_clob, DBMS_LOB.lob_readonly);

      IF l_amount > 0
      THEN
         LOOP
            DBMS_LOB.read (l_clob,
                           l_amount,
                           l_clob_offset,
                           l_chunk);
            l_clob_offset := l_clob_offset + l_amount;
            l_done_reading := l_clob_offset > l_clob_len;
            l_buf := l_buf || l_chunk;

            IF INSTR (l_buf, p_separator) > 0 OR l_done_reading
            THEN
               l_new_rows := split_text (l_buf, p_separator);

               FOR i IN 1 .. l_new_rows.COUNT - 1
               LOOP
                  l_rows.EXTEND;
                  l_rows (l_rows.LAST) := l_new_rows (i);
               END LOOP;

               l_buf := l_new_rows (l_new_rows.COUNT);

               IF l_done_reading
               THEN
                  l_rows.EXTEND;
                  l_rows (l_rows.LAST) := l_buf;
               END IF;
            END IF;

            EXIT WHEN l_done_reading;
         END LOOP;
      END IF;

      DBMS_LOB.close (l_clob);
      RETURN l_rows;
   END split_text;
   
   function split_text_regexp(
      p_text               in varchar2,
      p_separator          in varchar2,
      p_include_separators in varchar2 default 'F',
      p_match_parameter    in varchar2 default 'c',
      p_max_split          in integer default null)
      return str_tab_t
   is
      l_rows               str_tab_t := str_tab_t();
      l_start_pos          pls_integer;      -- start position of separator
      l_end_pos            pls_integer := 1; -- end position of separator plus 1
      l_len                pls_integer := length(p_text);
      l_include_separators boolean := is_true(p_include_separators);
   begin
      loop
         exit when l_end_pos > l_len;         
         l_start_pos := regexp_instr(p_text, p_separator, l_end_pos, 1, 0, p_match_parameter);
         if l_start_pos = 0 then
            l_rows.extend;
            l_rows(l_rows.count) := substr(p_text, l_end_pos);
            exit;
         end if;
         if l_start_pos > l_end_pos then
            l_rows.extend;
            l_rows(l_rows.count) := substr(p_text, l_end_pos, l_start_pos-l_end_pos+1);
         end if;
         l_end_pos := regexp_instr(p_text, p_separator, l_start_pos, 1, 1, p_match_parameter);
         if l_include_separators then
            l_rows.extend;
            l_rows(l_rows.count) := substr(p_text, l_start_pos, l_end_pos-l_start_pos);
         end if;
      end loop; 
      return l_rows;
   end split_text_regexp;            

   -------------------------------------------------------------------------------
   -- function join_text(...)
   --
   --
   FUNCTION join_text (p_text_tab    IN str_tab_t,
                       p_separator   IN VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2
   IS
      l_text   VARCHAR2 (32767) := NULL;
   BEGIN
      FOR i IN 1 .. p_text_tab.COUNT
      LOOP
         IF i > 1
         THEN
            l_text := l_text || p_separator;
         END IF;

         l_text := l_text || p_text_tab (i);
      END LOOP;

      RETURN l_text;
   END join_text;

   --------------------------------------------------------------------------------
   -- procedure format_xml(...)
   --
   PROCEDURE format_xml (p_xml_clob IN OUT NOCOPY CLOB, p_indent IN VARCHAR2)
   IS
      l_lines              str_tab_t;
      l_level              BINARY_INTEGER := 0;
      l_len                BINARY_INTEGER := LENGTH (NVL (p_indent, ''));
      l_newline   CONSTANT VARCHAR2 (1) := CHR (10);

      PROCEDURE write_line (p_line IN VARCHAR2)
      IS
      BEGIN
         IF l_len > 0
         THEN
            FOR i IN 1 .. l_level
            LOOP
               DBMS_LOB.writeappend (p_xml_clob, l_len, p_indent);
            END LOOP;
         END IF;

         DBMS_LOB.writeappend (p_xml_clob,
                               LENGTH (p_line) + 1,
                               p_line || l_newline);
      END;
   BEGIN
      IF p_xml_clob IS NOT NULL
      THEN
         p_xml_clob := REPLACE (p_xml_clob, '<', l_newline || '<');
         p_xml_clob := REPLACE (p_xml_clob, '>', '>' || l_newline);
         p_xml_clob := REPLACE (p_xml_clob, l_newline || l_newline, l_newline);
         l_lines := split_text (p_xml_clob, l_newline);
         DBMS_LOB.open (p_xml_clob, DBMS_LOB.lob_readwrite);
         DBMS_LOB.TRIM (p_xml_clob, 0);

         FOR i IN l_lines.FIRST .. l_lines.LAST
         LOOP
            FOR once IN 1 .. 1
            LOOP
               EXIT WHEN l_lines (i) IS NULL;
               l_lines (i) := TRIM (l_lines (i));
               EXIT WHEN LENGTH (l_lines (i)) = 0;

               IF INSTR (l_lines (i), '<') = 1
               THEN
                  IF INSTR (l_lines (i), '<!--') = 1
                  THEN
                     write_line (l_lines (i));
                  ELSIF INSTR (l_lines (i), '</') = 1
                  THEN
                     l_level := l_level - 1;
                     write_line (l_lines (i));
                  ELSE
                     write_line (l_lines (i));

                     IF INSTR (l_lines (i), '<xml?') != 1
                        AND INSTR (l_lines (i), '/>', -1) !=
                               LENGTH (l_lines (i)) - 1
                     THEN
                        l_level := l_level + 1;
                     END IF;
                  END IF;
               ELSE
                  write_line (l_lines (i));
               END IF;
            END LOOP;
         END LOOP;

         DBMS_LOB.close (p_xml_clob);
      END IF;
   END format_xml;

   -------------------------------------------------------------------------------
   -- function parse_clob_recordset(...)
   --
   --
   function parse_clob_recordset (p_clob in clob)
      return str_tab_tab_t
   is
      l_tab       str_tab_tab_t;
      l_row       str_tab_t;
      l_row_pos   integer;
      l_row_start integer;         
      l_col_pos   integer;
      l_col_start integer;
      l_row_done  boolean;
      l_tab_done  boolean;         
   begin
      if p_clob is not null then
         l_tab := str_tab_tab_t();
         l_row_start := 1;
         loop         
            l_tab_done := false;
            l_row_pos := instr(p_clob, record_separator, l_row_start, 1);
            if l_row_pos = 0 then
               l_tab_done := true;
               l_row_pos := dbms_lob.getlength(p_clob);
            end if;
            l_col_start := l_row_start;
            l_row := str_tab_t();
            loop    
               l_row_done := false;
               l_col_pos := instr(p_clob, field_separator, l_col_start, 1);
               if l_col_pos = 0 or l_col_pos > l_row_pos then
                  l_row_done := true;
                  if l_col_pos = 0 then
                     l_col_pos := dbms_lob.getlength(p_clob);
                  else
                     l_col_pos := l_row_pos;
                  end if;
               end if;
               l_row.extend;
               l_row(l_row.count) := dbms_lob.substr(p_clob, l_col_pos - l_col_start, l_col_start);
               l_col_start := l_col_pos + 1;                                                       
               exit when l_row_done;
            end loop;
            l_tab.extend;
            l_tab(l_tab.count) := l_row;
            l_row_start := l_row_pos + 1;
            exit when l_tab_done;
         end loop; 
      end if;
      return l_tab;
   end parse_clob_recordset;

   -------------------------------------------------------------------------------
   -- function parse_string_recordset(...)
   --
   --
   FUNCTION parse_string_recordset (p_string IN VARCHAR2)
      RETURN str_tab_tab_t
   IS
      l_rows   str_tab_t;
      l_tab    str_tab_tab_t := str_tab_tab_t ();
   BEGIN
      IF p_string IS NULL
      THEN
         RETURN NULL;
      END IF;

      l_rows := split_text (p_string, record_separator);

      IF l_rows.COUNT > 0
      THEN
         FOR i IN l_rows.FIRST .. l_rows.LAST
         LOOP
            l_tab.EXTEND;
            l_tab (l_tab.LAST) := split_text (l_rows (i), field_separator);
         END LOOP;
      END IF;

      RETURN l_tab;
   END parse_string_recordset;

   --------------------------------------------------------------------
   -- Return UTC timestamp for specified ISO 8601 string
   --
   FUNCTION TO_TIMESTAMP (p_iso_str IN VARCHAR2)
      RETURN TIMESTAMP
   IS
      l_yr                     VARCHAR2 (5);
      l_mon                    VARCHAR2 (2) := '01';
      l_day                    VARCHAR2 (2) := '01';
      l_hr                     VARCHAR2 (2) := '00';
      l_min                    VARCHAR2 (2) := '00';
      l_sec                    VARCHAR2 (8) := '00.0';
      l_tz                     VARCHAR2 (32) := '+00:00';
      l_time                   VARCHAR2 (32);
      l_parts                  str_tab_t;
      l_ts                     TIMESTAMP;
      l_offset                 INTERVAL DAY (9) TO SECOND (9);
      l_iso_pattern   CONSTANT VARCHAR2 (71)
         := '-?\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:(\d{2}([.]\d+)?))?([-+]\d{2}:\d{2}|Z)?' ;
      l_str                    VARCHAR2 (64) := strip (p_iso_str);
      l_pos                    BINARY_INTEGER;
      l_add_day                BOOLEAN := FALSE;
   BEGIN
      IF REGEXP_INSTR (l_str, l_iso_pattern) != 1
         OR REGEXP_INSTR (l_str,
                          l_iso_pattern,
                          1,
                          1,
                          1) != LENGTH (l_str) + 1
      THEN
         if length(l_str) = 10 then
            return to_timestamp(l_str||'T00:00');
         end if;
         cwms_err.raise ('INVALID_ITEM', l_str, 'dateTime-formatted string');
      END IF;

      l_pos :=
         REGEXP_INSTR (l_str,
                       '-?\d{4}',
                       1,
                       1,
                       1);
      l_yr := SUBSTR (l_str, 1, l_pos - 1);
      l_str := SUBSTR (l_str, l_pos + 1);
      l_mon := SUBSTR (l_str, 1, 2);
      l_str := SUBSTR (l_str, 4);
      l_day := SUBSTR (l_str, 1, 2);
      l_str := SUBSTR (l_str, 4);
      l_hr := SUBSTR (l_str, 1, 2);
      l_str := SUBSTR (l_str, 4);
      l_min := SUBSTR (l_str, 1, 2);
      l_str := SUBSTR (l_str, 3);

      IF SUBSTR (l_str, 1, 1) = ':'
      THEN
         l_pos :=
            REGEXP_INSTR (l_str,
                          ':\d{2}([.]\d+)?',
                          1,
                          1,
                          1);
         l_sec := SUBSTR (l_str, 2, l_pos - 2);
         l_str := SUBSTR (l_str, l_pos);
      END IF;

      IF LENGTH (l_str) > 0
      THEN
         l_tz := l_str;
      END IF;

      IF l_hr = '24'
      THEN
         l_add_day := TRUE;
         l_hr := '00';
      END IF;

      l_time :=
            l_yr
         || '-'
         || l_mon
         || '-'
         || l_day
         || 'T'
         || l_hr
         || ':'
         || l_min
         || ':'
         || l_sec;

      ----------------------------------------------------------------------
      -- use select to avoid namespace collision with CWMS_UTIL functions --
      ----------------------------------------------------------------------
      SELECT TO_TIMESTAMP (l_time, 'YYYY-MM-DD"T"HH24:MI:SS.FF')
        INTO l_ts
        FROM DUAL;

      IF l_add_day
      THEN
         l_ts := l_ts + INTERVAL '1 00:00:00' DAY TO SECOND;
      END IF;

      --------------------------------------------------------------
      -- for some reason the TZH:TZM format only works on TO_CHAR --
      --------------------------------------------------------------
      l_tz := REPLACE (l_tz, 'Z', '+00:00');
      l_parts := split_text (SUBSTR (l_tz, 2), ':');
      l_hr := l_parts (1);
      l_min := l_parts (2);
      l_offset := TO_DSINTERVAL ('0 ' || l_hr || ':' || l_min || ':00');

      IF SUBSTR (l_tz, 1, 1) = '-'
      THEN
         l_ts := l_ts + l_offset;
      ELSE
         l_ts := l_ts - l_offset;
      END IF;

      RETURN l_ts;
   END TO_TIMESTAMP;

   --------------------------------------------------------------------
   -- Return UTC timestamp for specified Java milliseconds
   --
   FUNCTION TO_TIMESTAMP (p_millis IN NUMBER)
      RETURN TIMESTAMP
   IS
      l_millis     NUMBER := ABS (p_millis);
      l_day        NUMBER;
      l_hour       NUMBER;
      l_min        NUMBER;
      l_sec        NUMBER;
      l_negative   BOOLEAN := p_millis < 0;
      l_interval   INTERVAL DAY (9) TO SECOND (9);
   BEGIN
      l_day := TRUNC (l_millis / 86400000);
      l_millis := l_millis - (l_day * 86400000);
      l_hour := TRUNC (l_millis / 3600000);
      l_millis := l_millis - (l_hour * 3600000);
      l_min := TRUNC (l_millis / 60000);
      l_millis := l_millis - (l_min * 60000);
      l_sec := TRUNC (l_millis / 1000);
      l_millis := l_millis - (l_sec * 1000);
      l_interval :=
         TO_DSINTERVAL (
               ''
            || l_day
            || ' '
            || TO_CHAR (l_hour, '00')
            || ':'
            || TO_CHAR (l_min, '00')
            || ':'
            || TO_CHAR (l_sec, '00')
            || '.'
            || TO_CHAR (l_millis, '000'));

      IF l_negative
      THEN
         RETURN epoch - l_interval;
      ELSE
         RETURN epoch + l_interval;
      END IF;
   END TO_TIMESTAMP;

   --------------------------------------------------------------------
   -- Return Java milliseconds for a specified UTC timestamp.
   --
   FUNCTION to_millis (p_timestamp IN TIMESTAMP)
      RETURN NUMBER
   IS
      l_intvl    INTERVAL DAY (9) TO SECOND (9);
      l_millis   NUMBER;
   BEGIN
      l_intvl := p_timestamp - epoch;
      l_millis :=
         TRUNC (
              EXTRACT (DAY FROM l_intvl) * 86400000
            + EXTRACT (HOUR FROM l_intvl) * 3600000
            + EXTRACT (MINUTE FROM l_intvl) * 60000
            + EXTRACT (SECOND FROM l_intvl) * 1000);
      RETURN l_millis;
   END to_millis;

   --------------------------------------------------------------------
   -- Return Java milliseconds for current time.
   --
   FUNCTION current_millis
      RETURN NUMBER
   IS
   BEGIN
      RETURN to_millis (SYSTIMESTAMP AT TIME ZONE 'UTC');
   END current_millis;

   --------------------------------------------------------------------
   -- Return Java microseconds for a specified UTC timestamp.
   --
   FUNCTION to_micros (p_timestamp IN TIMESTAMP)
      RETURN NUMBER
   IS
      l_intvl    INTERVAL DAY (9) TO SECOND (9);
      l_micros   NUMBER;
   BEGIN
      l_intvl := p_timestamp - epoch;
      l_micros :=
         TRUNC (
              EXTRACT (DAY FROM l_intvl) * 86400000000
            + EXTRACT (HOUR FROM l_intvl) * 3600000000
            + EXTRACT (MINUTE FROM l_intvl) * 60000000
            + EXTRACT (SECOND FROM l_intvl) * 1000000);
      RETURN l_micros;
   END to_micros;

   --------------------------------------------------------------------
   -- Return Java microseconds for current time.
   --
   FUNCTION current_micros
      RETURN NUMBER
   IS
   BEGIN
      RETURN to_micros (SYSTIMESTAMP AT TIME ZONE 'UTC');
   END current_micros;


   FUNCTION get_ts_interval (p_cwms_ts_code IN NUMBER)
      RETURN NUMBER
      RESULT_CACHE
   IS
      l_ts_interval   NUMBER;
   BEGIN
      SELECT a.interval
        INTO l_ts_interval
        FROM cwms_interval a, at_cwms_ts_spec b
       WHERE b.interval_code = a.interval_code AND b.ts_code = p_cwms_ts_code;

      RETURN l_ts_interval;
   END get_ts_interval;

   FUNCTION get_unit_id (p_unit_or_alias   IN VARCHAR2,
                         p_office_id       IN VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2
   IS              
      l_unit_id_in    VARCHAR2 (16) := parse_unit(p_unit_or_alias);
      l_unit_id_out   VARCHAR2 (16);
      l_office_code   NUMBER (10) := get_db_office_code (p_office_id);
   BEGIN
      BEGIN
         SELECT unit_id
           INTO l_unit_id_out
           FROM cwms_unit
          WHERE unit_id = l_unit_id_in;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            NULL;
      END;

      IF l_unit_id_out IS NULL
      THEN
         BEGIN
            SELECT u.unit_id
              INTO l_unit_id_out
              FROM at_unit_alias ua, cwms_unit u
             WHERE ua.alias_id = l_unit_id_in
                   AND ua.db_office_code IN
                          (db_office_code_all, l_office_code)
                   AND u.unit_code = ua.unit_code;
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               NULL;
         END;
      END IF;

      IF l_unit_id_out IS NULL
      THEN
         BEGIN
            SELECT unit_id
              INTO l_unit_id_out
              FROM cwms_unit
             WHERE UPPER (unit_id) = (l_unit_id_in);
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      IF l_unit_id_out IS NULL
      THEN
         BEGIN
            SELECT u.unit_id
              INTO l_unit_id_out
              FROM at_unit_alias ua, cwms_unit u
             WHERE UPPER (ua.alias_id) = UPPER (l_unit_id_in)
                   AND ua.db_office_code IN
                          (db_office_code_all, l_office_code)
                   AND u.unit_code = ua.unit_code;
         EXCEPTION
            WHEN OTHERS
            THEN
               NULL;
         END;
      END IF;

      RETURN l_unit_id_out;
   END get_unit_id;

   FUNCTION get_unit_id2 (p_unit_code IN VARCHAR2)
      RETURN VARCHAR2
      RESULT_CACHE
   IS
      l_unit_id   VARCHAR2 (16);
   BEGIN
      SELECT unit_id
        INTO l_unit_id
        FROM cwms_unit
       WHERE unit_code = p_unit_code;

      RETURN l_unit_id;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.raise ('INVALID_ITEM', p_unit_code, 'CWMS unit');
   END get_unit_id2;

   PROCEDURE get_valid_units (p_valid_units       OUT SYS_REFCURSOR,
                              p_parameter_id   IN     VARCHAR2 DEFAULT NULL)
   IS
   BEGIN
      IF p_parameter_id IS NULL
      THEN
         OPEN p_valid_units FOR
            SELECT a.unit_id
              FROM cwms_unit a;
      ELSE
         OPEN p_valid_units FOR
            SELECT a.unit_id
              FROM cwms_unit a
             WHERE abstract_param_code =
                      (SELECT abstract_param_code
                         FROM cwms_base_parameter
                        WHERE UPPER (base_parameter_id) =
                                 UPPER (get_base_id (p_parameter_id)));
      END IF;
   END get_valid_units;

   /* get_valid_unit_id return the properly cased unit_id for p_unit_id.
    */


   FUNCTION get_valid_unit_id (p_unit_id        IN VARCHAR2,
                               p_parameter_id   IN VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2
   IS
      l_unit_id   VARCHAR2 (16);
   BEGIN
      BEGIN
         SELECT unit_id
           INTO l_unit_id
           FROM TABLE (get_valid_units_tab (p_parameter_id))
          WHERE unit_id = p_unit_id;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            BEGIN
               SELECT unit_id
                 INTO l_unit_id
                 FROM TABLE (get_valid_units_tab (p_parameter_id))
                WHERE UPPER (unit_id) = UPPER (p_unit_id);
            EXCEPTION
               WHEN NO_DATA_FOUND
               THEN
                  IF p_parameter_id IS NULL
                  THEN
                     raise_application_error (
                        -20102,
                           'The unit: '
                        || TRIM (p_unit_id)
                        || ' is not a recognized CWMS Database unit.',
                        TRUE);
                  ELSE
                     raise_application_error (
                        -20102,
                           'The unit: '
                        || TRIM (p_unit_id)
                        || ' is not a recognized CWMS Database unit for the '
                        || TRIM (p_parameter_id)
                        || ' Parameter_ID.',
                        TRUE);
                  END IF;
               WHEN TOO_MANY_ROWS
               THEN
                  raise_application_error (
                     -20102,
                        'The unit: '
                     || TRIM (p_unit_id)
                     || ' has multiple matches in the CWMS Database.'
                     || ' Please specify the Parameter_ID and/or use the'
                     || ' exact letter casing for the desired unit.',
                     TRUE);
            END;
      END;

      RETURN l_unit_id;
   END get_valid_unit_id;

   FUNCTION get_valid_units_tab (p_parameter_id IN VARCHAR2 DEFAULT NULL)
      RETURN cat_unit_tab_t
      PIPELINED
   IS
      l_query_cursor   SYS_REFCURSOR;
      l_output_row     cat_unit_rec_t;
   BEGIN
      get_valid_units (l_query_cursor, p_parameter_id);

      LOOP
         FETCH l_query_cursor INTO l_output_row;

         EXIT WHEN l_query_cursor%NOTFOUND;
         PIPE ROW (l_output_row);
      END LOOP;

      CLOSE l_query_cursor;
   END get_valid_units_tab;

   FUNCTION get_unit_code (p_unit_id             IN VARCHAR2,
                           p_abstract_param_id   IN VARCHAR2 DEFAULT NULL,
                           p_db_office_id        IN VARCHAR2 DEFAULT NULL)
      RETURN NUMBER
   IS
      l_unit_code        NUMBER;
      l_db_office_code   VARCHAR2 (16) := get_db_office_code (p_db_office_id);
   BEGIN
      IF p_abstract_param_id IS NULL
      THEN
         BEGIN
            SELECT unit_code
              INTO l_unit_code
              FROM av_unit
             WHERE unit_id = TRIM (p_unit_id)
                   AND db_office_code IN (l_db_office_code, 53);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               cwms_err.raise ('INVALID_ITEM',
                               TRIM (p_unit_id),
                               'unit id. Note units are case senstive.');
            WHEN TOO_MANY_ROWS
            THEN
               cwms_err.raise (
                  'ERROR',
                     'More than one entry was found for the unit: "'
                  || TRIM (p_unit_id)
                  || '". Try specifying the p_abstract_param for this unit.');
         END;
      ELSE
         BEGIN
            SELECT unit_code
              INTO l_unit_code
              FROM av_unit
             WHERE unit_id = TRIM (p_unit_id)
                   AND db_office_code IN (l_db_office_code, 53)
                   AND abstract_param_code =
                          (SELECT abstract_param_code
                             FROM cwms_abstract_parameter
                            WHERE abstract_param_id =
                                     UPPER (TRIM (p_abstract_param_id)));
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               cwms_err.raise ('INVALID_ITEM',
                               TRIM (p_unit_id),
                               'unit id. Note units are case senstive.');
         END;
      END IF;

      RETURN l_unit_code;
   END get_unit_code;

   FUNCTION get_ts_group_code (p_ts_category_id   IN VARCHAR2,
                               p_ts_group_id      IN VARCHAR2,
                               p_db_office_code   IN NUMBER)
      RETURN NUMBER
   IS
      l_ts_group_code   NUMBER;
   BEGIN
      IF p_db_office_code IS NULL
      THEN
         cwms_err.raise ('ERROR', 'p_db_office_code cannot be null.');
      END IF;

      --
      IF p_ts_category_id IS NOT NULL AND p_ts_group_id IS NOT NULL
      THEN
         BEGIN
            SELECT ts_group_code
              INTO l_ts_group_code
              FROM at_ts_group a, at_ts_category b
             WHERE a.ts_category_code = b.ts_category_code
                   AND UPPER (b.ts_category_id) =
                          UPPER (TRIM (p_ts_category_id))
                   AND b.db_office_code IN
                          (p_db_office_code, cwms_util.db_office_code_all)
                   AND UPPER (a.ts_group_id) = UPPER (TRIM (p_ts_group_id))
                   AND a.db_office_code IN
                          (p_db_office_code, cwms_util.db_office_code_all);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               cwms_err.raise (
                  'ERROR',
                     'Could not find '
                  || TRIM (p_ts_category_id)
                  || '-'
                  || TRIM (p_ts_group_id)
                  || ' category-group combination');
         END;
      ELSIF (p_ts_category_id IS NOT NULL AND p_ts_group_id IS NULL)
            OR (p_ts_category_id IS NULL AND p_ts_group_id IS NOT NULL)
      THEN
         cwms_err.raise (
            'ERROR',
            'The ts_category_id and ts_group_id is not a valid combination');
      END IF;

      RETURN l_ts_group_code;
   END get_ts_group_code;

   FUNCTION get_loc_group_code (p_loc_category_id   IN VARCHAR2,
                                p_loc_group_id      IN VARCHAR2,
                                p_db_office_code    IN NUMBER)
      RETURN NUMBER
   IS
      l_loc_group_code   NUMBER;
   BEGIN
      IF p_db_office_code IS NULL
      THEN
         cwms_err.raise ('ERROR', 'p_db_office_code cannot be null.');
      END IF;

      --
      IF p_loc_category_id IS NOT NULL AND p_loc_group_id IS NOT NULL
      THEN
         BEGIN
            SELECT loc_group_code
              INTO l_loc_group_code
              FROM at_loc_group a, at_loc_category b
             WHERE a.loc_category_code = b.loc_category_code
                   AND UPPER (b.loc_category_id) =
                          UPPER (TRIM (p_loc_category_id))
                   AND b.db_office_code IN
                          (p_db_office_code, cwms_util.db_office_code_all)
                   AND UPPER (a.loc_group_id) = UPPER (TRIM (p_loc_group_id))
                   AND a.db_office_code IN
                          (p_db_office_code, cwms_util.db_office_code_all);
         EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
               cwms_err.raise (
                  'ERROR',
                     'Could not find '
                  || TRIM (p_loc_category_id)
                  || '-'
                  || TRIM (p_loc_group_id)
                  || ' category-group combination');
         END;
      ELSIF (p_loc_category_id IS NOT NULL AND p_loc_group_id IS NULL)
            OR (p_loc_category_id IS NULL AND p_loc_group_id IS NOT NULL)
      THEN
         cwms_err.raise (
            'ERROR',
            'The loc_category_id and loc_group_id is not a valid combination');
      END IF;

      RETURN l_loc_group_code;
   END get_loc_group_code;

   FUNCTION get_loc_group_code (p_loc_category_id   IN VARCHAR2,
                                p_loc_group_id      IN VARCHAR2,
                                p_db_office_id      IN VARCHAR2)
      RETURN NUMBER
   IS
   BEGIN
      RETURN get_loc_group_code (
                p_loc_category_id   => p_loc_category_id,
                p_loc_group_id      => p_loc_group_id,
                p_db_office_code    => cwms_util.get_db_office_code (
                                         p_db_office_id));
   END get_loc_group_code;

   --------------------------------------------------------------------------------
   -- get_user_id uses either sys_context or the apex authenticated user id. -
   --
   -- The "v" function is installed with apex - so apex needs to be installed     -
   -- for this package to compile.
   --------------------------------------------------------------------------------
   FUNCTION get_user_id
      RETURN VARCHAR2
   IS
      l_user_id   VARCHAR2 (31);
   BEGIN
      IF v ('APP_USER') != 'APEX_PUBLIC_USER' AND v ('APP_USER') IS NOT NULL
      THEN
         l_user_id := v ('APP_USER');
      ELSIF SYS_CONTEXT ('CWMS_ENV', 'CWMS_USER') IS NOT NULL
      THEN
         l_user_id := SYS_CONTEXT ('CWMS_ENV', 'CWMS_USER'); 
      ELSE
	 l_user_id := USER;
      END IF;

      RETURN UPPER (l_user_id);
   END get_user_id;

   PROCEDURE user_display_unit (
      p_unit_id           OUT VARCHAR2,
      p_value_out         OUT NUMBER,
      p_parameter_id   IN     VARCHAR2,
      p_value_in       IN     NUMBER DEFAULT NULL,
      p_user_id        IN     VARCHAR2 DEFAULT NULL,
      p_office_id      IN     VARCHAR2 DEFAULT NULL)
   IS
      l_unit_system           VARCHAR2 (2);
      l_user_id               VARCHAR2 (31) := UPPER (NVL (p_user_id, get_user_id));
      l_office_id             VARCHAR2 (16) := get_db_office_id (p_office_id);
      l_base_parameter_id     VARCHAR2 (16) := get_base_id (p_parameter_id);
      l_office_code           NUMBER := get_db_office_code (p_office_id);
      l_unit_code             NUMBER;
      l_base_parameter_code   NUMBER;
   BEGIN
      p_unit_id := NULL;
      p_value_out := NULL;
      --
      -- get preferred unit system or default to 'SI'
      --
      l_unit_system :=
         cwms_properties.get_property ('Pref_User.' || l_user_id,
                                       'Unit_System',
                                       cwms_properties.get_property (
                                          'Pref_Office',
                                          'Unit_System',
                                          'SI',
                                          l_office_id),
                                       l_office_id);

      --
      -- get display unit for parameter in preferred unit system
      --
      BEGIN
         SELECT base_parameter_code,
                CASE l_unit_system
                   WHEN 'SI' THEN display_unit_code_si
                   WHEN 'EN' THEN display_unit_code_en
                END
           INTO l_base_parameter_code, l_unit_code
           FROM cwms_base_parameter
          WHERE UPPER (base_parameter_id) = UPPER (l_base_parameter_id);
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            cwms_err.raise ('INVALID_PARAM_ID', p_parameter_id);
      END;

      SELECT unit_id
        INTO p_unit_id
        FROM cwms_unit
       WHERE unit_code = l_unit_code;

      --
      -- convert the specified value from storage unit
      --
      IF p_value_in IS NOT NULL
      THEN
         SELECT p_value_in * cuc.factor + cuc.offset
           INTO p_value_out
           FROM cwms_unit_conversion cuc, cwms_base_parameter bp
          WHERE     bp.base_parameter_code = l_base_parameter_code
                AND cuc.from_unit_code = bp.unit_code
                AND cuc.to_unit_code = l_unit_code;
      END IF;
   END user_display_unit;

   FUNCTION get_interval_string (p_interval IN NUMBER)
      RETURN VARCHAR2
   IS
      --   public static final String YEAR_TIME_INTERVAL  = "yr";
      --   public static final String MONTH_TIME_INTERVAL = "mo";
      --   public static final String WEEK_TIME_INTERVAL  = "wk";
      --   public static final String DAY_TIME_INTERVAL = "dy";
      --   public static final String HOUR_TIME_INTERVAL  = "hr";
      --   public static final String MINUTE_TIME_INTERVAL = "mi";
      l_num_yr    NUMBER;
      l_num_mo    NUMBER;
      l_num_dy    NUMBER;
      l_num_hr    NUMBER;
      l_num_mi    NUMBER;
      l_min_rem   NUMBER;
      l_lvl       VARCHAR2 (2) := NULL;
      l_return    VARCHAR2 (64) := NULL;
   BEGIN
      --
      l_num_yr := TRUNC (p_interval / CWMS_TS.MIN_IN_YR);
      l_min_rem := l_num_yr * CWMS_TS.MIN_IN_YR;

      IF l_num_yr > 0
      THEN
         l_return := l_num_yr || 'yr';
         l_lvl := 'YR';
      END IF;

      --
      l_num_mo := TRUNC ( (p_interval - l_min_rem) / CWMS_TS.MIN_IN_MO);
      l_min_rem := l_min_rem + l_num_mo * CWMS_TS.MIN_IN_MO;

      CASE
         WHEN l_lvl IS NULL
         THEN
            IF l_num_mo > 0
            THEN
               l_return := l_num_mo || 'mo';
               l_lvl := 'MO';
            END IF;
         ELSE
            l_return := l_return || l_num_mo || 'mo';
      END CASE;

      --
      --      l_num_wk := TRUNC ( (p_interval - l_min_rem) / CWMS_TS.MIN_IN_WK);
      --      l_min_rem := l_min_rem + l_num_wk * CWMS_TS.MIN_IN_WK;
      --
      --      CASE
      --         WHEN l_lvl IS NULL
      --         THEN
      --            IF l_num_wk > 0
      --            THEN
      --               l_return := l_num_wk || 'wk';
      --               l_lvl := 'WK';
      --            END IF;
      --         ELSE
      --            l_return := l_return || l_num_wk || 'wk';
      --      END CASE;

      --
      l_num_dy := TRUNC ( (p_interval - l_min_rem) / CWMS_TS.MIN_IN_DY);
      l_min_rem := l_min_rem + l_num_dy * CWMS_TS.MIN_IN_DY;

      CASE
         WHEN l_lvl IS NULL
         THEN
            IF l_num_dy > 0
            THEN
               l_return := l_num_dy || 'dy';
               l_lvl := 'DY';
            END IF;
         ELSE
            l_return := l_return || l_num_dy || 'dy';
      END CASE;

      --
      l_num_hr := TRUNC ( (p_interval - l_min_rem) / CWMS_TS.MIN_IN_HR);
      l_min_rem := l_min_rem + l_num_hr * CWMS_TS.MIN_IN_HR;

      CASE
         WHEN l_lvl IS NULL
         THEN
            IF l_num_hr > 0
            THEN
               l_return := l_num_hr || 'hr';
               l_lvl := 'HR';
            END IF;
         ELSE
            l_return := l_return || l_num_hr || 'hr';
      END CASE;

      --
      l_num_mi := p_interval - l_min_rem;
      l_return := l_return || l_num_mi || 'mi';
      --



      RETURN l_return;
   END get_interval_string;

   FUNCTION get_user_display_unit (p_parameter_id   IN VARCHAR2,
                                   p_user_id        IN VARCHAR2 DEFAULT NULL,
                                   p_office_id      IN VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2
   IS
      l_unit_id     VARCHAR2 (16);
      l_value_out   NUMBER;
   BEGIN
      user_display_unit (l_unit_id,
                         l_value_out,
                         p_parameter_id,
                         1.0,
                         p_user_id,
                         p_office_id);

      RETURN l_unit_id;
   END get_user_display_unit;

   ----------------------------------------------------------------------------

   FUNCTION get_default_units (p_parameter_id   IN VARCHAR2,
                               p_unit_system    IN VARCHAR2 DEFAULT 'SI')
      RETURN VARCHAR2
   AS
      l_default_units     VARCHAR2 (16);
      l_base_param_code   NUMBER;
   BEGIN
      IF p_parameter_id IS NULL
      THEN
         RETURN NULL;
      END IF;

      l_base_param_code := get_base_param_code (get_base_id (p_parameter_id));

      IF UPPER (p_unit_system) = 'SI'
      THEN
         SELECT a.unit_id
           INTO l_default_units
           FROM cwms_unit a, cwms_base_parameter b
          WHERE a.unit_code = b.display_unit_code_si
                AND b.base_parameter_code = l_base_param_code;
      ELSIF UPPER (p_unit_system) = 'EN'
      THEN
         SELECT a.unit_id
           INTO l_default_units
           FROM cwms_unit a, cwms_base_parameter b
          WHERE a.unit_code = b.display_unit_code_en
                AND b.base_parameter_code = l_base_param_code;
      ELSE
         cwms_err.raise ('INVALID_ITEM',
                         p_unit_system,
                         'Unit System. Use either SI or EN');
      END IF;

      RETURN l_default_units;
   END get_default_units;

   FUNCTION get_db_unit_code (p_parameter_id IN VARCHAR2)
      RETURN NUMBER
   IS
      l_unit_code   NUMBER (10);
   BEGIN
      SELECT unit_code
        INTO l_unit_code
        FROM cwms_base_parameter
       WHERE base_parameter_id = get_base_id (p_parameter_id);

      RETURN l_unit_code;
   END get_db_unit_code;

   FUNCTION get_db_unit_code (p_parameter_code IN NUMBER)
      RETURN NUMBER
   IS
      l_unit_code   NUMBER (10);
   BEGIN
      SELECT bp.unit_code
        INTO l_unit_code
        FROM cwms_base_parameter bp, at_parameter p
       WHERE p.parameter_code = p_parameter_code
             AND bp.base_parameter_code = p.base_parameter_code;

      RETURN l_unit_code;
   END get_db_unit_code;

   FUNCTION convert_to_db_units (p_value          IN BINARY_DOUBLE,
                                 p_parameter_id   IN VARCHAR2,
                                 p_unit_id        IN VARCHAR2)
      RETURN BINARY_DOUBLE
   IS
      l_factor   BINARY_DOUBLE;
      l_offset   BINARY_DOUBLE;
   BEGIN
      SELECT uc.factor, uc.offset
        INTO l_factor, l_offset
        FROM cwms_unit_conversion uc, cwms_base_parameter bp
       WHERE     bp.base_parameter_id = get_base_id (p_parameter_id)
             AND uc.to_unit_code = bp.unit_code
             AND uc.from_unit_id = p_unit_id;

      RETURN p_value * l_factor + l_offset;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         cwms_err.raise (
            'ERROR',
               'Cannot convert parameter '
            || p_parameter_id
            || ' in unit '
            || p_unit_id
            || ' to database unit.');
   END convert_to_db_units;

   FUNCTION get_factor_and_offset (p_from_unit_id   IN VARCHAR2,
                                   p_to_unit_id     IN VARCHAR2)
      RETURN double_tab_t
      RESULT_CACHE
   IS
      l_factor_and_offset   double_tab_t := double_tab_t ();
   BEGIN
      l_factor_and_offset.EXTEND (2);

      SELECT factor, offset
        INTO l_factor_and_offset (1), l_factor_and_offset (2)
        FROM cwms_unit_conversion
       WHERE from_unit_id = get_unit_id (p_from_unit_id)
             AND to_unit_id = get_unit_id (p_to_unit_id);

      RETURN l_factor_and_offset;
   END get_factor_and_offset;

   function convert_units (
      p_value          in binary_double,
      p_from_unit_id   in varchar2,
      p_to_unit_id     in varchar2)
      return binary_double
      result_cache
   is
      l_factor    cwms_unit_conversion.factor%type;
      l_offset    cwms_unit_conversion.offset%type;
      l_function  cwms_unit_conversion.function%type;
      l_converted binary_double;
   begin
      if p_value is not null then
         select factor,
                offset,
                function
           into l_factor,
                l_offset,
                l_function
           from cwms_unit_conversion
          where from_unit_id = cwms_util.get_unit_id(p_from_unit_id)
            and to_unit_id = cwms_util.get_unit_id(p_to_unit_id);
            
         if l_factor is null then
            l_converted := cwms_util.eval_expression(l_function, double_tab_t(p_value));
         else
            l_converted := p_value * l_factor + l_offset;
         end if;
      end if;
      return l_converted;
   exception
      when no_data_found
      then
         cwms_err.raise (
            'ERROR',
            'Cannot convert from unit '
            || p_from_unit_id
            || ' to unit '
            || p_to_unit_id);
   end convert_units;

   function convert_units (
      p_value            in binary_double,
      p_from_unit_code   in number,
      p_to_unit_code     in number)
      return binary_double
      result_cache
   is
      l_factor    cwms_unit_conversion.factor%type;
      l_offset    cwms_unit_conversion.offset%type;
      l_function  cwms_unit_conversion.function%type;
      l_converted binary_double;
   begin
      if p_value is not null then
         select factor,
                offset,
                function
           into l_factor,
                l_offset,
                l_function
           from cwms_unit_conversion
          where from_unit_code = p_from_unit_code
            and to_unit_code = p_to_unit_code;
            
         if l_factor is null then
            l_converted := cwms_util.eval_expression(l_function, double_tab_t(p_value));
         else
            l_converted := p_value * l_factor + l_offset;
         end if;
      end if;
      return l_converted;
   exception
      when no_data_found
      then
         cwms_err.raise (
            'ERROR',
            'Cannot convert from unit '
            || p_from_unit_code
            || ' to unit '
            || p_to_unit_code);
   end convert_units;

   function convert_units (
      p_value            in binary_double,
      p_from_unit_code   in number,
      p_to_unit_id       in varchar2)
      return binary_double
      result_cache
   is
      l_factor    cwms_unit_conversion.factor%type;
      l_offset    cwms_unit_conversion.offset%type;
      l_function  cwms_unit_conversion.function%type;
      l_converted binary_double;
   begin
      if p_value is not null then
         select factor,
                offset,
                function
           into l_factor,
                l_offset,
                l_function
           from cwms_unit_conversion
          where from_unit_code = p_from_unit_code
            and to_unit_id = cwms_util.get_unit_id(p_to_unit_id);
            
         if l_factor is null then
            l_converted := cwms_util.eval_expression(l_function, double_tab_t(p_value));
         else
            l_converted := p_value * l_factor + l_offset;
         end if;
      end if;
      return l_converted;
   exception
      when no_data_found
      then
         cwms_err.raise (
            'ERROR',
            'Cannot convert from unit '
            || p_from_unit_code
            || ' to unit '
            || p_to_unit_id);
   end convert_units;

   function convert_units (
      p_value          in binary_double,
      p_from_unit_id   in varchar2,
      p_to_unit_code   in number)
      return binary_double
      result_cache
   is
      l_factor    cwms_unit_conversion.factor%type;
      l_offset    cwms_unit_conversion.offset%type;
      l_function  cwms_unit_conversion.function%type;
      l_converted binary_double;
   begin
      if p_value is not null then
         select factor,
                offset,
                function
           into l_factor,
                l_offset,
                l_function
           from cwms_unit_conversion
          where from_unit_id = cwms_util.get_unit_id(p_from_unit_id)
            and to_unit_code = p_to_unit_code;
            
         if l_factor is null then
            l_converted := cwms_util.eval_expression(l_function, double_tab_t(p_value));
         else
            l_converted := p_value * l_factor + l_offset;
         end if;
      end if;
      return l_converted;
   exception
      when no_data_found
      then
         cwms_err.raise (
            'ERROR',
            'Cannot convert from unit '
            || p_from_unit_id
            || ' to unit '
            || p_to_unit_code);
   end convert_units;

   --
   -- sign-extends 32-bit integers so they can be retrieved by
   -- java int type
   --

   FUNCTION sign_extend (p_int IN INTEGER)
      RETURN INTEGER
   IS
   BEGIN
      DBMS_OUTPUT.put_line (
         'Warning: Use of CWMS_UTIL.SIGN_EXTEND is deprecated');
      RETURN p_int;
   END sign_extend;

   -----------------------------------
   -- function months_to_yminterval --
   -----------------------------------

   FUNCTION months_to_yminterval (p_months IN INTEGER)
      RETURN INTERVAL YEAR TO MONTH
   IS
   BEGIN
      IF p_months IS NULL
      THEN
         RETURN NULL;
      END IF;

      RETURN TO_YMINTERVAL (
                   TO_CHAR (TRUNC (p_months / 12))
                || '-'
                || TO_CHAR (MOD (p_months, 12)));
   END months_to_yminterval;

   ------------------------------------
   -- function minutes_to_dsinterval --
   ------------------------------------

   FUNCTION minutes_to_dsinterval (p_minutes IN INTEGER)
      RETURN INTERVAL DAY TO SECOND
   IS
   BEGIN
      IF p_minutes IS NULL
      THEN
         RETURN NULL;
      END IF;

      RETURN TO_DSINTERVAL (
                   TO_CHAR (TRUNC (p_minutes / 1440))
                || ' '
                || TO_CHAR (TRUNC (MOD (p_minutes, 1440) / 60))
                || ':'
                || TO_CHAR (MOD (p_minutes, 60) || ': 00'));
   END minutes_to_dsinterval;

   -----------------------------------
   -- function yminterval_to_months --
   -----------------------------------

   FUNCTION yminterval_to_months (p_intvl IN yminterval_unconstrained)
      RETURN INTEGER
   IS
   BEGIN
      IF p_intvl IS NULL
      THEN
         RETURN NULL;
      END IF;

      RETURN 12 * EXTRACT (YEAR FROM p_intvl) + EXTRACT (MONTH FROM p_intvl);
   END yminterval_to_months;

   ------------------------------------
   -- function dsinterval_to_minutes --
   ------------------------------------

   FUNCTION dsinterval_to_minutes (p_intvl IN dsinterval_unconstrained)
      RETURN INTEGER
   IS
   BEGIN
      IF p_intvl IS NULL
      THEN
         RETURN NULL;
      END IF;

      RETURN   1440 * EXTRACT (DAY FROM p_intvl)
             + 60 * EXTRACT (HOUR FROM p_intvl)
             + EXTRACT (MINUTE FROM p_intvl);
   END dsinterval_to_minutes;

   ----------------------------------
   -- function minutes_to_duration --
   ----------------------------------

   function minutes_to_duration (
      p_minutes in integer)
      return varchar2
   is
      l_duration varchar2(16);
      l_dsintvl  dsinterval_unconstrained;
      l_days     integer;
      l_hours    integer;
      l_minutes  integer;
   begin
      if p_minutes is not null then
         l_duration := 'P';
         l_dsintvl  := minutes_to_dsinterval(p_minutes);
         l_days     := extract(day from l_dsintvl);
         l_hours    := extract(hour from l_dsintvl);
         l_minutes  := extract(minute from l_dsintvl);
         if l_days > 0 then
            l_duration := l_duration || l_days || 'D';
         end if;
         if l_hours + l_minutes > 0 then
            l_duration := l_duration || 'T';
         end if;
         if l_hours > 0 then
            l_duration := l_duration || l_hours || 'H';
         end if;
         if l_minutes > 0 or l_days + l_hours = 0 then
            l_duration := l_duration || l_minutes || 'M';
         end if;
      end if;                      
      return l_duration;
   end minutes_to_duration;

   ----------------------------------
   -- function duration_to_minutes --
   ----------------------------------

   function duration_to_minutes(
      p_duration in varchar2)
      return integer
   is
      --                                     1      2      3      4 5      6      7   8
      l_pattern constant varchar2(128) := '^P(\d+Y)?(\d+M)?(\d+D)?(T(\d+H)?(\d+M)?(\d+([.]\d+)?S)?)?$';
      l_duration varchar2(64) := trim(p_duration);
      l_text    varchar2(8);        
      l_minutes integer;
   begin                                                                                     
      if regexp_substr(l_duration, l_pattern, 1, 1, 'i', 0) is null then
         cwms_err.raise('INVALID_ITEM', l_duration, 'ISO 8601 duration');
      end if;                                             
      for i in 1..2 loop
         if regexp_substr(l_duration, l_pattern, 1, 1, 'i', i) is not null then
            l_text := regexp_substr(l_duration, l_pattern, 1, 1, 'i', i);
            if to_number(substr(l_text, 1, length(l_text)-1)) > 0 then
               cwms_err.raise('ERROR', 'Cannont compute minutes. Duration "'||l_duration||'" contains years and/or months');
            end if;
         end if;
      end loop;
      if regexp_substr(l_duration, l_pattern, 1, 1, 'i', 7) is not null then
            l_text := regexp_substr(l_duration, l_pattern, 1, 1, 'i', 7);
            if to_number(substr(l_text, 1, length(l_text)-1)) > 0 then
               cwms_err.raise('ERROR', 'Cannont compute minutes. Duration "'||l_duration||'" contains seconds');
            end if;
      end if;
      l_minutes := 0;
      if regexp_substr(l_duration, l_pattern, 1, 1, 'i', 3) is not null then
         l_text := regexp_substr(l_duration, l_pattern, 1, 1, 'i', 3);
         l_minutes := l_minutes + 1440 * to_number(substr(l_text, 1, length(l_text)-1));
      end if;
      if regexp_substr(l_duration, l_pattern, 1, 1, 'i', 5) is not null then
         l_text := regexp_substr(l_duration, l_pattern, 1, 1, 'i', 5);
         l_minutes := l_minutes + 60 * to_number(substr(l_text, 1, length(l_text)-1));
      end if;
      if regexp_substr(l_duration, l_pattern, 1, 1, 'i', 6) is not null then
         l_text := regexp_substr(l_duration, l_pattern, 1, 1, 'i', 6);
         l_minutes := l_minutes + to_number(substr(l_text, 1, length(l_text)-1));
      end if;
      return l_minutes;
   end duration_to_minutes;      

   ------------------------------------
   -- procedure duration_to_interval --
   ------------------------------------

   procedure duration_to_interval(
      p_ym_interval out yminterval_unconstrained,
      p_ds_interval out dsinterval_unconstrained,
      p_duration    in  varchar2)
   is
      --                                     1      2      3      4 5      6      7   8
      l_pattern constant varchar2(128) := '^P(\d+Y)?(\d+M)?(\d+D)?(T(\d+H)?(\d+M)?(\d+([.]\d+)?S)?)?$';
      l_duration varchar2(64) := trim(p_duration);
      l_text     varchar2(8);        
      l_years    pls_integer := 0;
      l_months   pls_integer := 0;
      l_days     pls_integer := 0;
      l_hours    pls_integer := 0;
      l_minutes  pls_integer := 0;
      l_seconds  number := 0;
   begin
      if regexp_substr(l_duration, l_pattern, 1, 1, 'i', 0) is null then
         cwms_err.raise('INVALID_ITEM', l_duration, 'ISO 8601 duration');
      end if;                                             
      if regexp_substr(l_duration, l_pattern, 1, 1, 'i', 1) is not null then
         l_text := regexp_substr(l_duration, l_pattern, 1, 1, 'i', 1);
         l_years := to_number(substr(l_text, 1, length(l_text)-1));
      end if;
      if regexp_substr(l_duration, l_pattern, 1, 1, 'i', 2) is not null then
         l_text := regexp_substr(l_duration, l_pattern, 1, 1, 'i', 2);
         l_months := to_number(substr(l_text, 1, length(l_text)-1));
      end if;
      if regexp_substr(l_duration, l_pattern, 1, 1, 'i', 3) is not null then
         l_text := regexp_substr(l_duration, l_pattern, 1, 1, 'i', 3);
         l_days := to_number(substr(l_text, 1, length(l_text)-1));
      end if;
      if regexp_substr(l_duration, l_pattern, 1, 1, 'i', 5) is not null then
         l_text := regexp_substr(l_duration, l_pattern, 1, 1, 'i', 5);
         l_hours := to_number(substr(l_text, 1, length(l_text)-1));
      end if;
      if regexp_substr(l_duration, l_pattern, 1, 1, 'i', 6) is not null then
         l_text := regexp_substr(l_duration, l_pattern, 1, 1, 'i', 6);
         l_minutes := to_number(substr(l_text, 1, length(l_text)-1));
      end if;
      if regexp_substr(l_duration, l_pattern, 1, 1, 'i', 7) is not null then
         l_text := regexp_substr(l_duration, l_pattern, 1, 1, 'i', 7);
         l_seconds := to_number(substr(l_text, 1, length(l_text)-1));
      end if;
      p_ym_interval := to_yminterval(l_years||'-'||l_months);
      p_ds_interval := to_dsinterval(l_days||' '||l_hours||':'||l_minutes||':'||l_seconds);
   end duration_to_interval;            

   -----------------------------------
   -- function parse_odbc_ts_string --
   -----------------------------------

   FUNCTION parse_odbc_ts_string (p_odbc_str IN VARCHAR2)
      RETURN DATE
   IS
   BEGIN
      IF p_odbc_str IS NULL
      THEN
         RETURN NULL;
      END IF;

      RETURN TO_DATE (p_odbc_str, odbc_ts_fmt);
   EXCEPTION
      WHEN OTHERS
      THEN
         cwms_err.raise ('INVALID_ITEM',
                         p_odbc_str,
                         'ODBC timestamp format (' || odbc_ts_fmt || ')');
   END parse_odbc_ts_string;

   ----------------------------------
   -- function parse_odbc_d_string --
   ----------------------------------

   FUNCTION parse_odbc_d_string (p_odbc_str IN VARCHAR2)
      RETURN DATE
   IS
   BEGIN
      IF p_odbc_str IS NULL
      THEN
         RETURN NULL;
      END IF;

      RETURN TO_DATE (p_odbc_str, odbc_d_fmt);
   EXCEPTION
      WHEN OTHERS
      THEN
         cwms_err.raise ('INVALID_ITEM',
                         p_odbc_str,
                         'ODBC date format (' || odbc_d_fmt || ')');
   END parse_odbc_d_string;

   ----------------------------------------
   -- function parse_odbc_ts_or_d_string --
   ----------------------------------------

   FUNCTION parse_odbc_ts_or_d_string (p_odbc_str IN VARCHAR2)
      RETURN DATE
   IS
      l_date   DATE;
   BEGIN
      IF p_odbc_str IS NULL
      THEN
         RETURN NULL;
      END IF;

      l_date := parse_odbc_ts_string (p_odbc_str);
      RETURN l_date;
   EXCEPTION
      WHEN OTHERS
      THEN
         BEGIN
            l_date := parse_odbc_d_string (p_odbc_str);
            RETURN l_date;
         EXCEPTION
            WHEN OTHERS
            THEN
               cwms_err.raise (
                  'INVALID_ITEM',
                  p_odbc_str,
                     'ODBC timestamp or date format ('
                  || odbc_ts_fmt
                  || ', '
                  || ')');
         END;
   END parse_odbc_ts_or_d_string;

   function is_expression_constant(
      p_token in varchar2)
      return boolean
   is
      l_count   integer;
   begin
      select count(*)
        into l_count
        from table(expression_constants)
       where column_value = p_token;

      return l_count > 0;
   end is_expression_constant;

   function is_expression_operator(
      p_token in varchar2)
      return boolean
   is
      l_count   integer;
   begin
      select count(*)
        into l_count
        from table(expression_operators)
       where column_value = p_token;

      return l_count > 0;
   end is_expression_operator;

   function is_expression_function(
      p_token in varchar2)
      return boolean
   is
      l_count   integer;
   begin
      select count(*)
        into l_count
        from table(expression_functions)
       where column_value = p_token;

      return l_count > 0;
   end is_expression_function;

   function is_comparison_operator(
      p_token in varchar2)
      return boolean
   is
      l_count   integer;
   begin
      select count(*)
        into l_count
        from table(comparitors)
       where column_value = p_token;

      return l_count > 0;
   end is_comparison_operator;

   function is_combination_operator(
      p_token in varchar2)
      return boolean
   is
      l_count   integer;
   begin
      select count(*)
        into l_count
        from table(combinators)
       where column_value = p_token;

      return l_count > 0;
   end is_combination_operator;

   function is_logic_operator(
      p_token in varchar2)
      return boolean
   is        
   begin
      return is_comparison_operator(p_token) or is_combination_operator(p_token);
   end is_logic_operator;
   
   function tokenize_comparison_expression(
      p_comparison_expression in varchar2)
      return str_tab_tab_t
   is
      c_re          constant varchar2(49) := '\W?('||join_text(comparitors, '|')||')\W?';
      l_tokenized   str_tab_tab_t;
      l_parts       str_tab_t;
      l_expressions str_tab_t;
      l_op          varchar2(3);
      procedure invalid is 
      begin 
         cwms_err.raise('ERROR', 'Invalid comparison expression: '||p_comparison_expression);
      end;
   begin        
      l_parts := split_text(upper(trim(p_comparison_expression)));
      if is_comparison_operator(l_parts(l_parts.count)) then
         l_op := l_parts(l_parts.count); 
         l_parts := tokenize_expression2(join_text(sub_table(l_parts, 1, l_parts.count-1), ' '), 'T');
         l_tokenized := str_tab_tab_t();
         l_tokenized.extend(l_parts.count+1);
         for i in 1..l_parts.count loop
            l_tokenized(i) := split_text(l_parts(i));
         end loop;
         l_tokenized(l_tokenized.count) := str_tab_t(l_op); 
      else
         select trim(column_value) 
           bulk collect 
           into l_parts 
          from table(cwms_util.split_text_regexp(p_comparison_expression, c_re, 'T', 'i')); 
         case l_parts.count
         when 2 then
            if is_comparison_operator(l_parts(2)) then
               l_expressions := tokenize_expression2(l_parts(1));
               if l_expressions.count = 2 then
                  l_tokenized := str_tab_tab_t();
                  l_tokenized.extend(3);
                  l_tokenized(1) := tokenize_rpn(l_expressions(1));
                  l_tokenized(2) := tokenize_rpn(l_expressions(2));
                  l_tokenized(3) := str_tab_t(l_parts(2));
               else
                  invalid;
               end if;
            else
               invalid;
            end if;
         when 3 then
            if is_comparison_operator(l_parts(2)) then
               l_tokenized := str_tab_tab_t();
               l_tokenized.extend(3);
                  l_tokenized(1) := tokenize_expression(l_parts(1));
                  l_tokenized(2) := tokenize_expression(l_parts(3));
                  l_tokenized(3) := str_tab_t(l_parts(2));
            else
               invalid;
            end if;
         else 
            invalid;
         end case;
      end if;
      return l_tokenized;
   end tokenize_comparison_expression;
   
   -----------------------------------------------------------------------------
   -- FUNCTION tokenize_logic_expression
   -----------------------------------------------------------------------------
   function tokenize_logic_expression(
      p_expr in varchar2)                                                                                                                 
      return str_tab_tab_t
   is              
      c_re           constant varchar2(22) := '\W?('||cwms_util.join_text(cwms_util.combinators, '|')||')\W?';
      l_expr         varchar2(32767);
      l_temp         varchar2(32676);
      l_results      str_tab_tab_t;
      l_len          pls_integer;
      l_parts        str_tab_t;
      l_replacements str_tab_t;
      l_table1       str_tab_t;
      l_table2       str_tab_tab_t;
      l_start        pls_integer;
      l_end          pls_integer;  
      
      function sub_expr(p_table in str_tab_t, p_first in pls_integer, p_last in pls_integer default null) return varchar2
      is
         l_table str_tab_t;
         l_expr  varchar2(32767);
         l_end   pls_integer := nvl(p_last, p_table.count);
         l_extra pls_integer;
      begin
         select trim(column_value)
           bulk collect
           into l_table 
           from table(sub_table(p_table, p_first, p_last));    
         l_expr := join_text(l_table, ' ');                           
         return l_expr;                           
      end sub_expr; 
                     
      function drop_elements(p_indices in number_tab_t, p_table in str_tab_t) return str_tab_t
      is
         l_table str_tab_t;
      begin
         select column_value
           bulk collect
           into l_table
           from (select column_value,
                        rownum as seq
                   from table(p_table)
                )
          where seq not in (select * from table(p_indices))
          order by seq;
          
         return l_table;                     
      end drop_elements;
   begin
      l_expr := upper(trim(p_expr));
      l_len  := length(l_expr);
      if nvl(get_expression_depth_at(l_len+1, l_expr), 0) != 0 then
         cwms_err.raise('ERROR', 'Expression has unbalanced parentheses: '||p_expr);
      end if;
      if regexp_count(l_expr, c_re) = 0 then
         ------------------------
         -- no logic operators --
         ------------------------
         begin
            l_results := tokenize_comparison_expression(p_expr);
         exception
            when others then
               ------------------------------------
               -- no comparison operators either --
               ------------------------------------
               l_results := str_tab_tab_t(tokenize_expression(p_expr));
         end;
      else
         l_parts := split_text(l_expr);
         l_len := l_parts.count;
         if is_combination_operator(l_parts(l_len)) or 
            is_comparison_operator(l_parts(l_len)) or
            is_expression_operator(l_parts(l_len)) or
            is_expression_function(l_parts(l_len))
         then
            -------------
            -- postfix --
            ------------- 
            if instr(l_expr, '(') > 0 then
               cwms_err.raise('ERROR', 'Invalid logic expression: '||p_expr);
            end if; 
            l_results := str_tab_tab_t();
            l_temp  := null;
            for i in 1..l_len loop  
               if is_comparison_operator(l_parts(i)) then 
                  l_temp := l_temp||' '||l_parts(i);
                  l_table2 := tokenize_comparison_expression(l_temp);
                  if l_table2.count != 3 then
                     cwms_err.raise('ERROR', 'Invalid logic expression: '||l_temp);
                  end if;
                  l_results.extend(3);
                  for j in 1..3 loop
                     l_results(l_results.count-3+j) := l_table2(j);
                  end loop;
                  l_temp  := null;
               elsif is_combination_operator(l_parts(i)) then
                  l_results.extend;
                  l_results(l_results.count) := str_tab_t(l_parts(i));
               else
                  l_temp := l_temp||' '||l_parts(i);
               end if;
            end loop;
         else
            -----------
            -- infix --
            -----------
            ---------------------------- 
            -- bind parentheses first --
            ---------------------------- 
            l_replacements := replace_parentheticals(l_expr);
            l_replacements(l_replacements.count) := regexp_replace(l_replacements(l_replacements.count), '\$(\d+)', 'ARG10\1', 1, 0);
            l_expr := l_replacements(l_replacements.count);
            l_replacements.trim;
            -----------------------------------------------------------
            -- next bind operators in decreasing order of precedence --
            -----------------------------------------------------------
            l_start := l_replacements.count + 1;
            l_parts := split_text_regexp(l_expr, c_re, 'T', 'i');
            for rec in (select column_value as op from table(str_tab_t('NOT', 'AND', 'XOR', 'OR'))) loop
               for i in reverse 1..l_parts.count loop
                  if trim(l_parts(i)) = rec.op then
                     l_replacements.extend;
                     if rec.op = 'NOT' then
                        l_replacements(l_replacements.count) := join_text(sub_table(l_parts, i, i+1),' ');
                        l_parts(i) := 'ARG10'||l_replacements.count;
                        l_parts := drop_elements(number_tab_t(i+1), l_parts);
                     else
                        l_replacements(l_replacements.count) := join_text(sub_table(l_parts, i-1, i+1), ' ');
                        l_parts(i-1) := 'ARG10'||l_replacements.count;
                        l_parts := drop_elements(number_tab_t(i, i+1), l_parts);
                     end if;
                  end if;
               end loop;
            end loop;
            ------------------------------------------------------
            -- unwind operator replacements in postfix notation --
            ------------------------------------------------------
            l_expr := l_parts(1);
            for i in reverse 1..l_replacements.count loop
               l_temp := null;
               if i < l_start then
                  -------------------------------------
                  -- replace parentetical expression --
                  -------------------------------------  
                  l_table1 := split_text(l_replacements(i));
                  if is_expression_function(l_table1(1)) then
                     l_table2 := tokenize_logic_expression(sub_expr(l_table1, 2));
                     l_table2.extend;
                     l_table2(l_table2.count) := str_tab_t(l_table1(1));
                  else 
                     l_table2 := tokenize_logic_expression(l_replacements(i));
                  end if;
                  for j in 1..l_table2.count loop
                     l_temp := l_temp||join_text(l_table2(j), ' ')||' ';
                  end loop;
               else
                  ------------------------------
                  -- replace logic expression --
                  ------------------------------
                  l_parts := split_text_regexp(l_replacements(i), c_re, 'T', 'i');
                  case l_parts.count
                  when 2 then 
                     --------------------------
                     -- unary operator (NOT) --
                     --------------------------
                     begin
                        l_table2 := tokenize_comparison_expression(l_parts(2));
                        for j in 1..l_table2.count loop
                           l_temp := l_temp||join_text(l_table2(j), ' ')||' ';
                        end loop;
                        l_temp := l_temp||l_parts(1);
                     exception
                        when others then
                           l_temp := l_parts(2)||' '||l_parts(1);
                     end; 
                  when 3 then
                     --------------------- 
                     -- binary operator --
                     --------------------- 
                     begin
                        l_table2 := tokenize_comparison_expression(l_parts(1));
                        for j in 1..l_table2.count loop
                           l_temp := l_temp||join_text(l_table2(j), ' ')||' ';
                        end loop;
                     exception
                        when others then
                           l_temp := l_parts(1);
                     end; 
                     begin
                        l_table2 := tokenize_comparison_expression(l_parts(3));
                        for j in 1..l_table2.count loop
                           l_temp := l_temp||join_text(l_table2(j), ' ')||' ';
                        end loop;
                        l_temp := l_temp||l_parts(2);
                     exception
                        when others then
                           l_temp := l_temp||' '||l_parts(3)||' '||l_parts(2);
                     end; 
                  else 
                     cwms_err.raise('ERROR', 'Invalid subexpression: '||l_replacements(i));
                  end case;
               end if;
               l_expr := replace(l_expr, 'ARG10'||i, l_temp);
            end loop;
            l_results := tokenize_logic_expression(l_expr);
         end if;
      end if; 
      return l_results;
   end tokenize_logic_expression;
   
   function tokenize_algebraic(
      p_algebraic_expr in varchar2)
      return str_tab_t
      result_cache
   is
      l_infix_tokens        str_tab_t;
      l_postfix_tokens      str_tab_t := new str_tab_t();
      l_stack               str_tab_t := new str_tab_t();
      l_func_stack          str_tab_t := new str_tab_t();
      l_left_paren_count    binary_integer := 0;
      l_right_paren_count   binary_integer := 0;
      l_func                varchar2(8);
      l_dummy               varchar2(1);
      --------------------
      -- local routines --
      --------------------
      procedure error
      is
      begin
         cwms_err.raise(
            'ERROR',
            'Invalid algebraic expression: ' || p_algebraic_expr);
      end;

      procedure token_error(token in varchar2)
      is
      begin
         cwms_err.raise('ERROR', 'Invalid token in equation: ' || token);
      end;

      function precedence(op in varchar2) return number
      is
         l_precedence pls_integer;
      begin     
         if op is not null then
            l_precedence :=  case op
                             when '+'  then 1
                             when '-'  then 1
                             when '*'  then 2
                             when '/'  then 2
                             when '//' then 2
                             when '%'  then 2
                             when '^'  then 3
                             else 0
                             end;
            if l_precedence < 1 then
               cwms_err.raise('ERROR', 'Invalid arithmetic operator: '||op);
            end if;
         end if;
         return l_precedence;                          
      end;

      procedure push(p_op in varchar2)
      is
      begin
         l_stack.extend;
         l_stack(l_stack.count) := p_op;
      end;

      function pop return varchar2
      is
         l_op   varchar2(8);
      begin
         begin
            l_op := l_stack(l_stack.count);
         exception
            when others then error;
         end;
         l_stack.trim;
         return l_op;
      end;

      procedure push_func(p_func in varchar2)
      is
      begin
         l_func_stack.extend;
         l_func_stack(l_func_stack.count) := p_func;
      end;

      function pop_func return varchar2
      is
         l_func   varchar2(8);
      begin
         begin
            l_func := l_func_stack(l_func_stack.count);
         exception
            when others then error;
         end;
         l_func_stack.trim;
         return l_func;
      end;
   begin
      ---------------------------------
      -- parse the infix into tokens --
      ---------------------------------
      l_infix_tokens := cwms_util.split_text(trim(regexp_replace(upper(replace(p_algebraic_expr,chr(10),' ')),'([()])',' \1 ')));
      -------------------------------------
      -- process the tokens into postfix --
      -------------------------------------
      for i in 1 .. l_infix_tokens.count
      loop   
         case
         when is_expression_operator(l_infix_tokens(i)) then
            ---------------
            -- operators --
            ---------------
            if l_stack.count > 0 and precedence(l_stack(l_stack.count)) >= precedence(l_infix_tokens(i)) then
               l_postfix_tokens.extend;
               l_postfix_tokens(l_postfix_tokens.count) := pop;
            end if;

            push(l_infix_tokens(i));
         when is_expression_function(l_infix_tokens(i)) then
            ---------------
            -- functions --
            ---------------
            push_func(l_infix_tokens(i));
         when l_infix_tokens(i) = '(' then
            ----------------------
            -- open parentheses --
            ----------------------
            push(null);
            push_func(null);
            l_left_paren_count := l_left_paren_count + 1;
         when l_infix_tokens(i) = ')' then
            ------------------------
            -- close parentheses --
            ------------------------
            while l_stack(l_stack.count) is not null loop
               l_postfix_tokens.extend;
               l_postfix_tokens(l_postfix_tokens.count) := pop;
            end loop;

            l_dummy := pop;
            l_func := pop_func;

            if l_func_stack.count > 0 and l_func_stack(l_func_stack.count) is not null then
               l_func := pop_func;
               l_postfix_tokens.extend;
               l_postfix_tokens(l_postfix_tokens.count) := l_func;
            end if;

            l_right_paren_count := l_right_paren_count + 1;
         else
            ---------------------
            -- everything else --
            ---------------------
            l_postfix_tokens.extend;
            l_postfix_tokens(l_postfix_tokens.count) := l_infix_tokens(i);
         end case;
      end loop;

      if l_right_paren_count != l_left_paren_count
      then
         error;
      end if;

      while l_stack.count > 0
      loop
         l_postfix_tokens.extend;
         l_postfix_tokens(l_postfix_tokens.count) := pop;
      end loop;

      return l_postfix_tokens;
   end tokenize_algebraic;

   -----------------------------------------------------------------------------
   -- FUNCTION tokenize_rpn
   -----------------------------------------------------------------------------
   function tokenize_rpn(
      p_rpn_expr in varchar2)
      return str_tab_t
      result_cache
   is
   begin
      return split_text(trim(upper(replace(p_rpn_expr, chr(10), ' '))));
   end tokenize_rpn;

   -----------------------------------------------------------------------------
   -- FUNCTION tokenize_expression
   -----------------------------------------------------------------------------
   function tokenize_expression(
      p_expr in varchar2)
      return str_tab_t
      result_cache
   is
      l_tokens str_tab_t;
      l_count  integer := 0;
      l_number number;
   begin
      if instr(p_expr, '(') > 0 then
         -----------------------------------------------------
         -- must be algebraic, rpn doesn't have parentheses --
         -----------------------------------------------------
         l_tokens := tokenize_algebraic(p_expr);
      else            
         -------------------
         -- first try rpn --
         -------------------
         l_tokens := tokenize_rpn(p_expr);
         case l_tokens.count
         when 0 then null;
         when 1 then
            begin
               l_number := to_number(l_tokens(1));
            exception
               when others then
                  if not regexp_like(l_tokens(1), 'arg\d+', 'i') and not is_expression_constant(l_tokens(1)) then
                     cwms_err.raise('ERROR', 'Invalid expression: '||p_expr);
                  end if; 
            end;
         else
            if not is_expression_operator(l_tokens(l_tokens.count)) and 
               not is_expression_function(l_tokens(l_tokens.count)) and
               not is_comparison_operator(l_tokens(l_tokens.count)) and
               not is_combination_operator(l_tokens(l_tokens.count))
            then
               -----------------------------------------------------------------
               -- last token isn't an operator or function, must be algebraic --
               -----------------------------------------------------------------
               l_tokens := tokenize_algebraic(p_expr);
            end if;
         end case;
      end if;

      return l_tokens;
   end tokenize_expression;
   
   function tokenize_expression2(
      p_expr   in varchar2,
      p_is_rpn in varchar2 default 'F')
      return str_tab_t
      result_cache
   is    
      l_rpn_tokens str_tab_t;
      l_stack      str_tab_t := str_tab_t();
      l_val1       varchar2(32767);
      l_val2       varchar2(32767);
      l_idx        binary_integer; 
      l_number     number;
      --------------------
      -- local routines --
      --------------------
      procedure token_error(token in varchar2)
      is
      begin
         cwms_err.raise('ERROR', 'Invalid token in equation: ' || token);
      end;

      procedure argument_error(l_idx in integer)
      is
      begin
         cwms_err.raise('ERROR', 'ARG' || l_idx || ' does not exist');
      end;

      procedure push(val in varchar2)
      is
      begin
         l_stack.extend;
         l_stack(l_stack.count) := val;
      end;

      function pop return varchar2
      is
         val varchar2(32767);
      begin
         val := l_stack(l_stack.last);
         l_stack.trim;
         return val;
      end;
   begin                   
      if is_true(p_is_rpn) then
         l_rpn_tokens := split_text(p_expr);
      else
         l_rpn_tokens := tokenize_expression(p_expr);
      end if;
      for i in 1 .. l_rpn_tokens.count loop
         case
         ---------------
         -- operators --
         ---------------
         when is_expression_operator(l_rpn_tokens(i)) or
              is_comparison_operator(l_rpn_tokens(i)) or
              is_combination_operator(l_rpn_tokens(i))          
         then
            if l_rpn_tokens(i) = 'NOT' then
               push(pop||l_rpn_tokens(i));
            else
               l_val2 := pop;
               l_val1 := pop;
               push(l_val1||' '||l_val2||' '||l_rpn_tokens(i));
            end if; 
         ---------------
         -- constants --
         ---------------
         when is_expression_constant(l_rpn_tokens(i)) then push(l_rpn_tokens(i));
         ---------------------
         -- unary functions --
         ---------------------
         when is_expression_function(l_rpn_tokens(i)) then
            push(pop||' '||l_rpn_tokens(i));
         ---------------
         -- arguments --
         ---------------
         when substr(l_rpn_tokens(i), 1, 3) = 'ARG' or substr(l_rpn_tokens(i), 1, 4) = '-ARG' then
            push(l_rpn_tokens(i));
         -------------
         -- numbers --
         -------------
         else             
            begin
               l_number := to_number(l_rpn_tokens(i));
            exception
               when others then cwms_err.raise('ERROR', 'Invalid expression token: '||l_rpn_tokens(i));
            end;
            push(l_rpn_tokens(i));
         end case;
      end loop;
      return l_stack;
   end tokenize_expression2;
   
   -----------------------------------------------------------------------------
   -- FUNCTION replace_parentheticals
   -----------------------------------------------------------------------------
   function replace_parentheticals(
      p_expr in varchar2)
      return str_tab_t
   is
      l_results   str_tab_t := str_tab_t();
      l_positions number_tab_t;
      l_expr      varchar2(32767);
      l_start     pls_integer;
      l_end       pls_integer;
      l_token     varchar2(4);
      l_parts     str_tab_t;  
   begin
      select pos
        bulk collect
        into l_positions 
        from (select pos,
                     offset,
                     sum(offset) over (order by pos) as depth
                from (select instr(p_expr, '(', 1, level) as pos,
                             1 as offset 
                        from dual
                     connect by level <= regexp_count(p_expr, '\(')
                      union all
                      select instr(p_expr, ')', 1, level) as pos,
                             -1 as offset 
                        from dual
                     connect by level <= regexp_count(p_expr, '\)')
                     )
              )
        where offset =  1 and depth = 1
           or offset = -1 and depth = 0;
      if l_positions.count = 1 then 
         l_positions.trim;
      end if;           
      l_results.extend(l_positions.count/2+1);
      l_expr := p_expr;
      for i in reverse 1..l_positions.count/2 loop
         l_start := l_positions(2*i-1);
         l_end   := l_positions(2*i);  
         l_results(i) := trim(substr(l_expr, l_start+1, l_end-l_start-1)); 
                              
         l_token := '$'||i;
         l_expr  := rtrim(substr(l_expr, 1, l_start-1))||' '||l_token||' '||ltrim(substr(l_expr, l_end+1));
         l_parts := split_text(l_expr);
         for j in 1..l_parts.count loop
            if l_parts(j) = l_token then
               if j > 1 and is_expression_function(l_parts(j-1)) then
                  l_results(i) := l_parts(j-1)||' '||l_results(i);
                  l_parts(j-1) := ' ';
                  l_expr := join_text(l_parts, ' ');
               end if;
               exit;
            end if;
         end loop; 
      end loop;
      l_results(l_positions.count/2+1) := trim(l_expr);              
      return l_results;
   end replace_parentheticals;      

   -----------------------------------------------------------------------------
   -- FUNCTION eval_tokenized_expression
   -----------------------------------------------------------------------------
   function eval_tokenized_expression(
      p_rpn_tokens    in str_tab_t,
      p_args          in double_tab_t,
      p_args_offset   in integer default 0)
      return number
   is 
      l_stack double_tab_t;
   begin
      l_stack := eval_tokenized_expression2(
         p_rpn_tokens  => p_rpn_tokens,
         p_args        => p_args,
         p_args_offset => p_args_offset);
      if l_stack.count > 1 then
         cwms_err.raise ('ERROR', 'Remaining items on stack');
      end if;
      return l_stack(1);         
   end eval_tokenized_expression;      

   -----------------------------------------------------------------------------
   -- FUNCTION eval_tokenized_expression2
   -----------------------------------------------------------------------------
   function eval_tokenized_expression2(
      p_rpn_tokens    in str_tab_t,
      p_args          in double_tab_t,
      p_args_offset   in integer default 0)
   return double_tab_t
   is
      l_stack double_tab_t := double_tab_t();
      l_val1  binary_double;
      l_val2  binary_double;
      l_idx   binary_integer;
      --------------------
      -- local routines --
      --------------------
      procedure token_error(token in varchar2)
      is
      begin
         cwms_err.raise('ERROR', 'Invalid token in equation: ' || token);
      end;

      procedure argument_error(l_idx in integer)
      is
      begin
         cwms_err.raise('ERROR', 'ARG' || l_idx || ' does not exist');
      end;

      procedure push(val in binary_double)
      is
      begin
         l_stack.extend;
         l_stack(l_stack.count) := val;
      end;

      function pop return binary_double
      is
         val binary_double;
      begin
         val := l_stack(l_stack.last);
         l_stack.trim;
         return val;
      end;
   begin
      for i in 1 .. p_rpn_tokens.count
      loop
         case
         ---------------
         -- operators --
         ---------------
         when p_rpn_tokens(i) = '+'  then push(pop + pop);
         when p_rpn_tokens(i) = '-'  then push(-pop + pop);
         when p_rpn_tokens(i) = '*'  then push(pop * pop);
         when p_rpn_tokens(i) = '/'  then
            l_val2 := nullif(pop, 0);
            l_val1 := pop;
            push(l_val1 / l_val2);
         when p_rpn_tokens(i) = '//' then -- same as Python
            l_val2 := nullif(pop, 0);
            l_val1 := pop;
            push(floor(l_val1 / l_val2));
         when p_rpn_tokens(i) = '%'  then -- same as Python math.fmod, not %
            l_val2 := nullif(pop, 0);
            l_val1 := pop;
            push(mod(l_val1, l_val2));
         when p_rpn_tokens(i) = '^'  then
            l_val2 := pop;
            l_val1 := pop;
            push(power(l_val1, l_val2));
         ---------------
         -- constants --
         ---------------
         when p_rpn_tokens(i) = 'E'  then push(2.7182818284590451);
         when p_rpn_tokens(i) = 'PI' then push(3.1415926535897931);
         ---------------------
         -- unary functions --
         ---------------------
         when p_rpn_tokens(i) = 'ABS'   then push(abs(pop));
         when p_rpn_tokens(i) = 'ACOS'  then push(acos(pop));
         when p_rpn_tokens(i) = 'ASIN'  then push(asin(pop));
         when p_rpn_tokens(i) = 'ATAN'  then push(atan(pop));
         when p_rpn_tokens(i) = 'CEIL'  then push(ceil(pop));
         when p_rpn_tokens(i) = 'COS'   then push(cos(pop));
         when p_rpn_tokens(i) = 'EXP'   then push(exp(pop));
         when p_rpn_tokens(i) = 'FLOOR' then push(floor(pop));
         when p_rpn_tokens(i) = 'INV'   then push(1 / pop);
         when p_rpn_tokens(i) = 'LN'    then push(ln(pop));
         when p_rpn_tokens(i) = 'LOG'   then push(log(10, pop)); -- log base 10
         when p_rpn_tokens(i) = 'NEG'   then push(pop * -1);
         when p_rpn_tokens(i) = 'ROUND' then push(round(pop));
         when p_rpn_tokens(i) = 'SIGN'  then                     -- not SQL sign, but +1, 0, or -1
            l_val1 := pop;
            case
            when l_val1 < 0 then push(-1);
            when l_val1 > 0 then push(1);
            else push(0);
            end case;
         when p_rpn_tokens(i) = 'SIN'   then push(sin(pop));
         when p_rpn_tokens(i) = 'SQRT'  then push(sqrt(pop));
         when p_rpn_tokens(i) = 'TAN'   then push(tan(pop));
         when p_rpn_tokens(i) = 'TRUNC' then push(trunc(pop));
         ---------------
         -- arguments --
         ---------------
         when substr(p_rpn_tokens(i), 1, 3) = 'ARG' then
            begin
               l_idx := to_number(substr(p_rpn_tokens(i), 4)) + p_args_offset;
               if l_idx < 1 or l_idx > p_args.count then
                  argument_error(l_idx - p_args_offset);
               end if;
               push(p_args(l_idx)); 
            exception
               when others then
                  token_error(p_rpn_tokens(i));
            end;
         when substr(p_rpn_tokens(i), 1, 4) = '-ARG' then
            begin
               l_idx := to_number(substr(p_rpn_tokens(i), 5));
               if l_idx < 1 or l_idx > p_args.count
               then
                  argument_error(l_idx - p_args_offset);
               end if;
               push(p_args(l_idx));
            exception
               when others then
                  token_error(p_rpn_tokens(i));
            end;
         -------------
         -- numbers --
         -------------
         else
            begin
               push(to_binary_double(p_rpn_tokens(i)));
            exception
               when others then
                  token_error(p_rpn_tokens(i));
            end;
         end case;
      end loop;
      return l_stack;
   end eval_tokenized_expression2;

   -----------------------------------------------------------------------------
   -- FUNCTION eval_algebraic_expression
   -----------------------------------------------------------------------------
   function eval_algebraic_expression(
      p_algebraic_expr in varchar2,
      p_args           in double_tab_t,
      p_args_offset    in integer default 0)
      return number
   is
   begin
      return eval_tokenized_expression(
                tokenize_algebraic(p_algebraic_expr),
                p_args,
                p_args_offset);
   exception
      when others then
         cwms_err.raise('ERROR', 'Invalid algebraic expression: ' || p_algebraic_expr);
   end eval_algebraic_expression;

   -----------------------------------------------------------------------------
   -- FUNCTION eval_algebraic_expression2
   -----------------------------------------------------------------------------
   function eval_algebraic_expression2(
      p_algebraic_expr in varchar2,
      p_args           in double_tab_t,
      p_args_offset    in integer default 0)
      return double_tab_t
   is
   begin
      return eval_tokenized_expression2(
                tokenize_algebraic(p_algebraic_expr),
                p_args,
                p_args_offset);
   exception
      when others then
         cwms_err.raise('ERROR', 'Invalid algebraic expression: ' || p_algebraic_expr);
   end eval_algebraic_expression2;

   -----------------------------------------------------------------------------
   -- FUNCTION eval_rpn_expression
   -----------------------------------------------------------------------------
   function eval_rpn_expression(
      p_rpn_expr      in varchar2,
      p_args          in double_tab_t,
      p_args_offset   in integer default 0)
      return number
   is
   begin
      return eval_tokenized_expression(
                tokenize_rpn(p_rpn_expr),
                p_args,
                p_args_offset);
   exception
      when others then
         cwms_err.raise('ERROR', 'Invalid RPN expression: ' || p_rpn_expr);
   end eval_rpn_expression;

   -----------------------------------------------------------------------------
   -- FUNCTION eval_rpn_expression2
   -----------------------------------------------------------------------------
   function eval_rpn_expression2(
      p_rpn_expr      in varchar2,
      p_args          in double_tab_t,
      p_args_offset   in integer default 0)
      return double_tab_t
   is
   begin
      return eval_tokenized_expression2(
                tokenize_rpn(p_rpn_expr),
                p_args,
                p_args_offset);
   exception
      when others then
         cwms_err.raise('ERROR', 'Invalid RPN expression: ' || p_rpn_expr);
   end eval_rpn_expression2;

   -----------------------------------------------------------------------------
   -- FUNCTION eval_expression
   -----------------------------------------------------------------------------
   function eval_expression(
      p_expr          in varchar2,
      p_args          in double_tab_t,
      p_args_offset   in integer default 0)
      return number
   is
   begin
      return eval_tokenized_expression(tokenize_expression(p_expr), p_args, p_args_offset);
   exception
      when others then
         cwms_err.raise('ERROR', 'Invalid expression: ' || p_expr);
   end eval_expression;
   
   -----------------------------------------------------------------------------
   -- FUNCTION eval_expression2
   -----------------------------------------------------------------------------
   function eval_expression2(
      p_expr          in varchar2,
      p_args          in double_tab_t,
      p_args_offset   in integer default 0)
      return double_tab_t
   is
   begin
      return eval_tokenized_expression2(tokenize_expression(p_expr), p_args, p_args_offset);
   exception
      when others then
         cwms_err.raise('ERROR', 'Invalid expression: ' || p_expr);
   end eval_expression2;

   -----------------------------------------------------------------------------
   -- FUNCTION eval_tokenized_comparison
   -----------------------------------------------------------------------------
   function eval_tokenized_comparison(
      p_tokens      in str_tab_tab_t,
      p_args        in double_tab_t,
      p_args_offset in integer default 0)
      return boolean
   is
      l_val1   number;
      l_val2   number;
      l_op     varchar2(16);
      l_result boolean;
   begin
      l_val1 := eval_tokenized_expression(p_tokens(1), p_args, p_args_offset);
      l_val2 := eval_tokenized_expression(p_tokens(2), p_args, p_args_offset);
      l_op   := p_tokens(3)(1);
      case
         when l_op =   '='        then l_result := l_val1  = l_val2;
         when l_op in ('!=','<>') then l_result := l_val1 != l_val2;
         when l_op in ('<', 'LT') then l_result := l_val1 <  l_val2;
         when l_op in ('<=','LE') then l_result := l_val1 <= l_val2;
         when l_op in ('>', 'GT') then l_result := l_val1 >  l_val2;
         when l_op in ('>=','GE') then l_result := l_val1 >= l_val2;
         else cwms_err.raise('ERROR', 'Invalid comparison operator: '||l_op);
      end case;
      return l_result;
   end eval_tokenized_comparison;
          
   -----------------------------------------------------------------------------
   -- FUNCTION eval_tokenized_comparison2
   -----------------------------------------------------------------------------
   function eval_tokenized_comparison2(
      p_tokens      in str_tab_tab_t,
      p_args        in double_tab_t,
      p_args_offset in integer default 0)
      return varchar2
   is
   begin
      return case eval_tokenized_comparison(p_tokens, p_args, p_args_offset)
             when true  then 'T'
             when false then 'F'
             end;
   end eval_tokenized_comparison2;
          
   -----------------------------------------------------------------------------
   -- FUNCTION eval_comparison_expression
   -----------------------------------------------------------------------------
   function eval_comparison_expression(
      p_expr        in varchar2,
      p_args        in double_tab_t,
      p_args_offset in integer default 0)
      return boolean
   is
   begin
      return eval_tokenized_comparison(
         tokenize_comparison_expression(p_expr), 
         p_args, 
         p_args_offset);
   end eval_comparison_expression;
          
   -----------------------------------------------------------------------------
   -- FUNCTION eval_comparison_expression2
   -----------------------------------------------------------------------------
   function eval_comparison_expression2(
      p_expr        in varchar2,
      p_args        in double_tab_t,
      p_args_offset in integer default 0)
      return varchar2
   is
   begin
      return case eval_comparison_expression(p_expr, p_args, p_args_offset)
             when true  then 'T'
             when false then 'F'
             end;
   end eval_comparison_expression2;
          
   -----------------------------------------------------------------------------
   -- FUNCTION get_expression_depth_at
   -----------------------------------------------------------------------------
   function get_expression_depth_at(
      p_position in integer,
      p_expr     in varchar2)
      return integer
   is
      l_expr  varchar2(32767) := substr(p_expr, 1, p_position);
      l_depth pls_integer;
   begin                       
      l_depth := regexp_count(l_expr, '\(') - regexp_count(l_expr, '\)');
      if substr(l_expr, p_position, 1) = ')' then
         l_depth := l_depth + 1;
      end if;
      return l_depth;
   end get_expression_depth_at;      
            
   function to_algebraic(
      p_expr in varchar2)
      return varchar2
   is
   begin
      return to_algebraic(tokenize_expression(p_expr));
   end to_algebraic;      
            
   function to_algebraic(
      p_tokens in str_tab_t)
      return varchar2
   is
      l_rpn_tokens str_tab_t;
      l_stack      str_tab_t := str_tab_t();
      l_val1       varchar2(32767);
      l_val2       varchar2(32767);
      l_idx        binary_integer;
      --------------------
      -- local routines --
      --------------------
      procedure token_error(token in varchar2)
      is
      begin
         cwms_err.raise('ERROR', 'Invalid token in equation: ' || token);
      end;

      procedure argument_error(l_idx in integer)
      is
      begin
         cwms_err.raise('ERROR', 'ARG' || l_idx || ' does not exist');
      end;

      procedure push(val in varchar2)
      is
      begin
         l_stack.extend;
         l_stack(l_stack.count) := val;
      end;

      function pop return varchar2
      is
         val         varchar2(32767);
      begin
         val := l_stack(l_stack.last);
         l_stack.trim;
         return val;
      end;
      
      function precedence(p_op in varchar2) return integer
      is
         l_precedence integer;
      begin
         case 
         when p_op in ('+','-')          then l_precedence := 1;
         when p_op in ('*','/','//','%') then l_precedence := 2;
         when p_op = '^'                 then l_precedence := 3;
         else cwms_err.raise('ERROR', 'Invalid operator: '||p_op); 
         end case;
         return l_precedence;
      end;
   begin             
      for i in 1 .. p_tokens.count loop
         case
         ---------------
         -- operators --
         ---------------
         when p_tokens(i) in ('+','-','*','/','//','%','^')  then 
            l_val2 := pop;
            l_rpn_tokens := tokenize_expression(l_val2);
            if l_rpn_tokens(l_rpn_tokens.count) in ('+','-','*','/','//','%','^') and 
               precedence(l_rpn_tokens(l_rpn_tokens.count)) < precedence(p_tokens(i))
            then
               l_val2 := '('||l_val2||')';
            end if; 
            l_val1 := pop;
            l_rpn_tokens := tokenize_expression(l_val1);
            if l_rpn_tokens(l_rpn_tokens.count) in ('+','-','*','/','//','%','^') and 
            precedence(l_rpn_tokens(l_rpn_tokens.count)) < precedence(p_tokens(i))
            then
               l_val1 := '('||l_val1||')';
            end if; 
            push(l_val1||' '||p_tokens(i)||' '||l_val2);
         ---------------
         -- constants --
         ---------------
         when p_tokens(i) in ('E', 'PI') then push(p_tokens(i));
         ---------------------
         -- unary functions --
         ---------------------
         when p_tokens(i) in ('ABS','ACOS','ASIN','ATAN','CEIL','COS','EXP','FLOOR','INV','LN','LOG','NEG','ROUND','SIGN','SIN','SQRT','TAN','TRUNC') then
            l_val1 := pop;
            if substr(l_val1, 1, 1) = '(' then
               push(p_tokens(i)||l_val1);
            else
               push(p_tokens(i)||'('||l_val1||')');
            end if;
         ---------------
         -- arguments --
         ---------------
         when substr(p_tokens(i), 1, 3) = 'ARG' or substr(p_tokens(i), 1, 4) = '-ARG' then
            push(p_tokens(i));
         -------------
         -- numbers --
         -------------
         else
            push(p_tokens(i));
         end case;
      end loop;
      if l_stack.count != 1 then
         cwms_err.raise('ERROR', 'Items left on stack');
      end if;
      return pop;
   end to_algebraic;
         
   function to_algebraic_logic(
      p_expr in varchar2)
      return varchar2
   is
      l_expr        varchar2(256);
      l_logic_expr logic_expr_t;
   begin
      l_logic_expr := logic_expr_t(p_expr);
      l_logic_expr.to_algebraic(l_expr);
      return l_expr;
   end to_algebraic_logic;            
            
   function to_rpn(
      p_expr in varchar2)
      return varchar2
   is
   begin
      return to_rpn(tokenize_expression(p_expr));
   end to_rpn;      
            
   function to_rpn(
      p_tokens in str_tab_t)
      return varchar2
   is
   begin
      return join_text(p_tokens, ' ');
   end to_rpn;      
         
   function to_rpn_logic(
      p_expr in varchar2)
      return varchar2
   is
      l_expr        varchar2(256);
      l_logic_expr logic_expr_t;
   begin
      l_logic_expr := logic_expr_t(p_expr);
      l_logic_expr.to_rpn(l_expr);
      return l_expr;
   end to_rpn_logic;
               
   function get_comparison_op_symbol(
      p_operator in varchar2)
      return varchar2
   is
      l_op varchar2(8); 
   begin
      l_op := upper(trim(p_operator));
      case
      when l_op in ('EQ', '='        ) then l_op := '=' ;
      when l_op in ('NE', '!=', '<>' ) then l_op := '!=';
      when l_op in ('LT', '<'        ) then l_op := '<' ;
      when l_op in ('LE', '<='       ) then l_op := '<=';
      when l_op in ('GT', '>'        ) then l_op := '>' ;
      when l_op in ('GE', '>='       ) then l_op := '>=';
      else cwms_err.raise('INVALID_ITEM', p_operator, 'comparison operator');
      end case;
      return l_op;
   end;               
               
   function get_comparison_op_text(
      p_operator in varchar2)
      return varchar2
   is
      l_op varchar2(8); 
   begin
      l_op := upper(trim(p_operator));
      case
      when l_op in ('EQ', '='        ) then l_op := 'EQ';
      when l_op in ('NE', '!=', '<>' ) then l_op := 'NE';
      when l_op in ('LT', '<'        ) then l_op := 'LT';
      when l_op in ('LE', '<='       ) then l_op := 'LE';
      when l_op in ('GT', '>'        ) then l_op := 'GT';
      when l_op in ('GE', '>='       ) then l_op := 'GE';
      else cwms_err.raise('INVALID_ITEM', p_operator, 'comparison operator');
      end case;
      return l_op;
   end;               

   ---------------------
   -- Append routines --
   ---------------------

   procedure append(
      p_dst in out nocopy clob, 
      p_src in clob)
   is
   begin
      if p_src is not null then
         dbms_lob.append(p_dst, p_src);
      end if;
   end append;

   procedure append(
      p_dst in out nocopy clob, 
      p_src in varchar2)
   is
   begin
      if p_src is not null then
         dbms_lob.writeappend(p_dst, length(p_src), p_src);
      end if;
   end append;

   procedure append(
      p_dst in out nocopy clob, 
      p_src in xmltype)
   is
   begin
      append(p_dst, p_src.getclobval);
   end append;

   procedure append(
      p_dst in out nocopy xmltype, 
      p_src in clob)
   is
      l_dst   clob := p_dst.getclobval;
   begin
      append (l_dst, p_src);
      p_dst := xmltype (l_dst);
   END append;

   procedure append(
      p_dst in out nocopy xmltype, 
      p_src in varchar2)
   is
      l_dst   clob := p_dst.getclobval;
   begin
      append (l_dst, p_src);
      p_dst := xmltype (l_dst);
   END append;

   procedure append(
      p_dst in out nocopy xmltype, 
      p_src in xmltype)
   is
      l_dst   clob := p_dst.getclobval;
   begin
      append (l_dst, p_src);
      p_dst := xmltype (l_dst);
   END append;

   --------------------------
   -- XML Utility routines --
   --------------------------

   function get_xml_node (
      p_xml  in xmltype, 
      p_path in varchar)
   return xmltype
   is
   begin
      return case p_xml is null or p_path is null
             when true then null
             when false then p_xml.extract (p_path)
             end;
   end get_xml_node;
   
   function get_xml_attributes(
      p_xml  in xmltype,
      p_path in varchar2)
      return str_tab_t
   is
      l_names      str_tab_t; 
      l_values     str_tab_t; 
      l_attributes str_tab_t := str_tab_t();
      l_flwor      varchar2(32767);
   begin
      l_flwor := 'for $e in '||p_path||'/*/@* return name($e)';
      select element
        bulk collect
        into l_names
        from xmltable(l_flwor 
                      passing p_xml 
                      columns element varchar2(128) path '.'
                     );
      if l_names is not null and l_names.count > 0 then
         l_flwor := 'for $e in '||p_path||'/*/@* return $e';
         select element
           bulk collect
           into l_values
           from xmltable(l_flwor 
                         passing p_xml 
                         columns element varchar2(128) path '.'
                        );
         select n.text||'='||v.text
           bulk collect
           into l_attributes
           from (select column_value as text,
                        rownum as seq
                   from table(l_names)
                ) n
                join
                (select column_value as text,
                        rownum as seq
                   from table(l_values)
                ) v on v.seq=n.seq;                              
      end if;                     
      return l_attributes;                     
   end get_xml_attributes;      
      
   function get_xml_nodes(
      p_xml        in xmltype,
      p_path       in varchar2,
      p_condition  in varchar2 default null,
      p_order_by   in varchar2 default null,
      p_descending in varchar2 default 'F')
   return xml_tab_t  
   is
      l_flwor   varchar2(32767);
      l_results xml_tab_t;
   begin
      -------------------------------------
      -- build an XQuery FLWOR statement --
      -------------------------------------
      l_flwor := 'for $e in '||p_path;
      if p_condition is not null then
         l_flwor := l_flwor||' where '||replace(p_condition, p_path, '$e');
      end if;
      if p_order_by is not null then
         l_flwor := l_flwor||' order by '||replace(p_order_by, p_path, '$e');
         if return_true_or_false(p_descending) then
            l_flwor := l_flwor||' descending';
         end if;
      end if;
      l_flwor := l_flwor||' return $e';
      select element
        bulk collect
        into l_results
        from xmltable(
                l_flwor 
                passing p_xml
                columns element xmltype path '.'); -- included only for completeness
      return l_results;
   end get_xml_nodes;

   function get_xml_text(
      p_xml  in xmltype, 
      p_path in varchar)
   return varchar2
   is
      l_xml    xmltype;
      l_text   varchar2(32767);
   begin    
      l_xml := get_xml_node(p_xml, p_path);
      if l_xml is not null and instr(p_path, '/@') = 0 then
         l_xml := l_xml.extract('/node()/text()');
      end if;

      if l_xml is not null then
         l_text := regexp_replace(regexp_replace(l_xml.getstringval, '^\s+'), '\s+$');
      end if;
      return l_text;
   end get_xml_text;

   function get_xml_number(
      p_xml  in xmltype, 
      p_path in varchar)
   return number
   is
   begin
      return to_number(get_xml_text (p_xml, p_path));
   end get_xml_number;


   FUNCTION x_minus_y (p_list_1      IN VARCHAR2,
                       p_list_2      IN VARCHAR2,
                       p_separator   IN VARCHAR2 DEFAULT NULL)
      RETURN VARCHAR2
   IS
      l_list_1   str_tab_t;
      l_list_2   str_tab_t;
      l_list_3   str_tab_t;
   BEGIN
      l_list_1 := split_text (p_text => p_list_1, p_separator => p_separator);
      l_list_2 := split_text (p_text => p_list_2, p_separator => p_separator);

      SELECT *
        BULK COLLECT INTO l_list_3
        FROM (SELECT * FROM TABLE (l_list_1)
              MINUS
              SELECT * FROM TABLE (l_list_2));

      RETURN cwms_util.join_text (p_text_tab    => l_list_3,
                                  p_separator   => p_separator);
   END x_minus_y;


   PROCEDURE set_boolean_state (p_name IN VARCHAR2, p_state IN BOOLEAN)
   IS
   BEGIN
      set_boolean_state (
         p_name,
         CASE p_state WHEN TRUE THEN 'T' WHEN FALSE THEN 'F' END);
   END set_boolean_state;

   PROCEDURE set_boolean_state (p_name IN VARCHAR2, p_state IN CHAR)
   IS
      l_name   VARCHAR2 (64);
   BEGIN
      SELECT name
        INTO l_name
        FROM at_boolean_state
       WHERE UPPER (name) = UPPER (p_name);

      UPDATE at_boolean_state
         SET state = p_state
       WHERE name = l_name;
   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         INSERT INTO at_boolean_state
              VALUES (p_name, p_state);
   END set_boolean_state;

   FUNCTION get_boolean_state_char (p_name IN VARCHAR2)
      RETURN CHAR
   IS
      l_state   CHAR (1);
   BEGIN
      BEGIN
         SELECT state
           INTO l_state
           FROM at_boolean_state
          WHERE UPPER (name) = UPPER (p_name);
      EXCEPTION
         WHEN OTHERS
         THEN
            NULL;
      END;

      RETURN l_state;
   END get_boolean_state_char;

   FUNCTION get_boolean_state (p_name IN VARCHAR2)
      RETURN BOOLEAN
   IS
      l_state   CHAR (1);
   BEGIN
      l_state := get_boolean_state_char (p_name);
      RETURN CASE l_state IS NULL WHEN TRUE THEN NULL ELSE l_state = 'T' END;
   END get_boolean_state;

   PROCEDURE set_session_info (p_item_name   IN VARCHAR2,
                               p_txt_value   IN VARCHAR2,
                               p_num_value   IN NUMBER)
   IS
      l_item_name   VARCHAR2 (64);
   BEGIN
      -------------------
      -- sanity checks --
      -------------------
      IF p_item_name IS NULL
      THEN
         cwms_err.raise ('NULL_ARGUMENT', 'P_ITEM_NAME');
      END IF;

      -----------------------------
      -- insert/update the table --
      -----------------------------
      l_item_name := UPPER (TRIM (p_item_name));

      MERGE INTO at_session_info t
           USING (SELECT l_item_name AS item_name FROM DUAL) d
              ON (t.item_name = d.item_name)
      WHEN MATCHED
      THEN
         UPDATE SET str_value = p_txt_value, num_value = p_num_value
      WHEN NOT MATCHED
      THEN
         INSERT     VALUES (l_item_name, p_txt_value, p_num_value);
   END set_session_info;

   PROCEDURE set_session_info (p_item_name   IN VARCHAR2,
                               p_txt_value   IN VARCHAR2)
   IS
      l_item_name   VARCHAR2 (64);
   BEGIN
      -------------------
      -- sanity checks --
      -------------------
      IF p_item_name IS NULL
      THEN
         cwms_err.raise ('NULL_ARGUMENT', 'P_ITEM_NAME');
      END IF;

      -----------------------------
      -- insert/update the table --
      -----------------------------
      l_item_name := UPPER (TRIM (p_item_name));

      MERGE INTO at_session_info t
           USING (SELECT l_item_name AS item_name FROM DUAL) d
              ON (t.item_name = d.item_name)
      WHEN MATCHED
      THEN
         UPDATE SET str_value = p_txt_value
      WHEN NOT MATCHED
      THEN
         INSERT     VALUES (l_item_name, p_txt_value, NULL);
   END set_session_info;

   PROCEDURE set_session_info (p_item_name   IN VARCHAR2,
                               p_num_value   IN NUMBER)
   IS
      l_item_name   VARCHAR2 (64);
   BEGIN
      -------------------
      -- sanity checks --
      -------------------
      IF p_item_name IS NULL
      THEN
         cwms_err.raise ('NULL_ARGUMENT', 'P_ITEM_NAME');
      END IF;

      -----------------------------
      -- insert/update the table --
      -----------------------------
      l_item_name := UPPER (TRIM (p_item_name));

      MERGE INTO at_session_info t
           USING (SELECT l_item_name AS item_name FROM DUAL) d
              ON (t.item_name = d.item_name)
      WHEN MATCHED
      THEN
         UPDATE SET num_value = p_num_value
      WHEN NOT MATCHED
      THEN
         INSERT     VALUES (l_item_name, NULL, p_num_value);
   END set_session_info;

   PROCEDURE get_session_info (p_txt_value      OUT VARCHAR2,
                               p_num_value      OUT NUMBER,
                               p_item_name   IN     VARCHAR2)
   IS
      l_item_name   VARCHAR2 (64);
   BEGIN
      -------------------
      -- sanity checks --
      -------------------
      IF p_item_name IS NULL
      THEN
         cwms_err.raise ('NULL_ARGUMENT', 'P_ITEM_NAME');
      END IF;

      -------------------------
      -- retrieve the values --
      -------------------------
      l_item_name := UPPER (TRIM (p_item_name));

      BEGIN
         SELECT str_value, num_value
           INTO p_txt_value, p_num_value
           FROM at_session_info
          WHERE item_name = l_item_name;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            NULL;
      END;
   END get_session_info;

   FUNCTION get_session_info_txt (p_item_name IN VARCHAR2)
      RETURN VARCHAR2
   IS
      l_txt_value   VARCHAR2 (256);
      l_num_value   NUMBER;
   BEGIN
      get_session_info (l_txt_value, l_num_value, p_item_name);

      RETURN l_txt_value;
   END get_session_info_txt;

   FUNCTION get_session_info_num (p_item_name IN VARCHAR2)
      RETURN NUMBER
   IS
      l_txt_value   VARCHAR2 (256);
      l_num_value   NUMBER;
   BEGIN
      get_session_info (l_txt_value, l_num_value, p_item_name);

      RETURN l_num_value;
   END get_session_info_num;

   PROCEDURE reset_session_info (p_item_name IN VARCHAR2)
   IS
      l_item_name   VARCHAR2 (64);
   BEGIN
      -------------------
      -- sanity checks --
      -------------------
      IF p_item_name IS NULL
      THEN
         cwms_err.raise ('NULL_ARGUMENT', 'P_ITEM_NAME');
      END IF;

      -----------------------
      -- delete the record --
      -----------------------
      l_item_name := UPPER (TRIM (p_item_name));

      BEGIN
         DELETE FROM at_session_info
               WHERE item_name = l_item_name;
      EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            NULL;
      END;
   END reset_session_info;

   FUNCTION is_nan (p_value IN BINARY_DOUBLE)
      RETURN VARCHAR2
   IS
      l_is_nan   BOOLEAN := p_value IS NAN;
   BEGIN
      RETURN CASE l_is_nan WHEN TRUE THEN 'T' ELSE 'F' END;
   END is_nan;

   function sub_table(
      p_table in str_tab_t,
      p_first in integer,
      p_last  in integer default null)
      return str_tab_t
   is  
      l_last  integer;
      l_table str_tab_t;
   begin
      l_last := least(nvl(p_last, p_table.count), p_table.count);

      select trim(column_value)
        bulk collect
        into l_table
        from (select column_value,
                     rownum as seq
                from table(p_table)
             )
       where seq between p_first and l_last
       order by seq; 
       
      return l_table;                        
   end sub_table;

   function sub_table(
      p_table in number_tab_t,
      p_first in integer,
      p_last  in integer default null)
      return number_tab_t
   is  
      l_last  integer;
      l_table number_tab_t;
   begin
      l_last := least(nvl(p_last, p_table.count), p_table.count);

      select trim(column_value)
        bulk collect
        into l_table
        from (select column_value,
                     rownum as seq
                from table(p_table)
             )
       where seq between p_first and l_last
       order by seq; 
       
      return l_table;                        
   end sub_table;

   function sub_table(
      p_table in double_tab_t,
      p_first in integer,
      p_last  in integer default null)
      return double_tab_t
   is  
      l_last  integer;
      l_table double_tab_t;
   begin
      l_last := least(nvl(p_last, p_table.count), p_table.count);

      select trim(column_value)
        bulk collect
        into l_table
        from (select column_value,
                     rownum as seq
                from table(p_table)
             )
       where seq between p_first and l_last
       order by seq; 
       
      return l_table;                        
   end sub_table;
      
   function parse_unit_spec(
      p_unit_spec in varchar2,
      p_key       in varchar2)
      return varchar2
   is
      l_parts1 str_tab_t;
      l_parts2 str_tab_t;
      l_parsed varchar2(16);
      l_key    varchar2(1) := upper(trim(p_key));
      begin
      l_parts1 := split_text(p_unit_spec, '|');
      for i in 1..l_parts1.count loop
         l_parts2 := split_text(trim(l_parts1(i)), '=');
         if l_parts2.count = 2 and upper(trim(l_parts2(1))) = l_key then
            l_parsed := trim(l_parts2(2));
            exit;
         end if;
      end loop;
      return l_parsed;
   end parse_unit_spec;

   function parse_unit(
      p_unit_spec in varchar2)
      return varchar2
   is
   begin
      if instr(p_unit_spec, '=') > 0 then
         return parse_unit_spec(p_unit_spec, 'U');
      else
         return p_unit_spec;
      end if;
   end parse_unit;

   function parse_vertical_datum(
      p_unit_spec in varchar2)
      return varchar2
   is
   begin
      return parse_unit_spec(p_unit_spec, 'V');
   end parse_vertical_datum;

   function get_effective_vertical_datum(
      p_unit_spec in varchar2)
      return varchar2
   is
      l_vertical_datum varchar2(16);
   begin
      l_vertical_datum := parse_vertical_datum(p_unit_spec);
      if l_vertical_datum is null then
         l_vertical_datum := cwms_loc.get_default_vertical_datum;
      end if;
      l_vertical_datum := upper(trim(l_vertical_datum));
      if l_vertical_datum = 'NULL' then
         l_vertical_datum := null;
      end if;
      return l_vertical_datum;
   end get_effective_vertical_datum;

   procedure check_dynamic_sql(
      p_sql in varchar2)
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
         cwms_err.raise(
            'ERROR',
            'UNSAFE DYNAMIC SQL : '||p_sql);
      end if;
   end check_dynamic_sql;      

   
   function get_url(
      p_url     in varchar2,
      p_timeout in integer default 60)
      return clob
   is
      l_req  utl_http.req;
      l_resp utl_http.resp;
      l_buf  varchar2(32767);
      l_clob clob;
      
      procedure write_clob(p_text in varchar2)
      is
         l_len binary_integer := length(p_text);
      begin
         dbms_lob.writeappend(l_clob, l_len, p_text);
      end;
   begin       
      dbms_lob.createtemporary(l_clob, true);
      dbms_lob.open(l_clob, dbms_lob.lob_readwrite);   
   begin
         utl_http.set_transfer_timeout(p_timeout);
         l_req := utl_http.begin_request(p_url);
         utl_http.set_header(l_req, 'User-Agent', 'Mozilla/4.0');
         l_resp := utl_http.get_response(l_req);
         utl_http.set_transfer_timeout;
          loop                             
            utl_http.read_text(l_resp, l_buf);
            write_clob(l_buf);
         end loop;
      exception
         when utl_http.end_of_body then
            utl_http.end_response(l_resp);
            
         when others then
            begin
               utl_http.end_response(l_resp);
            exception
               when others then null;
            end;
            raise;
      end;
      dbms_lob.close(l_clob);
      return l_clob;
   end get_url;      
   
   function get_column(
      p_table  in double_tab_tab_t,
      p_column in pls_integer)
      return double_tab_t
   is
      l_results double_tab_t;
      l_count   pls_integer;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_table is null then
         cwms_err.raise('NULL_ARGUMENT', 'p_table');
      end if;
      if p_column is null then
         cwms_err.raise('NULL_ARGUMENT', 'p_column');
      end if;
      select count(*) into l_count from table(p_table) where column_value is null;
      if l_count != 0 then 
         cwms_err.raise(
            'ERROR',
            'Table has one or more null rows');
      end if;
      l_count := p_table(1).count;
      if not p_column between 1 and l_count then
         cwms_err.raise(
            'ERROR',
            'Specified column ('
            ||p_column
            ||') is not valid for a table of width '
            ||l_count);
      end if;
      select value_in_column
        bulk collect
        into l_results 
        from (select t2.column_value as value_in_column, 
                     rownum as r 
                from table(p_table) t1,
                     table(t1.column_value) t2
               where t2.column_value in (select column_value from table(t1.column_value))             
             )
             where mod(r, l_count) = mod(p_column, l_count);
      return l_results;
   end get_column;            
   
    FUNCTION str2tbl (p_str IN VARCHAR2, p_delim IN VARCHAR2 DEFAULT ',')
       RETURN str2tblType
       PIPELINED
    AS
       l_str   LONG DEFAULT p_str || p_delim;
       l_n     NUMBER;
    BEGIN
       LOOP
          l_n := INSTR (l_str, p_delim);
          EXIT WHEN (NVL (l_n, 0) = 0);
          PIPE ROW (LTRIM (RTRIM (SUBSTR (l_str, 1, l_n - 1))));
          l_str := SUBSTR (l_str, l_n + 1);
       END LOOP;

       RETURN;
    END;

   function get_column(
      p_table  in str_tab_tab_t,
      p_column in pls_integer)
      return str_tab_t
   is
      l_results str_tab_t;
      l_count   pls_integer;
   begin
      -------------------
      -- sanity checks --
      -------------------
      if p_table is null then
         cwms_err.raise('NULL_ARGUMENT', 'p_table');
      end if;
      if p_column is null then
         cwms_err.raise('NULL_ARGUMENT', 'p_column');
      end if;
      select count(*) into l_count from table(p_table) where column_value is null;
      if l_count != 0 then 
         cwms_err.raise(
            'ERROR',
            'Table has one or more null rows');
      end if;
      l_count := p_table(1).count;
      if not p_column between 1 and l_count then
         cwms_err.raise(
            'ERROR',
            'Specified column ('
            ||p_column
            ||') is not valid for a table of width '
            ||l_count);
      end if;
      select value_in_column
        bulk collect
        into l_results 
        from (select t2.column_value as value_in_column, 
                     rownum as r 
                from table(p_table) t1,
                     table(t1.column_value) t2
               where t2.column_value in (select column_value from table(t1.column_value))             
             )
             where mod(r, l_count) = mod(p_column, l_count);
      return l_results;
   end get_column;            

   procedure to_json(
      p_json     in out nocopy clob,
      p_xml      in     xmltype,
      p_in_array in     boolean default false)
   is
      type bool_by_string_t is table of boolean index by varchar2(32767);         
      not_a_number exception;
      pragma exception_init(not_a_number, -6502);
      l_name     varchar2(128);
      l_nodes    xml_tab_t; 
      l_attrs    str_tab_t;
      l_text     varchar2(32767);
      l_number   number;
      l_parts    str_tab_t;
      l_array    boolean;
      l_names    str_tab_t;
      l_node_pos number_tab_t;
   begin
      l_name  := p_xml.getrootelement;
      l_attrs := get_xml_attributes(p_xml, '');
      l_nodes := get_xml_nodes(p_xml, '/*/*');
      l_text  := get_xml_text(p_xml, '/');
      
      if not p_in_array then                                     
         append(p_json, ' "'||l_name||'":');
      end if;  
      if l_attrs.count = 0 and l_nodes.count = 0 and l_text is null then
         ----------------------------------
         -- no attributes and no content --
         ----------------------------------
         append(p_json, 'null');
      else
         -------------------------------
         -- attributes and/or content --
         -------------------------------
         l_array := l_attrs.count + l_nodes.count + case l_text is null when true then 0 else 1 end > 1;
         if l_array then append(p_json, '['); end if; 
         if l_attrs.count > 0 then
            ----------------
            -- attributes --
            ----------------
            append(p_json, '{');
            for i in 1..l_attrs.count loop
               if i > 1 then append(p_json, ', '); end if;
               append(p_json, replace(regexp_replace(l_attrs(i), '(.+)\s*=\s*(.+)', '"@\1" : "\2"'), '""', '"'));
            end loop;
            append(p_json, '}');
         end if;
         if l_nodes.count > 0 then
            ---------------------
            -- element content --
            ---------------------
            if l_attrs.count > 0 then append(p_json, ','); end if;
            append(p_json, '{');
            -----------------------------------------------------------------
            -- determine if there are multiple elements with the same name --
            -----------------------------------------------------------------
            l_names := str_tab_t();
            for i in 1..l_nodes.count loop
               l_name := l_nodes(i).getrootelement;
               select count(*) into l_number from table(l_names) where column_value = l_name;
               if l_number = 0 then
                  l_names.extend;
                  l_names(l_names.count) := l_name;
               end if;
            end loop;
            if l_names.count < l_nodes.count then
               -----------------------------------------------
               -- at least some elements have the same name --
               -----------------------------------------------
               for i in 1..l_names.count loop
                  l_node_pos := number_tab_t();
                  -----------------------------
                  -- index the nodes by name --
                  -----------------------------
                  for j in 1..l_nodes.count loop
                     if l_nodes(j).getrootelement = l_names(i) then
                        l_node_pos.extend;
                        l_node_pos(l_node_pos.count) := j;
                     end if;
                  end loop;
                  if i > 1 then append(p_json, ','); end if;
                  if l_node_pos.count = 1 then
                     ---------------------------------
                     -- this name has only one node --
                     ---------------------------------
                     to_json(p_json, l_nodes(l_node_pos(1)));
                  else
                     ----------------------------------                   
                     -- this name has multiple nodes --
                     ----------------------------------                   
                     append(p_json, '"'||l_names(i)||'":[');
                     for j in 1..l_node_pos.count loop
                        if j > 1 then append(p_json, ','); end if;
                        to_json(p_json, l_nodes(l_node_pos(j)), p_in_array => true);
                     end loop;
                     append(p_json, ']');
                  end if;
               end loop;
            else
               ---------------------------------
               -- no nodes have the same name --
               ---------------------------------
               for i in 1..l_nodes.count loop
                  if i > 1 then append(p_json, ','); end if;
                  to_json(p_json, l_nodes(i));
               end loop;
            end if;              
            append(p_json, '}');
         elsif l_text is not null then
            -------------------
            -- CDATA content --
            -------------------
            if l_attrs.count > 0 then append(p_json, ','); end if;
            begin
               --------------
               -- numeric? --
               --------------
               l_number := to_number(l_text);
               l_text := regexp_replace(l_text, '(^|[^0-9])\.', '\10.'); -- add leading zero for JSON
            exception
               -----------------
               -- not numeric --
               -----------------
               when not_a_number then l_text := '"'||replace(l_text, '"', '\"')||'"';
            end;
            append(p_json, l_text);
         end if;
         if l_array then append(p_json, ']'); end if; 
      end if;
   end to_json;
         
   function to_json(
      p_xml in xmltype)
      return clob
   is
      l_json clob;
   begin
      dbms_lob.createtemporary(l_json, true);
      append(l_json, '{');
      to_json(l_json, p_xml);
      append(l_json, '}');
      return l_json;
   end to_json;      
               
   FUNCTION is_irregular_code (
      p_interval_code   IN CWMS_INTERVAL.INTERVAL_CODE%TYPE)
      RETURN BOOLEAN
   IS
      l_interval_dur   CWMS_INTERVAL.INTERVAL%TYPE;
   BEGIN
      BEGIN
         SELECT interval
           INTO l_interval_dur
           FROM cwms_interval ci
          WHERE interval_code = p_interval_code;
      EXCEPTION
         WHEN OTHERS
         THEN
            RAISE;
      END;

      IF (l_interval_dur = 0)
      THEN
         RETURN TRUE;
      ELSE
         RETURN FALSE;
      END IF;
   END is_irregular_code;

   procedure check_office_permission(
      p_office_id     in varchar2,
      p_user_group_id in varchar2 default null)
   is
      l_user_id       varchar2(30); 
      l_office_id     varchar2(16);
      l_user_group_id varchar2(32);
   begin
      l_user_id := get_user_id;
      if l_user_id != '&cwms_schema' then
         l_office_id := cwms_util.get_db_office_id(p_office_id);
         if p_user_group_id is null then
            l_user_group_id := 'All Users';
         else
            l_user_group_id := p_user_group_id;
         end if;
         select db_office_id 
           into l_office_id     
           from table(cwms_sec.get_assigned_priv_groups_tab)
          where upper(user_group_id) = upper(l_user_group_id)
            and is_member = 'T'
            and db_office_id = l_office_id; 
      end if;
   exception 
      when no_data_found then
         cwms_err.raise(
            'ERROR', 
            'User '
            ||get_user_id
            ||' does not have '
            ||l_user_group_id
            ||' permission for office '
            ||l_office_id);
   end check_office_permission;

   function cat_scheduled_jobs(
      p_job_name_mask in varchar2 default '*')
      return sys_refcursor
   is
      l_cursor sys_refcursor;
   begin
      open l_cursor for
         select j.job_name,
                j.repeat_interval,
                j.run_count,
                j.failure_count,
                j.state,
                cast(j.last_start_date as date) as last_start_time,
                j.last_run_duration,
                cast(j.next_run_date as date) as next_run_time,
                d.status
           from user_scheduler_jobs j,
                user_scheduler_job_run_details d
          where j.job_name like normalize_wildcards(upper(p_job_name_mask)) escape '\'
            and d.job_name = j.job_name
            and cast(d.actual_start_date as date) = cast(j.last_start_date as date)
          order by 1;
          
      return l_cursor;          
   end cat_scheduled_jobs;
   
   function cat_scheduled_job_history(
      p_job_name in varchar2)
      return sys_refcursor
   is
      l_cursor sys_refcursor;
   begin
      open l_cursor for
         select cast(actual_start_date as date) as start_time,
                run_duration,
                status
           from user_scheduler_job_run_details
          where job_name = upper(p_job_name)
          order by 1;
      
      return l_cursor;
   end cat_scheduled_job_history;

   function tab_to_csv(
      p_tab in clob)
      return clob
   is
      l_table str_tab_tab_t;
      l_csv   clob;
   begin
      dbms_lob.createtemporary(l_csv, true);
      select cwms_util.split_text(column_value, chr(9))
        bulk collect
        into l_table
        from table(cwms_util.split_text(p_tab, chr(10)));
      for i in 1..l_table.count loop
         for j in 1..l_table(i).count loop
            if instr(l_table(i)(j), ',') > 0 then
               l_table(i)(j) := '"'||l_table(i)(j)||'"';
            end if;
         end loop;
         if i > 1 then
            cwms_util.append(l_csv, chr(10)||cwms_util.join_text(l_table(i), ',')); 
         else
            cwms_util.append(l_csv, cwms_util.join_text(l_table(i), ',')); 
         end if;
      end loop;
      return l_csv;
   end tab_to_csv;
   
   function tab_to_csv(
      p_tab in varchar2)
      return varchar2
   is
      l_table str_tab_tab_t;
      l_csv   varchar2(32767);
   begin
      dbms_lob.createtemporary(l_csv, true);
      select cwms_util.split_text(column_value, chr(9))
        bulk collect
        into l_table
        from table(cwms_util.split_text(p_tab, chr(10)));
      for i in 1..l_table.count loop
         for j in 1..l_table(i).count loop
            if instr(l_table(i)(j), ',') > 0 then
               l_table(i)(j) := '"'||l_table(i)(j)||'"';
            end if;
         end loop;
         if i > 1 then
            l_csv := l_csv||chr(10)||cwms_util.join_text(l_table(i), ','); 
         else
            l_csv := l_csv||cwms_util.join_text(l_table(i), ','); 
         end if;
      end loop;
      return l_csv;
   end tab_to_csv;

/*
BEGIN
 -- anything put here will be executed on every mod_plsql call
  NULL;
*/

END cwms_util;
/

SHOW ERRORS;

set define on
define cwms_schema = CWMS_20
prompt update for package spec ../cwms_dba/cwms_user_admin
/* Formatted on 6/21/2009 8:40:43 AM (QP5 v5.115.810.9015) */
create or replace package cwms_dba.cwms_user_admin
AS
	/******************************************************************************
		 NAME:		 cwms_admin
		  PURPOSE:

		 REVISIONS:
		  Ver 		  Date		 Author				Description
		---------  ----------  --------------- ------------------------------------
		1.0			10/6/2008				1. Created this package.
	******************************************************************************/

	PROCEDURE lock_db_account (p_username IN VARCHAR2 DEFAULT NULL );

	PROCEDURE unlock_db_account (p_username IN VARCHAR2 DEFAULT NULL );

	PROCEDURE create_cwmsdbi_db_account (p_username   IN VARCHAR2,
													 p_password   IN VARCHAR2 DEFAULT NULL
													);

    PROCEDURE create_cwms_service_account (p_username 		IN VARCHAR2,
                                          p_password 		IN VARCHAR2                                          
												);
												
	PROCEDURE delete_db_account (p_username IN VARCHAR2 DEFAULT NULL );

    PROCEDURE create_cwms_db_account (p_username         IN VARCHAR2, p_password in varchar2,
                                                 p_dbi_username    IN VARCHAR2
                                                );

	PROCEDURE set_user_password (p_username	IN VARCHAR2,
										  p_password	IN VARCHAR2
										 );
        PROCEDURE grant_rdl_role (p_role VARCHAR2, p_username VARCHAR2);
	PROCEDURE revoke_rdl_role (p_role VARCHAR2, p_username VARCHAR2);
        PROCEDURE update_service_password(p_username VARCHAR2,p_password VARCHAR2);
END cwms_user_admin;
/

set define on
define cwms_schema = CWMS_20
prompt update for package body ../cwms_dba/cwms_user_admin
/* Formatted on 7/10/2009 1:37:43 PM (QP5 v5.115.810.9015) */
create or replace package BODY cwms_dba.cwms_user_admin
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
		DBMS_OUTPUT.put_line (l_sql_string);
      check_dynamic_sql(l_sql_string);

		EXECUTE IMMEDIATE l_sql_string;
	END;

	PROCEDURE unlock_db_account (p_username IN VARCHAR2 DEFAULT NULL )
	AS
		l_sql_string						VARCHAR2 (400);
	BEGIN
		l_sql_string := 'ALTER user ' || p_username || ' account unlock';
		DBMS_OUTPUT.put_line (l_sql_string);
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
		DBMS_OUTPUT.put_line (l_sql_string);
        check_dynamic_sql(l_sql_string);

		EXECUTE IMMEDIATE l_sql_string;

		l_sql_string := 'GRANT CWMS_USER TO ' || dbms_assert.simple_sql_name(p_username);
		DBMS_OUTPUT.put_line (l_sql_string);
        check_dynamic_sql(l_sql_string);

		EXECUTE IMMEDIATE l_sql_string;

	END create_cwms_service_account;

	PROCEDURE create_cwmsdbi_db_account (p_username   IN VARCHAR2,
													 p_password   IN VARCHAR2 DEFAULT NULL
													)
	AS
		l_sql_string						VARCHAR2 (60);
	BEGIN
		create_db_account (p_username, p_password);

		l_sql_string := 'GRANT CREATE SESSION TO ' || p_username;
		DBMS_OUTPUT.put_line (l_sql_string);

                check_dynamic_sql(l_sql_string);
		EXECUTE IMMEDIATE l_sql_string;
	END;

	PROCEDURE create_cwms_db_account (p_username 		IN VARCHAR2,
                                          p_password 		IN VARCHAR2,
                                          p_dbi_username IN VARCHAR2
												)
	AS
		l_sql_string						VARCHAR2 (400);
	BEGIN
		create_db_account (p_username, p_password);

		l_sql_string := 'GRANT CONNECT TO ' || dbms_assert.simple_sql_name(p_username);
		DBMS_OUTPUT.put_line (l_sql_string);
      check_dynamic_sql(l_sql_string);

		EXECUTE IMMEDIATE l_sql_string;

		l_sql_string := 'GRANT CWMS_USER TO ' || dbms_assert.simple_sql_name(p_username);
		DBMS_OUTPUT.put_line (l_sql_string);
      check_dynamic_sql(l_sql_string);

		EXECUTE IMMEDIATE l_sql_string;
		l_sql_string :=
				'ALTER user '
			|| p_username
			|| ' GRANT CONNECT THROUGH '
			|| p_dbi_username;
		DBMS_OUTPUT.put_line (l_sql_string);

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

set define on
define cwms_schema = CWMS_20
prompt update for script compileAll
set echo off
set define on
whenever sqlerror exit sql.sqlcode
prompt Invalid objects...
  select substr(object_name, 1, 31) "INVALID OBJECT", object_type
    from dba_objects
   where owner = '&cwms_schema'
     and status = 'INVALID'
order by object_name, object_type asc;

prompt Recompiling all invalid objects...
exec sys.utl_recomp.recomp_serial('&cwms_schema');
--  Some of the packages/types don't compile first time
commit;
exec dbms_lock.sleep(10);
exec sys.utl_recomp.recomp_serial('&cwms_schema');
/

prompt Remaining invalid objects...
  select substr(object_name, 1, 31) "INVALID OBJECT", object_type
    from dba_objects
   where owner = '&cwms_schema'
     and status = 'INVALID'
order by object_name, object_type asc;

declare
   obj_count integer;
begin
   select count(*)
     into obj_count
     from dba_objects
    where owner = '&cwms_schema'
      and status = 'INVALID';
   if obj_count > 0 then
      dbms_output.put_line('' || obj_count || ' objects are still invalid.');
      raise_application_error(-20999, 'Some objects are still invalid.');
   else
      dbms_output.put_line('All invalid objects successfully compiled.');
   end if;
end;
/


set define on
define cwms_schema = CWMS_20
prompt update for script cwms_version
whenever sqlerror continue;

insert into cwms_db_change_log (application,
                              ver_major,
                              ver_minor,
                              ver_build,
                              ver_date,
                              title,
                              description)
     values ('CWMS',
             3,
             0,
             7,
             to_date ('10MAR2017', 'DDMONYYYY'),
             'CWMS Database Release 3.0.7',
             'Support for CAC authentication');
commit;
whenever sqlerror exit;



commit;

CREATE OR REPLACE FUNCTION CHECK_SESSION_USER(
  schema_p   IN VARCHAR2,
  table_p    IN VARCHAR2)
 RETURN VARCHAR2
 AS

 BEGIN
  if dbms_mview.i_am_a_refresh then
   return null;
  end if;
  IF ((SYS_CONTEXT ('CWMS_ENV', 'CWMS_USER') IS NULL) AND (USER = 'CWMS9999'))
  THEN
    return '1=0';
  ELSE
    return '1=1';
  END IF;
END CHECK_SESSION_USER;
/

BEGIN
    for c IN (select table_name from user_tables WHERE table_name <> 'AT_SEC_SESSION')
    loop
        begin
           DBMS_RLS.ADD_POLICY (
           object_schema    => '&cwms_schema',
           object_name      => c.table_name,
           policy_name      => 'SERVICE_USER_POLICY',
           function_schema  => '&cwms_schema',
           policy_function  => 'CHECK_SESSION_USER',
           statement_types  => 'select');
        exception
            when others then
                if instr(sqlerrm, 'policy already exists') > 0 then
                    null;
                else
                    raise;
                end if;    
        end;
    end loop;
END;
/

exec cwms_sec.create_cwms_service_user;
exec  cwms_sec.start_clean_session_job;
exit;

