/* Formatted on 3/3/2011 8:05:07 AM (QP5 v5.163.1008.3004) */
SET DEFINE ON
@@defines.sql

CREATE OR REPLACE PACKAGE BODY &cwms_schema..cwms_sec_policy
AS
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
END cwms_sec_policy;
/

