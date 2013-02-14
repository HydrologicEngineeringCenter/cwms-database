/* Formatted on 1/3/2013 9:31:41 AM (QP5 v5.163.1008.3004) */
CREATE OR REPLACE PACKAGE conflict_handlers
AS
   TYPE emsg_array IS TABLE OF VARCHAR2 (2000)
                         INDEX BY BINARY_INTEGER;

   PROCEDURE resolve_conflicts (
      MESSAGE             IN ANYDATA,
      error_stack_depth   IN NUMBER,
      error_numbers       IN DBMS_UTILITY.NUMBER_ARRAY,
      error_messages      IN EMSG_ARRAY);
END conflict_handlers;
/

SHOW ERRORS

