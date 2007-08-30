/* Formatted on 2007/08/30 15:37 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE cwms_sec
AS
   PROCEDURE get_user_priv_groups (
      p_priv_groups    OUT      sys_refcursor,
      p_username       IN       VARCHAR2 DEFAULT NULL,
      p_db_office_id   IN       VARCHAR2 DEFAULT NULL
   );

   FUNCTION get_user_office_id
      RETURN VARCHAR2;
END cwms_sec;
/