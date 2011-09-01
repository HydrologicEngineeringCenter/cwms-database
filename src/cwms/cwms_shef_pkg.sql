/* Formatted on 8/12/2011 2:16:08 PM (QP5 v5.163.1008.3004) */
CREATE OR REPLACE PACKAGE cwms_shef
/**
 * Facilities for dealing with CWMS SHEF processing
 *
 * @author Gerhard Krueger
 *
 * @since CWMS 2.1
 */
AS
   /**
    * SHEF processing state indicating the processing is starting up
    */
	data_stream_state_startup	  CONSTANT VARCHAR2 (7) := 'Startup';
   /**
    * SHEF processing state indicating the processing is shutting down
    */
	data_stream_state_shutdown   CONSTANT VARCHAR2 (8) := 'Shutdown';
   /**
    * SHEF processing state indicating the processing is active
    */
	data_stream_state_active	  CONSTANT VARCHAR2 (6) := 'Active';
   /**
    * SHEF processing state indicating the processing is paused
    */
	data_stream_state_inactive   CONSTANT VARCHAR2 (8) := 'Inactive';
   /**
    * Collection of valid SHEF processing states
    */
	data_stream_states			  CONSTANT str_tab_t
		:= str_tab_t (data_stream_state_startup,
						  data_stream_state_shutdown,
						  data_stream_state_active,
						  data_stream_state_inactive
						 ) ;

   /**
    * [description needed]
    */
	data_stream_mgt_style		  CONSTANT VARCHAR2 (16) := 'DATA STREAMS';
   /**
    * [description needed]
    */
	data_feed_mgt_style			  CONSTANT VARCHAR2 (16) := 'DATA FEEDS';
	--
   /**
    * SHEF processing criteria line prefix indicating the criteria line should be ignored
    */
	ignore_shef_spec				  CONSTANT VARCHAR2 (2) := '//';
	-- PROCEDURE clean_at_shef_crit_file p_action constants.
   /**
    * [description needed]
    */
	ten_file_limit 				  CONSTANT VARCHAR2 (32) := 'TEN FILE LIMIT';
	-- default value.
   /**
    * [description needed]
    */
	delete_all						  CONSTANT VARCHAR2 (32) := 'DELETE ALL';
   /**
    * Maximum length of SHEF location identifier
    */
	max_shef_loc_length			  CONSTANT NUMBER := 8;
   /**
    * [description needed]
    *
    * @member data_stream_code [description needed]
    * @member data_stream_id   [description needed]
    * @member data_stream_desc [description needed]
    * @member active_flag      [description needed]
    * @member office_id        [description needed]
    */
	TYPE cat_data_stream_rec_t IS RECORD
	(
		data_stream_code	 NUMBER,
		data_stream_id 	 VARCHAR2 (16),
		data_stream_desc	 VARCHAR2 (128),
		active_flag 		 VARCHAR2 (1),
		office_id			 VARCHAR2 (16)
	);
   /**
    * [description needed]
    */
	TYPE cat_data_stream_tab_t IS TABLE OF cat_data_stream_rec_t;
   /**
    * [description needed]
    *
    * @member data_feed_code       [description needed]
    * @member data_feed_id         [description needed]
    * @member data_feed_prefix     [description needed]
    * @member data_feed_desc       [description needed]
    * @member data_stream_id       [description needed]
    * @member data_stream_active_f [description needed]
    * @member office_id            [description needed]
    */
	TYPE cat_data_feed_rec_t IS RECORD
	(
		data_feed_code 			  NUMBER,
		data_feed_id				  VARCHAR2 (32),
		data_feed_prefix			  VARCHAR2 (3),
		data_feed_desc 			  VARCHAR2 (128),
		data_stream_id 			  VARCHAR2 (16),
		data_stream_active_flag   VARCHAR2 (1),
		office_id					  VARCHAR2 (16)
	);
   /**
    * [description needed]
    */
	TYPE cat_data_feed_tab_t IS TABLE OF cat_data_feed_rec_t;
   /**
    * [description needed]
    *
    * @member shef_time_zone_id   [description needed]
    * @member shef_time_zone_desc [description needed]
    */
	TYPE cat_shef_tz_rec_t IS RECORD
	(
		shef_time_zone_id 	 VARCHAR2 (16),
		shef_time_zone_desc	 VARCHAR2 (64)
	);
   /**
    * [description needed]
    */
	TYPE cat_shef_tz_tab_t IS TABLE OF cat_shef_tz_rec_t;
   /**
    * [description needed]
    *
    * @member shef_duration_code    [description needed]
    * @member shef_duration_desc    [description needed]
    * @member shef_duration_numeric [description needed]
    * @member cwms_duration_id      [description needed]
    */
	TYPE cat_shef_dur_rec_t IS RECORD
	(
		shef_duration_code		VARCHAR2 (1),
		shef_duration_desc		VARCHAR2 (128),
		shef_duration_numeric	VARCHAR2 (4),
		cwms_duration_id			VARCHAR2 (16)
	);
   /**
    * [description needed]
    */
	TYPE cat_shef_dur_tab_t IS TABLE OF cat_shef_dur_rec_t;
   /**
    * [description needed]
    *
    * @member shef_unit_id [description needed]
    */
	TYPE cat_shef_units_rec_t IS RECORD (shef_unit_id VARCHAR2 (16));
   /**
    * [description needed]
    */
	TYPE cat_shef_units_tab_t IS TABLE OF cat_shef_units_rec_t;
   /**
    * [description needed]
    *
    * @member id_code               [description needed]
    * @member shef_pe_code          [description needed]
    * @member shef_tse_code         [description needed]
    * @member shef_req_send_code    [description needed]
    * @member shef_duration_code    [description needed]
    * @member shef_duration_numeric [description needed]
    * @member unit_id_en            [description needed]
    * @member unit_id_si            [description needed]
    * @member abstract_param_id     [description needed]
    * @member base_parameter_id     [description needed]
    * @member sub_parameter_id      [description needed]
    * @member parameter_type_id     [description needed]
    * @member description           [description needed]
    * @member notes                 [description needed]
    */
	TYPE cat_shef_pe_codes_rec_t IS RECORD
	(
		id_code						NUMBER,
		shef_pe_code				VARCHAR2 (16),
		shef_tse_code				VARCHAR2 (3),
		shef_req_send_code		VARCHAR2 (7),
		shef_duration_code		VARCHAR2 (1),
		shef_duration_numeric	VARCHAR2 (4),
		unit_id_en					VARCHAR2 (16),
		unit_id_si					VARCHAR2 (16),
		abstract_param_id 		VARCHAR2 (32),
		base_parameter_id 		VARCHAR2 (16),
		sub_parameter_id			VARCHAR2 (32),
		parameter_type_id 		VARCHAR2 (16),
		description 				VARCHAR2 (256),
		notes 						VARCHAR2 (256)
	);
   /**
    * [description needed]
    */
	TYPE cat_shef_pe_codes_tab_t IS TABLE OF cat_shef_pe_codes_rec_t;
   /**
    * [description needed]
    *
    * @member shef_e_code [description needed]
    * @member description [description needed]
    * @member duration_id [description needed]
    */
	TYPE cat_shef_extremum_rec_t IS RECORD
	(
		shef_e_code   VARCHAR2 (1),
		description   VARCHAR2 (32),
		duration_id   VARCHAR2 (16)
	);
   /**
    * [description needed]
    */
	TYPE cat_shef_extremum_tab_t IS TABLE OF cat_shef_extremum_rec_t;
   /**
    * [description needed]
    *
    * @param p_data_stream_id  [description needed]
    * @param p_db_office_id    [description needed]
    *
    * @return [description needed]
    */
	FUNCTION get_update_crit_file_flag (p_data_stream_id	 IN VARCHAR2,
													p_db_office_id 	 IN VARCHAR2
												  )
		RETURN VARCHAR2;
   /**
    * [description needed]
    *
    * @param p_update_crit_file_flag [description needed]
    * @param p_data_stream_id        [description needed]
    * @param p_db_office_id          [description needed]
    */
	PROCEDURE set_update_crit_file_flag (
		p_update_crit_file_flag   IN VARCHAR2,
		p_data_stream_id			  IN VARCHAR2,
		p_db_office_id 			  IN VARCHAR2
	);

   /**
    * [description needed]
    *
    * @param p_shef_extremum_codes [description needed]
    */
	PROCEDURE cat_shef_extremum_codes (p_shef_extremum_codes OUT SYS_REFCURSOR
												 );
   /**
    * [description needed]
    *
    * @param p_shef_pe_codes [description needed]
    * @param p_db_office_id  [description needed]
    */
	PROCEDURE cat_shef_pe_codes (
		p_shef_pe_codes		OUT SYS_REFCURSOR,
		p_db_office_id 	IN 	 VARCHAR2 DEFAULT NULL
	);
   /**
    * [description needed]
    *
    * @member shef_crit_line [description needed]
    */
	TYPE cat_shef_crit_lines_rec_t IS RECORD (shef_crit_line VARCHAR2 (400));
   /**
    * [description needed]
    *
    */
	TYPE cat_shef_crit_lines_tab_t IS TABLE OF cat_shef_crit_lines_rec_t;
   /**
    * [description needed]
    *
    * @param p_id_code      [description needed]
    * @param p_db_office_id [description needed]
    */
	PROCEDURE delete_local_pe_code (p_id_code 		 IN NUMBER,
											  p_db_office_id	 IN VARCHAR2 DEFAULT NULL
											 );
   /**
    * [description needed]
    *
    * @param p_shef_pe_code          [description needed]
    * @param p_shef_tse_code         [description needed]
    * @param p_shef_duration_numeric [description needed]
    * @param p_shef_req_send_code    [description needed]
    * @param p_parameter_id          [description needed]
    * @param p_parameter_type_id     [description needed]
    * @param p_unit_id_en            [description needed]
    * @param p_unit_id_si            [description needed]
    * @param p_description           [description needed]
    * @param p_notes                 [description needed]
    * @param p_db_office_id          [description needed]
    */
	PROCEDURE create_local_pe_code (
		p_shef_pe_code 			  IN VARCHAR2,
		p_shef_tse_code			  IN VARCHAR2,
		p_shef_duration_numeric   IN VARCHAR2,
		p_shef_req_send_code 	  IN VARCHAR2 DEFAULT NULL,
		p_parameter_id 			  IN VARCHAR2,
		p_parameter_type_id		  IN VARCHAR2,
		p_unit_id_en				  IN VARCHAR2,
		p_unit_id_si				  IN VARCHAR2,
		p_description				  IN VARCHAR2 DEFAULT NULL,
		p_notes						  IN VARCHAR2 DEFAULT NULL,
		p_db_office_id 			  IN VARCHAR2 DEFAULT NULL
	);


   /**
    * [description needed]
    *
    * @param p_cwms_ts_id            [description needed]
    * @param p_data_stream_id        [description needed]
    * @param p_data_feed_id          [description needed]
    * @param p_loc_group_id          [description needed]
    * @param p_shef_loc_id           [description needed]
    * @param p_shef_pe_code          [description needed]
    * @param p_shef_tse_code         [description needed]
    * @param p_shef_duration_code    [description needed]
    * @param p_shef_unit_id          [description needed]
    * @param p_time_zone_id          [description needed]
    * @param p_daylight_savings      [description needed]
    * @param p_interval_utc_offset   [description needed]
    * @param p_snap_forward_minutes  [description needed]
    * @param p_snap_backward_minutes [description needed]
    * @param p_ts_active_flag        [description needed]
    * @param p_ignore_shef_spec      [description needed]
    * @param p_update_allowed        [description needed]
    * @param p_db_office_id          [description needed]
    */
	PROCEDURE store_shef_spec (
		p_cwms_ts_id				  IN VARCHAR2,
		p_data_stream_id			  IN VARCHAR2 DEFAULT NULL,
		p_data_feed_id 			  IN VARCHAR2 DEFAULT NULL,
		p_loc_group_id 			  IN VARCHAR2 DEFAULT 'SHEF Location Id',
		p_shef_loc_id				  IN VARCHAR2 DEFAULT NULL,
		-- normally use loc_group_id
		p_shef_pe_code 			  IN VARCHAR2,
		p_shef_tse_code			  IN VARCHAR2,
		p_shef_duration_code 	  IN VARCHAR2,
		-- e.g., V5002 or simply L   -
		p_shef_unit_id 			  IN VARCHAR2,
		p_time_zone_id 			  IN VARCHAR2,
		p_daylight_savings		  IN VARCHAR2 DEFAULT 'F',
		p_interval_utc_offset	  IN NUMBER DEFAULT NULL,			 -- in minutes.
		p_snap_forward_minutes	  IN NUMBER DEFAULT NULL,
		p_snap_backward_minutes   IN NUMBER DEFAULT NULL,
		p_ts_active_flag			  IN VARCHAR2 DEFAULT 'T',
		p_ignore_shef_spec		  IN VARCHAR2 DEFAULT 'F',
		p_update_allowed			  IN VARCHAR2 DEFAULT 'T',
		p_db_office_id 			  IN VARCHAR2 DEFAULT NULL
	);
   /**
    * [description needed]
    *
    * @param p_cwms_ts_id     [description needed]
    * @param p_data_stream_id [description needed]
    * @param p_db_office_id   [description needed]
    */
	PROCEDURE delete_shef_spec (p_cwms_ts_id		  IN VARCHAR2,
										 p_data_stream_id   IN VARCHAR2,
										 p_db_office_id	  IN VARCHAR2 DEFAULT NULL
										);

	-- left kernal must be unique.
   /**
    * [description needed]
    *
    * @param p_data_stream_id           [description needed]
    * @param p_data_stream_desc         [description needed]
    * @param p_active_flag              [description needed]
    * @param p_use_db_shef_spec_mapping [description needed]
    * @param p_ignore_nulls             [description needed]
    * @param p_db_office_id             [description needed]
    */
    PROCEDURE store_data_stream (
        p_data_stream_id                  IN VARCHAR2,
        p_data_stream_desc              IN VARCHAR2 DEFAULT NULL,
        p_active_flag                      IN VARCHAR2 DEFAULT 'T',
        p_use_db_shef_spec_mapping   IN VARCHAR2 DEFAULT 'T',
        p_ignore_nulls                   IN VARCHAR2 DEFAULT 'T',
        p_db_office_id                   IN VARCHAR2 DEFAULT NULL
    );
   /**
    * [description needed]
    *
    * @param p_data_stream_id_old [description needed]
    * @param p_data_stream_id_new [description needed]
    * @param p_db_office_id       [description needed]
    */
	PROCEDURE rename_data_stream (
		p_data_stream_id_old   IN VARCHAR2,
		p_data_stream_id_new   IN VARCHAR2,
		p_db_office_id 		  IN VARCHAR2 DEFAULT NULL
	);
   /**
    * [description needed]
    *
    * @param p_data_feed_id [description needed]
    * @param p_db_office_id [description needed]
    */
	PROCEDURE delete_data_feed_shef_specs (
		p_data_feed_id   IN VARCHAR2,
		p_db_office_id   IN VARCHAR2 DEFAULT NULL
	);
   /**
    * [description needed]
    *
    * @param p_data_stream_id  [description needed]
    * @param p_db_office_id    [description needed]
    */
	PROCEDURE delete_data_stream_shef_specs (
		p_data_stream_id	 IN VARCHAR2,
		p_db_office_id 	 IN VARCHAR2 DEFAULT NULL
	);
   /**
    * [description needed]
    *
    * @param p_data_stream_id [description needed]
    * @param p_cascade_all    [description needed]
    * @param p_db_office_id   [description needed]
    */
	PROCEDURE delete_data_stream (p_data_stream_id	 IN VARCHAR2,
											p_cascade_all		 IN VARCHAR2 DEFAULT 'F',
											p_db_office_id 	 IN VARCHAR2 DEFAULT NULL
										  );
   /**
    * [description needed]
    *
    * @param p_shef_data_streams [description needed]
    * @param p_db_office_id      [description needed]
    */
	PROCEDURE cat_shef_data_streams (
		p_shef_data_streams		 OUT SYS_REFCURSOR,
		p_db_office_id 		 IN	  VARCHAR2 DEFAULT NULL
	);
   /**
    * [description needed]
    *
    * @param [description needed]
    *
    * @return [description needed]
    */
	FUNCTION cat_shef_data_streams_tab (
		p_db_office_id IN VARCHAR2 DEFAULT NULL
	)
		RETURN cat_data_stream_tab_t
		PIPELINED;
   /**
    * [description needed]
    *
    * @param p_shef_time_zones [description needed]
    */
	PROCEDURE cat_shef_time_zones (p_shef_time_zones OUT SYS_REFCURSOR);
   /**
    * [description needed]
    *
    * @return [description needed]
    */
	FUNCTION cat_shef_time_zones_tab
		RETURN cat_shef_tz_tab_t
		PIPELINED;
   /**
    * [description needed]
    *
    * @return [description needed]
    */
	FUNCTION cat_shef_durations_tab
		RETURN cat_shef_dur_tab_t
		PIPELINED;
   /**
    * [description needed]
    *
    * @return [description needed]
    */
	FUNCTION cat_shef_units_tab
		RETURN cat_shef_units_tab_t
		PIPELINED;
   /**
    * [description needed]
    *
    * @return [description needed]
    */
	FUNCTION cat_shef_extremum_tab
		RETURN cat_shef_extremum_tab_t
		PIPELINED;
   /**
    * [description needed]
    *
    * @return [description needed]
    */
	FUNCTION cat_shef_pe_codes_tab (p_db_office_id IN VARCHAR2 DEFAULT NULL)
		RETURN cat_shef_pe_codes_tab_t
		PIPELINED;
   /**
    * [description needed]
    *
    * @return [description needed]
    */
	FUNCTION get_shef_crit_file (p_data_stream_id	  IN VARCHAR2,
										  p_utc_version_date   IN DATE DEFAULT NULL,
										  p_db_office_id		  IN VARCHAR2 DEFAULT NULL
										 )
		RETURN CLOB;
   /**
    * [description needed]
    *
    * @return [description needed]
    */
	FUNCTION get_shef_duration_numeric (p_shef_duration_code IN VARCHAR2)
		RETURN VARCHAR2;
   /**
    * [description needed]
    *
    * @param p_shef_id            [description needed]
    * @param p_shef_pe_code       [description needed]
    * @param p_shef_tse_code      [description needed]
    * @param p_shef_duration_code [description needed]
    * @param p_units              [description needed]
    * @param p_unit_sys           [description needed]
    * @param p_tz                 [description needed]
    * @param p_dltime             [description needed]
    * @param p_int_offset         [description needed]
    * @param p_int_backward       [description needed]
    * @param p_int_forward        [description needed]
    * @param p_cwms_ts_id         [description needed]
    * @param p_comment            [description needed]
    * @param p_criteria_record    [description needed]
    */
	PROCEDURE parse_criteria_record (p_shef_id					  OUT VARCHAR2,
												p_shef_pe_code 			  OUT VARCHAR2,
												p_shef_tse_code			  OUT VARCHAR2,
												p_shef_duration_code 	  OUT VARCHAR2,
												p_units						  OUT VARCHAR2,
												p_unit_sys					  OUT VARCHAR2,
												p_tz							  OUT VARCHAR2,
												p_dltime 					  OUT VARCHAR2,
												p_int_offset				  OUT VARCHAR2,
												p_int_backward 			  OUT VARCHAR2,
												p_int_forward				  OUT VARCHAR2,
												p_cwms_ts_id				  OUT VARCHAR2,
												p_comment					  OUT VARCHAR2,
												p_criteria_record 	  IN		VARCHAR2
											  );
   /**
    * [description needed]
    *
    * @param p_shef_crit_lines [description needed]
    * @param p_data_stream_id  [description needed]
    * @param p_db_office_id    [description needed]
    */
	PROCEDURE cat_shef_crit_lines (
		p_shef_crit_lines 	  OUT SYS_REFCURSOR,
		p_data_stream_id	  IN		VARCHAR2,
		p_db_office_id 	  IN		VARCHAR2 DEFAULT NULL
	);
   /**
    * [description needed]
    *
    * @param p_data_stream_id [description needed]
    * @param p_db_office_id   [description needed]
    *
    * @return [description needed]
    */
	FUNCTION cat_shef_crit_lines_tab (
		p_data_stream_id	 IN VARCHAR2,
		p_db_office_id 	 IN VARCHAR2 DEFAULT NULL
	)
		RETURN cat_shef_crit_lines_tab_t
		PIPELINED;
   /**
    * [description needed]
    *
    * @param p_data_stream_id [description needed]
    * @param p_db_office_id   [description needed]
    */
	PROCEDURE store_shef_crit_file (
		p_data_stream_id	 IN VARCHAR2,
		p_db_office_id 	 IN VARCHAR2 DEFAULT NULL
	);
   /**
    * [description needed]
    *
    * @param p_data_stream_id [description needed]
    * @param p_db_office_id   [description needed]
    *
    * @return [description needed]
    */
	FUNCTION get_data_stream_code (p_data_stream_id   IN VARCHAR2,
											 p_db_office_id	  IN VARCHAR2 DEFAULT NULL
											)
		RETURN NUMBER;
   /**
    * [description needed]
    *
    * @param p_data_stream_id [description needed]
    * @param p_db_office_id   [description needed]
    *
    * @return [description needed]
    */
	FUNCTION is_crit_file_current (p_data_stream_id   IN VARCHAR2,
											 p_db_office_id	  IN VARCHAR2 DEFAULT NULL
											)
		RETURN BOOLEAN;
   /**
    * [description needed]
    *
    * @param p_data_stream_id [description needed]
    * @param p_db_office_id   [description needed]
    *
    * @return [description needed]
    */
	FUNCTION is_data_stream_active (
		p_data_stream_id	 IN VARCHAR2,
		p_db_office_id 	 IN VARCHAR2 DEFAULT NULL
	)
		RETURN BOOLEAN;
   /**
    * [description needed]
    *
    * @param p_data_feed_id     [description needed]
    * @param p_data_feed_prefix [description needed]
    * @param p_data_feed_desc   [description needed]
    * @param p_db_office_id     [description needed]
    *
    * @return [description needed]
    */
	FUNCTION create_data_feed (p_data_feed_id 		IN VARCHAR2,
										p_data_feed_prefix	IN VARCHAR2,
										p_data_feed_desc		IN VARCHAR2,
										p_db_office_id 		IN VARCHAR2 DEFAULT NULL
									  )
		RETURN NUMBER;
   /**
    * [description needed]
    *
    * @param p_data_stream_id      [description needed]
    * @param p_data_feed_id        [description needed]
    * @param p_stream_db_office_id [description needed]
    * @param p_feed_db_office_id   [description needed]
    */
	PROCEDURE assign_data_feed (
		p_data_stream_id			IN VARCHAR2,
		p_data_feed_id 			IN VARCHAR2,
		p_stream_db_office_id	IN VARCHAR2 DEFAULT NULL,
		p_feed_db_office_id		IN VARCHAR2 DEFAULT NULL
   );
   /**
    * [description needed]
    *
    * @param p_data_feed_id        [description needed]
    * @param p_feed_db_office_id   [description needed]
    */
	PROCEDURE unassign_data_feed (
		p_data_feed_id 		 IN VARCHAR2,
		p_feed_db_office_id	 IN VARCHAR2 DEFAULT NULL
	);
   /**
    * [description needed]
    *
    * @param p_data_feed_id  [description needed]
    * @param p_cascade_all   [description needed]
    * @param p_db_office_id  [description needed]
    */
	PROCEDURE delete_data_feed (p_data_feed_id	IN VARCHAR2,
										 p_cascade_all 	IN VARCHAR2 DEFAULT 'F',
										 p_db_office_id	IN VARCHAR2 DEFAULT NULL
										);
   /**
    * [description needed]
    *
    * @param p_shef_data_feeds [description needed]
    * @param p_db_office_id    [description needed]
    */
	PROCEDURE cat_shef_data_feeds (
		p_shef_data_feeds 	  OUT SYS_REFCURSOR,
		p_db_office_id 	  IN		VARCHAR2 DEFAULT NULL
	);
   /**
    * [description needed]
    *
    * @param p_db_office_id [description needed]
    *
    * @return [description needed]
    */
	FUNCTION cat_shef_data_feeds_tab (p_db_office_id IN VARCHAR2 DEFAULT NULL)
		RETURN cat_data_feed_tab_t
		PIPELINED;
   /**
    * [description needed]
    *
    * @param p_data_feed_id     [description needed]
    * @param p_data_feed_prefix [description needed]
    * @param p_db_office_id     [description needed]
    */
	PROCEDURE set_data_feed_prefix (
		p_data_feed_id 		IN VARCHAR2,
		p_data_feed_prefix	IN VARCHAR2,
		p_db_office_id 		IN VARCHAR2 DEFAULT NULL
	);
   /**
    * [description needed]
    *
    * @param p_data_feed_id   [description needed]
    * @param p_data_feed_desc [description needed]
    * @param p_db_office_id   [description needed]
    */
	PROCEDURE set_data_feed_desc (p_data_feed_id 	 IN VARCHAR2,
											p_data_feed_desc	 IN VARCHAR2,
											p_db_office_id 	 IN VARCHAR2 DEFAULT NULL
										  );
   /**
    * [description needed]
    *
    *
    * @param p_data_feed_id_old [description needed]
    * @param p_data_feed_id_new [description needed]
    * @param p_db_office_id     [description needed]
    */
	PROCEDURE rename_data_feed (p_data_feed_id_old	 IN VARCHAR2,
										 p_data_feed_id_new	 IN VARCHAR2,
										 p_db_office_id		 IN VARCHAR2 DEFAULT NULL
										);
   /**
    * [description needed]
    *
    * @param p_data_stream_id   [description needed]
    * @param p_data_feed_id     [description needed]
    * @param p_data_feed_prefix [description needed]
    * @param p_data_feed_desc   [description needed]
    * @param p_db_office_id     [description needed]
    */
	PROCEDURE convert_data_stream_to_feed (
		p_data_stream_id		IN VARCHAR2,
		p_data_feed_id 		IN VARCHAR2 DEFAULT NULL,
		p_data_feed_prefix	IN VARCHAR2 DEFAULT NULL,
		p_data_feed_desc		IN VARCHAR2 DEFAULT NULL,
		p_db_office_id 		IN VARCHAR2 DEFAULT NULL
	);

	-- DATA STREAMS
	-- DATA FEEDS
	-- MIXED -->reserved for future use when mgt style can be set for each
	--  data stream.
   /**
    * [description needed]
    *
    * @param p_db_office_id [description needed]
    *
    * @return [description needed]
    */
	FUNCTION get_data_stream_mgt_style (
		p_db_office_id IN VARCHAR2 DEFAULT NULL
	)
		RETURN VARCHAR2;
   /**
    * [description needed]
    *
    * @param p_data_stream_id [description needed]
    * @param p_db_office_id   [description needed]
    *
    * @return [description needed]
    */
	FUNCTION get_data_stream_state (
		p_data_stream_id	 IN VARCHAR2,
		p_db_office_id 	 IN VARCHAR2 DEFAULT NULL
	)
		RETURN VARCHAR2;
   /**
    * [description needed]
    *
    * @param p_data_stream_mgt_style [description needed]
    * @param p_db_office_id          [description needed]
    */
	PROCEDURE set_data_stream_mgt_style (
		p_data_stream_mgt_style   IN VARCHAR2,
		p_db_office_id 			  IN VARCHAR2 DEFAULT NULL
	);

	-----------------------------------------------------------------------------
	-- Messaging Routines
	-----------------------------------------------------------------------------
   /**
    * Posts a notification message about a data stream state change
    *
    * @see constant data_stream_state_startup
    * @see constant data_stream_state_shutdown
    * @see constant data_stream_state_active
    * @see constant data_stream_state_inactive
    *
    * @param p_data_stream_id The data stream identifier
    * @param p_new_state      The new data stream state
    * @param p_old_state      The old data stream state, if known
    * @param p_office_id      The office using the data stream. If not specified or NULL, the session user's default office is used
    */
	PROCEDURE notify_data_stream_state (
		p_data_stream_id	 IN VARCHAR2,
		p_new_state 		 IN VARCHAR2,
		p_old_state 		 IN VARCHAR2 DEFAULT NULL,
		p_office_id 		 IN VARCHAR2 DEFAULT NULL
	);
   /**
    * Confirms receipt of a data stream state change message
    *
    * @see constant data_stream_state_startup
    * @see constant data_stream_state_shutdown
    * @see constant data_stream_state_active
    * @see constant data_stream_state_inactive
    *
    * @param p_component      The CWMS component confirming receipt of the message
    * @param p_instance       The instance of the CWMS component confirming the receipt of the message
    * @param p_host           The system on which the confirming component is executing
    * @param p_port           The port at which to contact the confirming component, if applicable
    * @param p_data_stream_id The data stream identifier
    * @param p_new_state      The new data stream state
    * @param p_old_state      The old data stream state, if known
    * @param p_office_id      The office using the data stream. If not specified or NULL, the session user's default office is used
    */
	PROCEDURE confirm_data_stream_state (
		p_component 		 IN VARCHAR2,
		p_instance			 IN VARCHAR2,
		p_host				 IN VARCHAR2,
		p_port				 IN INTEGER,
		p_data_stream_id	 IN VARCHAR2,
		p_new_state 		 IN VARCHAR2,
		p_old_state 		 IN VARCHAR2 DEFAULT NULL,
		p_office_id 		 IN VARCHAR2 DEFAULT NULL
	);
   /**
    * Posts a notification message stating the processing criteria have been modified
    *
    * @param p_data_stream_id The data stream identifier
    * @param p_office_id      The office using the data stream. If not specified or NULL, the session user's default office is used
    */
	PROCEDURE notify_criteria_modified (
		p_data_stream_id	 IN VARCHAR2,
		p_office_id 		 IN VARCHAR2 DEFAULT NULL
	);
   /**
    * Confirms receipt of a criteria modified message
    *
    * @param p_component      The CWMS component confirming receipt of the message
    * @param p_instance       The instance of the CWMS component confirming the receipt of the message
    * @param p_host           The system on which the confirming component is executing
    * @param p_port           The port at which to contact the confirming component, if applicable
    * @param p_data_stream_id The data stream identifier
    * @param p_office_id      The office using the data stream. If not specified or NULL, the session user's default office is used
    */
	PROCEDURE confirm_criteria_reloaded (
		p_component 		 IN VARCHAR2,
		p_instance			 IN VARCHAR2,
		p_host				 IN VARCHAR2,
		p_port				 IN INTEGER,
		p_data_stream_id	 IN VARCHAR2,
		p_office_id 		 IN VARCHAR2 DEFAULT NULL
	);
   /**
    * [description needed]
    *
    * @param p_data_stream_id [description needed]
    * @param p_db_office_id   [description needed]
    *
    * @return [description needed]
    */
	FUNCTION get_use_db_shef_spec_mapping (
		p_data_stream_id	 IN VARCHAR2,
		p_db_office_id 	 IN VARCHAR2 DEFAULT NULL
	)
		RETURN BOOLEAN;
   /**
    * [description needed]
    *
    * @param p_boolean        [description needed]
    * @param p_data_stream_id [description needed]
    * @param p_db_office_id   [description needed]
    */
	PROCEDURE set_use_db_shef_spec_mapping (
		p_boolean			 IN BOOLEAN,
		p_data_stream_id	 IN VARCHAR2,
		p_db_office_id 	 IN VARCHAR2 DEFAULT NULL
	);
   /**
    * [description needed]
    *
    * @param p_use_db_crit    [description needed]
    * @param p_crit_file      [description needed]
    * @param p_use_db_otf     [description needed]
    * @param p_otf_file       [description needed]
    * @param p_data_stream_id [description needed]
    * @param p_db_office_id   [description needed]
    */
	PROCEDURE get_process_shefit_files (
		p_use_db_crit			 OUT VARCHAR2,
		p_crit_file 			 OUT CLOB,
		p_use_db_otf			 OUT VARCHAR2,
		p_otf_file				 OUT CLOB,
		p_data_stream_id	 IN	  VARCHAR2,
		p_db_office_id 	 IN	  VARCHAR2 DEFAULT NULL
	);
END cwms_shef;
/
