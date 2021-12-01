CREATE OR REPLACE PACKAGE CWMS_DBA.cwms_user_admin
AS
    /******************************************************************************
   NAME:   cwms_admin
    PURPOSE:

   REVISIONS:
    Ver     Date   Author    Description
  ---------  ----------  --------------- ------------------------------------
  1.0   10/6/2008    1. Created this package.
 ******************************************************************************/

    PROCEDURE lock_db_account (p_username IN VARCHAR2 DEFAULT NULL);

    PROCEDURE unlock_db_account (p_username IN VARCHAR2 DEFAULT NULL);


    PROCEDURE grant_rdl_role (p_role VARCHAR2, p_username VARCHAR2);

    PROCEDURE revoke_rdl_role (p_role VARCHAR2, p_username VARCHAR2);

    PROCEDURE update_service_password (p_username   VARCHAR2,
                                       p_password   VARCHAR2);

    PROCEDURE grant_cwms_permissions (p_username IN VARCHAR2);
END cwms_user_admin;
/

