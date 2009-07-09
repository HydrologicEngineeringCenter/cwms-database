/* Formatted on 7/5/2009 1:19:30 PM (QP5 v5.115.810.9015) */
CREATE OR REPLACE PACKAGE cwms_20.cwms_sec
AS
	TYPE cat_at_sec_allow_rec_t IS RECORD (
												 db_office_code					 NUMBER,
												 user_group_code					 NUMBER,
												 ts_group_code 					 NUMBER,
												 db_office_id						 VARCHAR2 (16),
												 user_group_id 					 VARCHAR2 (32),
												 ts_group_id						 VARCHAR2 (32),
												 priv_sum							 NUMBER,
												 priv 								 VARCHAR2 (15)
											 );

	TYPE cat_at_sec_allow_tab_t IS TABLE OF cat_at_sec_allow_rec_t;



	FUNCTION is_user_admin (p_db_office_id IN VARCHAR2 DEFAULT NULL )
		RETURN BOOLEAN;

	FUNCTION is_member_user_group (p_user_group_code	IN NUMBER,
											 p_username 			IN VARCHAR2,
											 p_db_office_code 	IN NUMBER
											)
		RETURN BOOLEAN;

	PROCEDURE assign_ts_group_user_group (
		p_ts_group_id		IN VARCHAR2,
		p_user_group_id	IN VARCHAR2,
		p_privilege 		IN VARCHAR2,						  -- none, read or write
		p_db_office_id 	IN VARCHAR2 DEFAULT NULL
	);

	PROCEDURE lock_db_account (p_username IN VARCHAR2);

	PROCEDURE unlock_db_account (p_username IN VARCHAR2);

	PROCEDURE create_cwms_db_account (
		p_username		  IN VARCHAR2,
		p_password		  IN VARCHAR2,
		p_db_office_id   IN VARCHAR2 DEFAULT NULL
	);

	PROCEDURE create_cwmsdbi_db_user (
		p_dbi_username   IN VARCHAR2,
		p_dbi_password   IN VARCHAR2 DEFAULT NULL ,
		p_db_office_id   IN VARCHAR2 DEFAULT NULL
	);

	PROCEDURE delete_cwms_db_account (p_username IN VARCHAR2);

	PROCEDURE get_user_priv_groups (
		p_priv_groups		  OUT sys_refcursor,
		p_username		  IN		VARCHAR2 DEFAULT NULL ,
		p_db_office_id   IN		VARCHAR2 DEFAULT NULL
	);

	PROCEDURE get_user_office_data (p_office_id			  OUT VARCHAR2,
											  p_office_long_name   OUT VARCHAR2
											 );

	FUNCTION get_user_office_id
		RETURN VARCHAR2;

	PROCEDURE unlock_user (p_username		 IN VARCHAR2,
								  p_db_office_id	 IN VARCHAR2 DEFAULT NULL
								 );

	FUNCTION get_user_group_code (p_user_group_id	 IN VARCHAR2,
											p_db_office_code	 IN NUMBER
										  )
		RETURN NUMBER;

	PROCEDURE add_user_to_group (p_username			IN VARCHAR2,
										  p_user_group_id 	IN VARCHAR2,
										  p_db_office_code	IN NUMBER
										 );

	PROCEDURE add_user_to_group (p_username		  IN VARCHAR2,
										  p_user_group_id   IN VARCHAR2,
										  p_db_office_id	  IN VARCHAR2 DEFAULT NULL
										 );

	PROCEDURE create_user (p_username				 IN VARCHAR2,
								  p_password				 IN VARCHAR2,
								  p_user_group_id_list	 IN char_32_array_type,
								  p_db_office_id			 IN VARCHAR2 DEFAULT NULL
								 );

	PROCEDURE delete_user (p_username		 IN VARCHAR2,
								  p_db_office_id	 IN VARCHAR2 DEFAULT NULL
								 );

	PROCEDURE lock_user (p_username		  IN VARCHAR2,
								p_db_office_id   IN VARCHAR2 DEFAULT NULL
							  );

	PROCEDURE remove_user_from_group (
		p_username			IN VARCHAR2,
		p_user_group_id	IN VARCHAR2,
		p_db_office_id 	IN VARCHAR2 DEFAULT NULL
	);

	FUNCTION get_user_state (p_username 		IN VARCHAR2,
									 p_db_office_id	IN VARCHAR2 DEFAULT NULL
									)
		RETURN VARCHAR2;

	PROCEDURE cat_at_sec_allow (p_at_sec_allow		OUT sys_refcursor,
										 p_db_office_id	IN 	 VARCHAR2 DEFAULT NULL
										);

	FUNCTION cat_at_sec_allow_tab (p_db_office_id IN VARCHAR2 DEFAULT NULL )
		RETURN cat_at_sec_allow_tab_t
		PIPELINED;

	PROCEDURE refresh_mv_sec_ts_privileges;
    
    procedure start_refresh_mv_sec_privs_job;
END cwms_sec;
/