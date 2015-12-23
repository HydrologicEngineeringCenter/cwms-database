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
   PROCEDURE clear_session_privileges;
END cwms_env;
/

SHOW error;
