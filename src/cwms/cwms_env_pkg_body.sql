CREATE OR REPLACE PACKAGE BODY cwms_env
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

   PROCEDURE set_session_privileges
   IS
      l_office_id   VARCHAR2 (16);
      l_username    VARCHAR2 (32);
      l_canwrite    BOOLEAN;
      l_cnt         NUMBER;
   BEGIN
      l_canwrite := FALSE;
      l_cnt := 0;
      l_username := user;


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
