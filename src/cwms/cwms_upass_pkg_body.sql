CREATE OR REPLACE PACKAGE BODY cwms_upass
AS
   PROCEDURE update_cwms_user (p_userid         IN VARCHAR2,
                               p_lastname       IN VARCHAR2,
                               p_middlename     IN VARCHAR2,
                               p_firstname      IN VARCHAR2,
                               p_org            IN VARCHAR2,
                               p_office         IN VARCHAR2,
                               p_phone          IN VARCHAR2,
                               p_email          IN VARCHAR2,
                               p_control_code   IN VARCHAR2)
   IS
   BEGIN
      IF ( ( (UPPER (p_control_code)) = 'C') OR ( (UPPER (p_control_code)) = 'A'))
      THEN
         cwms_sec.update_user_data (p_userid,
                                         p_firstname || ' ' || 
                                         p_middlename || ' ' ||
                                         p_lastname,
                                         p_org,
                                         p_office,
                                         p_phone,
                                         p_email);
         commit;
      ELSIF ( (UPPER (p_control_code)) = 'D')
      THEN
         CWMS_SEC.DELETE_UPASS_USER (p_userid);
      ELSE
	CWMS_MSG.LOG_DB_MESSAGE ('UPASS',
                                  CWMS_MSG.MSG_LEVEL_NORMAL,
                                  'Invalid UPASS update code');
        commit;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
	CWMS_MSG.LOG_DB_MESSAGE (
            'UPASS',
            CWMS_MSG.MSG_LEVEL_NORMAL,
               'Exception while update user metadata in UPASS: '
            || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
   END update_cwms_user;
END cwms_upass;
/

