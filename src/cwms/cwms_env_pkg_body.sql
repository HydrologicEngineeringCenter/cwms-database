CREATE OR REPLACE PACKAGE BODY cwms_env
AS



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
   END;
END cwms_env;
/