CREATE OR REPLACE PACKAGE cwms_upass
AS
   PROCEDURE update_user_data (p_userid     IN VARCHAR2,
                               p_fullname   IN VARCHAR2,
                               p_org        IN VARCHAR2,
                               p_office     IN VARCHAR2,
                               p_phone      IN VARCHAR2,
                               p_email      IN VARCHAR2);

   PROCEDURE update_cwms_user (p_userid        IN VARCHAR2,
                               p_lastname      IN VARCHAR2,
                               p_middlename   IN VARCHAR2,
                               p_firstname     IN VARCHAR2,
                               p_org           IN VARCHAR2,
                               p_office        IN VARCHAR2,
                               p_phone        IN VARCHAR2,
                               p_email        IN VARCHAR2,
                               p_control_code IN VARCHAR2
                               );
END cwms_upass;
/

