/* Formatted on 2007/05/22 07:40 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE BODY cwms_20.cwms_apex
AS
/******************************************************************************
   NAME:       cwms_apex
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        3/23/2007             1. Created this package body.
******************************************************************************/
--
--  example:..
--     desired result is either:
--     if p_expr_value is equal to the p_expr_value_test          -
--     then the string:                                                    -
--             ' 1 = 1 '   is returned                                       -
--      else the string returned is...
--              ' p_column_id = p_expr_string '                            -
--
--      For exmple:
--         get_equal_predicate('sub_parameter_id', ':P535_SUB_PARM', :P535_SUB_PARM, '%');   -
--      if :P535_SUB_PARM is '%' then....
--              " 1=1 "  is returned.
--
--      if :P535_SUB_PARM is not '%' then...
--               " sub_parameter_id = :P535_SUB_PARM " is returned.
--      NOTE: quotes are not part of the string - there is a leading and trailing space character.
--
   FUNCTION get_equal_predicate (
      p_column_id         IN   VARCHAR2,
      p_expr_string       IN   VARCHAR2,
      p_expr_value        IN   VARCHAR2,
      p_expr_value_test   IN   VARCHAR2
   )
      RETURN VARCHAR2
   IS
      l_return_predicate   VARCHAR2 (100) := ' 1=1 ';
      l_column_id          VARCHAR2 (31)  := TRIM (p_column_id);
   BEGIN
      IF p_expr_value != p_expr_value_test
      THEN
         l_return_predicate :=
                 ' ' || l_column_id || ' = ''' || TRIM (p_expr_value)
                 || ''' ';
      ELSIF p_expr_value IS NULL
      THEN
         l_return_predicate := ' ' || l_column_id || ' IS NULL ';
      END IF;

      RETURN l_return_predicate;
   END;

   FUNCTION get_primary_db_office_id
      RETURN VARCHAR2
   IS
   BEGIN
      return cwms_util.user_office_id;
   END get_primary_db_office_id;
END cwms_apex;
/