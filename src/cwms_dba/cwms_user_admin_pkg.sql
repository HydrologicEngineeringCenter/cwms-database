/* Formatted on 6/21/2009 8:40:43 AM (QP5 v5.115.810.9015) */
CREATE OR REPLACE PACKAGE cwms_dba.cwms_user_admin
AS
	/******************************************************************************
		 NAME:		 cwms_admin
		  PURPOSE:

		 REVISIONS:
		  Ver 		  Date		 Author				Description
		---------  ----------  --------------- ------------------------------------
		1.0			10/6/2008				1. Created this package.
	******************************************************************************/

	PROCEDURE lock_db_account (p_username IN VARCHAR2 DEFAULT NULL );

	PROCEDURE unlock_db_account (p_username IN VARCHAR2 DEFAULT NULL );

	PROCEDURE create_cwmsdbi_db_account (p_username   IN VARCHAR2,
													 p_password   IN VARCHAR2 DEFAULT NULL
													);

    PROCEDURE create_cwms_service_account (p_username 		IN VARCHAR2,
                                          p_password 		IN VARCHAR2                                          
												);
												
	PROCEDURE delete_db_account (p_username IN VARCHAR2 DEFAULT NULL );

    PROCEDURE create_cwms_db_account (p_username         IN VARCHAR2, p_password in varchar2,
                                                 p_dbi_username    IN VARCHAR2
                                                );

	PROCEDURE set_user_password (p_username	IN VARCHAR2,
										  p_password	IN VARCHAR2
										 );
        PROCEDURE grant_rdl_role (p_role VARCHAR2, p_username VARCHAR2);
	PROCEDURE revoke_rdl_role (p_role VARCHAR2, p_username VARCHAR2);
        PROCEDURE update_service_password(p_username VARCHAR2,p_password VARCHAR2);
	PROCEDURE grant_cwms_permissions(p_username IN VARCHAR2);
END cwms_user_admin;
/
