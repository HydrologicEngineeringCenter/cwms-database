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
      l_office_id_attr   VARCHAR2 (30) := 'SESSION_OFFICE_ID';
      l_office_code_attr   VARCHAR2 (30) := 'SESSION_OFFICE_CODE';
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
         SET_CWMS_ENV (l_office_id_attr, l_office_id);
         SET_CWMS_ENV (l_office_code_attr, CWMS_UTIL.GET_DB_OFFICE_CODE(l_office_id));
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
    set_cwms_env('CWMS_SESSION_KEY',p_session_key);
    set_session_privileges;
   END set_session_user;

   PROCEDURE set_session_user_direct(p_user VARCHAR2)
   IS
      l_userid VARCHAR2(32);
      l_role varchar2(32) := null;
   BEGIN
      select granted_role into l_role from dba_role_privs where granted_role='WEB_USER' and grantee=USER;
      set_cwms_env('CWMS_USER',p_user);
      set_session_privileges;
   exception
      when no_data_found then
         cwms_err.raise(
               'ERROR',
               'Permission Denied. Only accounts with the WEB_USER role can use this function');
   END set_session_user_direct;

   PROCEDURE set_session_privileges
   IS
      l_office_id   VARCHAR2 (16);
      l_username    VARCHAR2 (32);
      l_canwrite    BOOLEAN;
      l_canlogin    BOOLEAN;
      l_cnt         NUMBER;
      l_rdl_privilege VARCHAR2(16);
      l_ccp_privilege INTEGER;
   BEGIN
      l_canwrite := FALSE;
      l_canlogin := FALSE;
      l_cnt := 0;
      l_rdl_privilege := 'NONE';
      l_ccp_privilege := 4;
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

     FOR C IN (SELECT user_group_id FROM TABLE (cwms_sec.get_assigned_priv_groups_tab) WHERE db_office_id = l_office_id)
      LOOP
        l_canlogin := TRUE;
        IF((C.user_group_id='CCP Mgr') OR 
            (C.user_group_id='CCP Proc') OR
            (C.user_group_id='CWMS DBA Users') OR
            (C.user_group_id='CWMS PD Users') OR
            (C.user_group_id='CWMS User Admins') OR
            (C.user_group_id='Data Acquisition Mgr') OR
            (C.user_group_id='Data Exchange Mgr') OR
            (C.user_group_id='TS ID Creator') OR
            (C.user_group_id='VT Mgr'))
        THEN
            l_canwrite := TRUE;
        END IF;
        IF(c.user_group_id='RDL Mgr')
        THEN
            l_rdl_privilege := 'RDLCRUD';
        END IF;
        IF(c.user_group_id='RDL Reviewer')
        THEN
            IF(l_rdl_privilege = 'NONE')
            THEN
                l_rdl_privilege := 'RDLREAD';
            END IF;
        END IF;
        IF(c.user_group_id='CCP Mgr')
        THEN
            l_ccp_privilege := 1;
        END IF;
        IF(c.user_group_id='CCP Proc')
        THEN
            IF(l_ccp_privilege > 1)
            THEN
                l_ccp_privilege := 2;
            END IF;
        END IF;
        IF(c.user_group_id='CCP Reviewer') 
        THEN
            IF(l_ccp_privilege > 2)
            THEN
                l_ccp_privilege := 3;
            END IF;
        END IF;
        
      END LOOP;
      

      IF (l_canwrite)
      THEN
         set_cwms_env ('CWMS_PRIVILEGE', 'CAN_WRITE');
      ELSIF (l_canlogin)
      THEN
         set_cwms_env ('CWMS_PRIVILEGE', 'CAN_LOGIN');
      END IF;
      
      set_cwms_env('RDL_PRIVILEGE',l_rdl_privilege);
      set_cwms_env('CCP_PRIV_LEVEL',l_ccp_privilege);
   END set_session_privileges;
END cwms_env;
/
show errors;