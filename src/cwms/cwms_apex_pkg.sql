/* Formatted on 2007/05/22 07:40 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE cwms_20.cwms_apex
AS
/******************************************************************************
   NAME:       cwms_apex
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        3/23/2007             1. Created this package.
******************************************************************************/
   FUNCTION get_equal_predicate (
      p_column_id         IN   VARCHAR2,
      p_expr_string       IN   VARCHAR2,
      p_expr_value        IN   VARCHAR2,
      p_expr_value_test   IN   VARCHAR2
   )
      RETURN VARCHAR2;

   FUNCTION get_primary_db_office_id
      RETURN VARCHAR2;
END cwms_apex;
/