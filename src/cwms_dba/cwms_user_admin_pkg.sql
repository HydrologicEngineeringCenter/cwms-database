CREATE OR REPLACE PACKAGE cwms_user_admin
AS
/******************************************************************************
   NAME:       cwms_admin
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        10/6/2008             1. Created this package.
******************************************************************************/

   PROCEDURE lock_db_account (p_username IN VARCHAR2 DEFAULT NULL);

   PROCEDURE unlock_db_account (p_username IN VARCHAR2 DEFAULT NULL);

   PROCEDURE create_cwms_db_account (
      p_username       IN   VARCHAR2,
      p_dbi_username   IN   VARCHAR2
   );

   PROCEDURE delete_db_account (p_username IN VARCHAR2 DEFAULT NULL);
END cwms_user_admin;
/
