CREATE OR REPLACE PACKAGE cwms_env
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
   /**
    *
    * To be used only by WEB API accounts that responsibly check user
    * validity.
    * @parameter p_user The user to perform operations as
   */
   PROCEDURE set_session_user_direct(p_user VARCHAR2);
END cwms_env;
/

SHOW error;
