/* Formatted on 3/3/2011 8:05:07 AM (QP5 v5.163.1008.3004) */
SET DEFINE ON
@@defines.sql

CREATE OR REPLACE PACKAGE BODY &cwms_schema..cwms_sec_policy
AS
    FUNCTION cwms_duration_filter (p_schema IN VARCHAR2, p_table IN VARCHAR2)
        RETURN VARCHAR2
    IS
    BEGIN
       return 'duration_code < 61';
    END cwms_duration_filter;

    FUNCTION cwms_interval_filter (p_schema IN VARCHAR2, p_table IN VARCHAR2)
        RETURN VARCHAR2
    IS
    BEGIN
       return 'interval_code < 60';
    END cwms_interval_filter;

    FUNCTION cwms_parameter_type_filter (p_schema IN VARCHAR2, p_table IN VARCHAR2)
        RETURN VARCHAR2
    IS
    BEGIN
       return 'parameter_type_code < 7';
    END cwms_parameter_type_filter;


    FUNCTION CHECK_SESSION_USER (p_schema IN VARCHAR2, p_table IN VARCHAR2)
        RETURN VARCHAR2
    IS
    BEGIN
        IF DBMS_MVIEW.i_am_a_refresh
        THEN
            RETURN NULL;
        END IF;

        IF (    (SYS_CONTEXT ('CWMS_ENV', 'CWMS_USER') IS NULL)
            AND (USER = cwms_sec.cac_service_user))
        THEN
            RETURN '1=0';
        ELSE
            RETURN '1=1';
        END IF;
    END CHECK_SESSION_USER;

    FUNCTION CHECK_IS_PD_OR_DBA( p_schema IN VARCHAR2, p_table IN VARCHAR2)
        RETURN VARCHAR2
    IS        
    BEGIN
        if (cwms_sec.is_user_admin(NULL) OR SYS_CONTEXT('USERENV','POLICY_INVOKER') = 'CWMS_20')
        then
            RETURN '1=1';
        else
            RETURN '1=0';
        end if;
    END CHECK_IS_PD_OR_DBA;

END cwms_sec_policy;
/
