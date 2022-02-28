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
    * @parameter p_office The office for a particular session.
   */
   PROCEDURE set_session_user_direct(p_user VARCHAR2, p_office VARCHAR2 default NULL);

   /**
    * For user by WEB_USER accounts, set the role given the provided apikey
    *
    * @parameter p_apikey A user authorization token with a user defined (default 1 day) lifetime.
    * @parameter p_office The office required for a particular session.
    *
   */
   PROCEDURE set_session_user_apikey(p_apikey VARCHAR2, p_office VARCHAR2 default NULL);
END cwms_env;
/
