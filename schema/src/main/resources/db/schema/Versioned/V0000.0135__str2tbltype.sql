create type str2tbltype
/**
 * Holds a table of varchar2(2000). Used by the standalone str2tab utility function.
 */
AS TABLE OF VARCHAR2 (2000);
/


create or replace public synonym cwms_t_str2tbltype for str2tbltype;

