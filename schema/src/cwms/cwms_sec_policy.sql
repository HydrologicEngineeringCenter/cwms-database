CREATE OR REPLACE PACKAGE &cwms_schema..cwms_sec_policy
AS
    FUNCTION CHECK_SESSION_USER (p_schema IN VARCHAR2, p_table IN VARCHAR2)
        RETURN VARCHAR2;
END cwms_sec_policy;
/
