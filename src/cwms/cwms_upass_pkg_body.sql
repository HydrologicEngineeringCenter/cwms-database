CREATE OR REPLACE PACKAGE BODY cwms_upass
AS
    PROCEDURE delete_upass_user (p_userid IN VARCHAR2)
    IS
    BEGIN
        DELETE FROM at_sec_users
              WHERE username = UPPER (p_userid);

        DELETE FROM at_sec_locked_users
              WHERE username = UPPER (p_userid);

        DELETE FROM at_sec_user_office
              WHERE username = UPPER (p_userid);

        DELETE FROM at_sec_cwms_users
              WHERE USERID = UPPER (p_userid);

        COMMIT;
        CWMS_MSG.LOG_DB_MESSAGE (
            CWMS_MSG.MSG_LEVEL_NORMAL,
            'User ' || UPPER (p_userid) || ' is deleted by UPASS');
    END delete_upass_user;

    PROCEDURE update_user_data (p_userid           IN VARCHAR2,
                                p_fullname         IN VARCHAR2,
                                p_org              IN VARCHAR2,
                                p_office           IN VARCHAR2,
                                p_phone            IN VARCHAR2,
                                p_email            IN VARCHAR2,
                                p_principle_name   IN VARCHAR2 DEFAULT NULL)
    IS
        l_count            NUMBER;
        l_fullname         VARCHAR2 (96);
        l_org              VARCHAR2 (16);
        l_office           VARCHAR2 (16);
        l_phone            VARCHAR2 (24);
        l_email            VARCHAR2 (128);
        l_principle_name   VARCHAR2 (128);
    BEGIN
        l_fullname := SUBSTR (p_fullname, 1, 96);
        l_org := SUBSTR (p_org, 1, 16);
        l_office := SUBSTR (p_office, 1, 16);
        l_phone := SUBSTR (p_phone, 1, 24);
        l_email := SUBSTR (p_email, 1, 128);
        l_principle_name := SUBSTR (p_principle_name, 1, 128);

        SELECT COUNT (*)
          INTO l_count
          FROM AT_SEC_CWMS_USERS
         WHERE USERID = UPPER (p_userid);

        IF (l_count = 0)
        THEN
            INSERT INTO AT_SEC_CWMS_USERS (userid,
                                           fullname,
                                           org,
                                           office,
                                           phone,
                                           email,
                                           principle_name,
                                           createdby)
                 VALUES (p_userid,
                         l_fullname,
                         l_org,
                         l_office,
                         l_phone,
                         l_email,
                         l_principle_name,
                         CWMS_UTIL.GET_USER_ID);
        ELSE
            UPDATE AT_SEC_CWMS_USERS
               SET fullname = l_fullname,
                   org = l_org,
                   office = l_office,
                   phone = l_phone,
                   email = l_email,
                   createdby = CWMS_UTIL.GET_USER_ID
             WHERE userid = UPPER (p_userid);

            IF p_principle_name IS NOT NULL
            THEN
                UPDATE AT_SEC_CWMS_USERS
                   SET principle_name = l_principle_name
                 WHERE userid = UPPER (p_userid);
            END IF;
        END IF;

        COMMIT;
    END UPDATE_USER_DATA;

    PROCEDURE update_cwms_user (p_userid           IN VARCHAR2,
                                p_lastname         IN VARCHAR2,
                                p_middlename       IN VARCHAR2,
                                p_firstname        IN VARCHAR2,
                                p_org              IN VARCHAR2,
                                p_office           IN VARCHAR2,
                                p_phone            IN VARCHAR2,
                                p_email            IN VARCHAR2,
                                p_control_code     IN VARCHAR2,
                                p_principle_name   IN VARCHAR2 DEFAULT NULL)
    IS
    BEGIN
        IF (   ((UPPER (p_control_code)) = 'C')
            OR ((UPPER (p_control_code)) = 'A'))
        THEN
            update_user_data (
                p_userid,
                p_firstname || ' ' || p_middlename || ' ' || p_lastname,
                p_org,
                p_office,
                p_phone,
                p_email,
                p_principle_name);
            CWMS_DBA.CWMS_USER_ADMIN.UNLOCK_DB_ACCOUNT(p_userid);
            COMMIT;
        ELSIF ((UPPER (p_control_code)) = 'D')
        THEN
            DELETE_UPASS_USER (p_userid);
        ELSE
            CWMS_MSG.LOG_DB_MESSAGE (CWMS_MSG.MSG_LEVEL_NORMAL,
                                     'Invalid UPASS update code');
            COMMIT;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            CWMS_MSG.LOG_DB_MESSAGE (
                CWMS_MSG.MSG_LEVEL_NORMAL,
                   'Exception while update user metadata in UPASS: '
                || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    END update_cwms_user;
END cwms_upass;
/
