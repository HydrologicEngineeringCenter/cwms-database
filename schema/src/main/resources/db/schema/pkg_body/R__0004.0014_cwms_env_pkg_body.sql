CREATE OR REPLACE PACKAGE BODY cwms_env
AS
   procedure pause_office_caching
   is
   begin
      cwms_cache.disable(cwms_util.g_office_id_cache);
      cwms_cache.disable(cwms_util.g_office_code_cache);
   end pause_office_caching;

   procedure resume_office_caching
   is
   begin
      cwms_cache.enable(cwms_util.g_office_id_cache);
      cwms_cache.enable(cwms_util.g_office_code_cache);

      cwms_cache.remove(cwms_util.g_office_id_cache, '<NULL>');
      cwms_cache.remove(cwms_util.g_office_code_cache, '<NULL>');
   end resume_office_caching;

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

   /**
    * Helper to deal with permissions. If the previous set user doesn't have correct permissions
    * this call to log_db_message will fail, however since this is called in the CWMS_ENV
    * package we know it's a authorized user (the connection)
    * so we elevate the privilege temporarily.
    * Perhaps we should add a specific "CAN_LOG" privilege could also just check for WEB_USER role
    * in the trigger
   */
   procedure log(p_procedure in varchar2, p_msg_level in integer, p_message   in varchar2)
   is
      l_priv varchar2(255) := SYS_CONTEXT('CWMS_ENV','CWMS_PRIVILEGE');
      l_cur_office varchar2(5) := SYS_CONTEXT('CWMS_ENV','SESSION_OFFICE_ID');
      l_cur_office_code cwms_office.office_code%type := NULL;
   begin
      pause_office_caching;
      if l_cur_office is not null then
         l_cur_office_code := CWMS_UTIL.GET_DB_OFFICE_CODE(l_cur_office);
      end if;
      -- set environment so logging works
      set_cwms_env ('CWMS_PRIVILEGE', 'CAN_WRITE');
      set_cwms_env ('SESSION_OFFICE_ID', 'CWMS');
      set_cwms_env ('SESSION_OFFICE_CODE', CWMS_UTIL.GET_DB_OFFICE_CODE('CWMS'));

      -- The actual thing this function is supposed to do
      cwms_msg.log_db_message(p_procedure,p_msg_level,p_message);

      -- reset environment back so security works
      set_cwms_env ('CWMS_PRIVILEGE', l_priv);
      set_cwms_env ('SESSION_OFFICE_ID', l_cur_office);
      set_cwms_env ('SESSION_OFFICE_CODE', l_cur_office_code);
      resume_office_caching;
   end;


   PROCEDURE set_session_office_id (p_office_id IN VARCHAR2)
   IS
      l_office_id_attr   VARCHAR2 (30) := 'SESSION_OFFICE_ID';
      l_office_code_attr   VARCHAR2 (30) := 'SESSION_OFFICE_CODE';
      l_office_id   VARCHAR2 (16);
      l_office_code cwms_office.office_code%type;
      --
      l_cnt         NUMBER;
      l_username    VARCHAR2 (31) := CWMS_UTIL.get_user_id();
   BEGIN
      BEGIN
         pause_office_caching;
         l_office_id := CWMS_UTIL.GET_DB_OFFICE_ID (p_office_id);
         l_office_code := CWMS_UTIL.get_db_office_code(l_office_id);
      EXCEPTION
         WHEN OTHERS
         THEN
            resume_office_caching;
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
        FROM at_sec_users
        WHERE db_office_code = l_office_code
          AND username = l_username;

      IF l_cnt > 0
      THEN
         SET_CWMS_ENV (l_office_id_attr, l_office_id);
         SET_CWMS_ENV (l_office_code_attr, l_office_code);
         SET_SESSION_PRIVILEGES;
      ELSE
         resume_office_caching;
         cwms_err.raise (
            'ERROR',
               'Unable to set SESSION_OFFICE_ID to: '
            || l_office_id
            || ' because user: '
            || l_username
            || ' does not have any assigned privileges for that office.');
      END IF;
      resume_office_caching;
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

   PROCEDURE set_session_user_direct(p_user VARCHAR2, p_office VARCHAR2)
   IS
      l_userid VARCHAR2(32);
      l_role varchar2(32) := null;
      l_msg varchar(2048);
      l_from_ip varchar(255) := SYS_CONTEXT('USERENV','IP_ADDRESS');
   BEGIN
      select granted_role into l_role from dba_role_privs where granted_role='WEB_USER' and grantee=USER;
      l_msg := 'Login: ' || 'Session set to user ''' || p_user || ''' by '
                         || USER || ' from host ' || l_from_ip;
      log('set_session_user_direct',cwms_msg.msg_level_basic,l_msg);
      set_cwms_env('CWMS_USER',p_user);
      if p_office is not null then
         set_session_office_id(p_office);
      else
         clear_session_privileges; -- set back to read only
      end if;
   exception
      when no_data_found then
         l_msg := 'Unauthorized attempt to set user context by ' || USER || ' from ' || l_from_ip;
         log('set_session_user_direct',cwms_msg.msg_level_basic,l_msg);
         cwms_err.raise(
               'ERROR',
               'Permission Denied. Only accounts with the WEB_USER role can use this function');
     when others then
        clear_session_privileges;
        raise;
   END set_session_user_direct;

   PROCEDURE set_session_user_apikey(p_apikey VARCHAR2, p_office VARCHAR2)
   IS
      l_userid VARCHAR2(32) := null;
   BEGIN
      select userid into l_userid from cwms_20.av_active_api_keys where apikey = p_apikey;
      set_session_user_direct(l_userid,p_office);
   end set_session_user_apikey;

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
