/* Formatted on 2007/11/08 07:32 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE cwms_sec
AS
   PROCEDURE get_user_priv_groups (
      p_priv_groups    OUT      sys_refcursor,
      p_username       IN       VARCHAR2 DEFAULT NULL,
      p_db_office_id   IN       VARCHAR2 DEFAULT NULL
   );

   PROCEDURE get_user_office_data (
      p_office_id          OUT   VARCHAR2,
      p_office_long_name   OUT   VARCHAR2
   );

   FUNCTION get_user_office_id
      RETURN VARCHAR2;
END cwms_sec;
/