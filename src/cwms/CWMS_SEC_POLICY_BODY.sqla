/* Formatted on 2007/01/08 15:21 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE BODY cwms_sec_policy
AS
/******************************************************************************
   NAME:       cwms_sec_policy
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        1/3/2007             1. Created this package body.
******************************************************************************/
   FUNCTION read_ts_codes (ns IN VARCHAR2, na IN VARCHAR2)
      RETURN VARCHAR2
   IS
      l_predicate   VARCHAR2 (2000);
   BEGIN
      IF SYS_CONTEXT ('USERENV', 'SESSION_USER') = 'CWMS_20'
      THEN
         l_predicate := '1=1';
      ELSE
         l_predicate :=
            'ts_code in (select ts_code from mv_sec_ts_privileges where user_id =  SYS_CONTEXT(''USERENV'', ''SESSION_USER'')
                         and bitand(net_privilege_code, 4) = 4)';
      END IF;

      RETURN l_predicate;
   END;

   FUNCTION write_ts_codes (ns IN VARCHAR2, na IN VARCHAR2)
      RETURN VARCHAR2
   IS
      l_predicate   VARCHAR2 (2000);
   BEGIN
      IF SYS_CONTEXT ('USERENV', 'SESSION_USER') = 'CWMS_20'
      THEN
         l_predicate := '1=1';
      ELSE
         l_predicate :=
            'ts_code in (select ts_code from mv_sec_ts_privileges where user_id =  SYS_CONTEXT(''USERENV'', ''SESSION_USER'')
                         and bitand(net_privilege_code, 2) = 2)';
      END IF;

      RETURN l_predicate;
   END;
END cwms_sec_policy;
/