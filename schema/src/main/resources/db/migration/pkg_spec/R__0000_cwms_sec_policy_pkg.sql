CREATE OR REPLACE PACKAGE &cwms_schema..cwms_sec_policy authid current_user
AS
    FUNCTION cwms_duration_filter(p_schema IN VARCHAR2, p_table IN VARCHAR2)
        RETURN VARCHAR2;
    FUNCTION cwms_interval_filter(p_schema IN VARCHAR2, p_table IN VARCHAR2)
        RETURN VARCHAR2;
    FUNCTION cwms_parameter_type_filter(p_schema IN VARCHAR2, p_table IN VARCHAR2)
        RETURN VARCHAR2;
    FUNCTION CHECK_SESSION_USER (p_schema IN VARCHAR2, p_table IN VARCHAR2)
        RETURN VARCHAR2;

    FUNCTION CHECK_IS_PD_OR_DBA( p_schema IN VARCHAR2, p_table IN VARCHAR2)
        RETURN VARCHAR2;
END cwms_sec_policy;
/
