/* Formatted on 2007/06/27 14:24 (Formatter Plus v4.8.8) */
CREATE OR REPLACE PACKAGE cwms_sec
AS
   PROCEDURE get_user_priv_groups (
      p_priv_groups    OUT      sys_refcursor,
      p_username       IN       VARCHAR2 DEFAULT NULL,
      p_db_office_id   IN       VARCHAR2 DEFAULT NULL
   );
END cwms_sec;
/