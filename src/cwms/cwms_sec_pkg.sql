CREATE OR REPLACE PACKAGE cwms_sec
AS
	PROCEDURE lock_db_account (p_username IN VARCHAR2);

	PROCEDURE unlock_db_account (p_username IN VARCHAR2);

	PROCEDURE create_cwms_db_account (p_username 		IN VARCHAR2,
												 p_db_office_id	IN VARCHAR2
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
END cwms_sec;
/