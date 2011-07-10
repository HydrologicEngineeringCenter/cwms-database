/* Formatted on 6/16/2011 8:41:42 AM (QP5 v5.163.1008.3004) */
CREATE OR REPLACE PACKAGE cwms_ts_id
AS
	PROCEDURE refresh_at_cwms_ts_id;

	PROCEDURE merge_into_at_cwms_ts_id (p_cwms_ts_id IN at_cwms_ts_id%ROWTYPE);

	PROCEDURE delete_from_at_cwms_ts_id (p_ts_code IN NUMBER);

	PROCEDURE touched_apl (p_location_code 		 IN NUMBER,
								  p_loc_active_flag		 IN VARCHAR2,
								  p_sub_location_id		 IN VARCHAR2,
								  p_base_location_code	 IN NUMBER
								 );

	PROCEDURE touched_acts (p_cwms_ts_spec IN at_cwms_ts_spec%ROWTYPE);

	PROCEDURE touched_abl (p_db_office_code			IN NUMBER,
								  p_base_location_code		IN NUMBER,
								  p_base_loc_active_flag	IN VARCHAR2,
								  p_base_location_id 		IN VARCHAR2
								 );

	PROCEDURE touched_api (p_parameter_code		  IN NUMBER,
								  p_base_parameter_code   IN NUMBER,
								  p_sub_parameter_id 	  IN VARCHAR2
								 );
END cwms_ts_id;
/