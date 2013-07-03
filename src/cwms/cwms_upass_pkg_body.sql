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
   l_msgid NUMBER;
   BEGIN
      IF ( ( (UPPER (p_control_code)) = 'C') OR ( (UPPER (p_control_code)) = 'A'))
      THEN
         cwms_sec.update_user_data (p_userid,
                                         p_firstname || ' ' || 
                                         p_middlename || ' ' ||
                                         p_firstname,
                                         p_org,
                                         p_office,
                                         p_phone,
                                         p_email);
      ELSIF ( (UPPER (p_control_code)) = 'D')
      THEN
         CWMS_SEC.DELETE_USER (p_userid);
      ELSE
         l_msgid := CWMS_MSG.LOG_MESSAGE ('UPASS',
                               NULL,
                               NULL,
                               NULL,
                               SYSTIMESTAMP AT TIME ZONE 'UTC',
                               'Invalid UPASS update code',
                               CWMS_MSG.MSG_LEVEL_NORMAL,
                               TRUE,
                               FALSE);
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         l_msgid := CWMS_MSG.LOG_MESSAGE (
            'UPASS',
            NULL,
            NULL,
            NULL,
            SYSTIMESTAMP AT TIME ZONE 'UTC',
            'Exception while update user metadata in UPASS: '
            || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE,
            CWMS_MSG.MSG_LEVEL_NORMAL,
            TRUE,
            FALSE);
   END update_cwms_user;
END cwms_upass;
/

