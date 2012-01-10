/* Formatted on 1/4/2012 11:20:47 AM (QP5 v5.185.11230.41888) */
CREATE OR REPLACE PACKAGE cwms_shef
AS
   default_update_idle_period   CONSTANT NUMBER := 60;           -- 60 minutes
	data_stream_state_startup	  CONSTANT VARCHAR2 (7) := 'Startup';
	data_stream_state_shutdown   CONSTANT VARCHAR2 (8) := 'Shutdown';
	data_stream_state_active	  CONSTANT VARCHAR2 (6) := 'Active';
	data_stream_state_inactive   CONSTANT VARCHAR2 (8) := 'Inactive';
	data_stream_states			  CONSTANT str_tab_t
		:= str_tab_t (data_stream_state_startup,
						  data_stream_state_shutdown,
						  data_stream_state_active,
                    data_stream_state_inactive) ;

	data_stream_mgt_style		  CONSTANT VARCHAR2 (16) := 'DATA STREAMS';
	data_feed_mgt_style			  CONSTANT VARCHAR2 (16) := 'DATA FEEDS';
	--
	ignore_shef_spec				  CONSTANT VARCHAR2 (2) := '//';
	-- PROCEDURE clean_at_shef_crit_file p_action constants.
	ten_file_limit 				  CONSTANT VARCHAR2 (32) := 'TEN FILE LIMIT';
	-- default value.
	delete_all						  CONSTANT VARCHAR2 (32) := 'DELETE ALL';
	max_shef_loc_length			  CONSTANT NUMBER := 8;

	TYPE cat_data_stream_rec_t IS RECORD
	(
		data_stream_code	 NUMBER,
		data_stream_id 	 VARCHAR2 (16),
		data_stream_desc	 VARCHAR2 (128),
		active_flag 		 VARCHAR2 (1),
		office_id			 VARCHAR2 (16)
	);

	TYPE cat_data_stream_tab_t IS TABLE OF cat_data_stream_rec_t;

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

	TYPE cat_data_feed_tab_t IS TABLE OF cat_data_feed_rec_t;

	TYPE cat_shef_tz_rec_t IS RECORD
	(
		shef_time_zone_id 	 VARCHAR2 (16),
		shef_time_zone_desc	 VARCHAR2 (64)
	);

	TYPE cat_shef_tz_tab_t IS TABLE OF cat_shef_tz_rec_t;

	TYPE cat_shef_dur_rec_t IS RECORD
	(
		shef_duration_code		VARCHAR2 (1),
		shef_duration_desc		VARCHAR2 (128),
		shef_duration_numeric	VARCHAR2 (4),
		cwms_duration_id			VARCHAR2 (16)
	);

	TYPE cat_shef_dur_tab_t IS TABLE OF cat_shef_dur_rec_t;

	TYPE cat_shef_units_rec_t IS RECORD (shef_unit_id VARCHAR2 (16));

	TYPE cat_shef_units_tab_t IS TABLE OF cat_shef_units_rec_t;

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

	TYPE cat_shef_pe_codes_tab_t IS TABLE OF cat_shef_pe_codes_rec_t;

	TYPE cat_shef_extremum_rec_t IS RECORD
	(
		shef_e_code   VARCHAR2 (1),
		description   VARCHAR2 (32),
		duration_id   VARCHAR2 (16)
	);

	TYPE cat_shef_extremum_tab_t IS TABLE OF cat_shef_extremum_rec_t;



   TYPE cat_shef_decode_spec_rec_t IS RECORD
   (
      ts_code                 NUMBER,
      cwms_ts_id              VARCHAR2 (183 BYTE),
      db_office_id            VARCHAR2 (16 BYTE),
      data_stream_id          VARCHAR2 (16 BYTE),
      stream_db_office_id     VARCHAR2 (16 BYTE),
      data_feed_id            VARCHAR2 (32 BYTE),
      feed_db_office_id       VARCHAR2 (16 BYTE),
      data_feed_prefix        VARCHAR2 (3 BYTE),
      loc_group_id            VARCHAR2 (65 BYTE),
      loc_category_id         VARCHAR2 (32 BYTE),
      loc_alias_id            VARCHAR2 (256 BYTE),
      shef_loc_id             VARCHAR2 (128 BYTE),
      shef_pe_code            VARCHAR2 (2 BYTE),
      shef_tse_code           VARCHAR2 (3 BYTE),
      shef_duration_code      VARCHAR2 (1 BYTE),
      shef_duration_numeric   VARCHAR2 (4 BYTE),
      shef_time_zone_id       VARCHAR2 (16 BYTE),
      dl_time                 VARCHAR2 (1 BYTE),
      unit_id                 VARCHAR2 (16 BYTE),
      unit_system             VARCHAR2 (2 BYTE),
      interval_utc_offset     NUMBER,
      interval_forward        NUMBER,
      interval_backward       NUMBER,
      ts_active_flag          VARCHAR2 (1 BYTE),
      net_ts_active_flag      CHAR (1 BYTE),
      ignore_shef_spec        VARCHAR2 (1 BYTE),
      shef_spec               VARCHAR2 (271 BYTE),
      location_id             VARCHAR2 (49 BYTE),
      parameter_id            VARCHAR2 (49 BYTE),
      parameter_type_id       VARCHAR2 (16 BYTE),
      interval_id             VARCHAR2 (16 BYTE),
      duration_id             VARCHAR2 (16 BYTE),
      version_id              VARCHAR2 (32 BYTE),
      data_stream_code        NUMBER,
      shef_crit_line          VARCHAR2 (4000 BYTE)
   );

   TYPE cat_shef_decode_spec_tab_t IS TABLE OF cat_shef_decode_spec_rec_t;

	-- FUNCTION get_update_crit_file_flag (p_data_stream_id	IN VARCHAR2,
	-- 				p_db_office_id   IN VARCHAR2
	-- 				 )
	--  RETURN VARCHAR2;
	--
	-- PROCEDURE set_update_crit_file_flag (
	--  p_update_crit_file_flag	IN VARCHAR2,
	--  p_data_stream_id 	 IN VARCHAR2,
	--  p_db_office_id		IN VARCHAR2
	-- );


   PROCEDURE cat_shef_extremum_codes (
      p_shef_extremum_codes OUT SYS_REFCURSOR);

	PROCEDURE cat_shef_pe_codes (
		p_shef_pe_codes		OUT SYS_REFCURSOR,
      p_db_office_id    IN     VARCHAR2 DEFAULT NULL);

	TYPE cat_shef_crit_lines_rec_t IS RECORD (shef_crit_line VARCHAR2 (400));

	TYPE cat_shef_crit_lines_tab_t IS TABLE OF cat_shef_crit_lines_rec_t;

	PROCEDURE delete_local_pe_code (p_id_code 		 IN NUMBER,
                                   p_db_office_id   IN VARCHAR2 DEFAULT NULL);

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
      p_db_office_id            IN VARCHAR2 DEFAULT NULL);



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
      p_db_office_id            IN VARCHAR2 DEFAULT NULL);

	PROCEDURE delete_shef_spec (p_cwms_ts_id		  IN VARCHAR2,
										 p_data_stream_id   IN VARCHAR2,
                               p_db_office_id     IN VARCHAR2 DEFAULT NULL);

	-- left kernal must be unique.
    PROCEDURE store_data_stream (
        p_data_stream_id                  IN VARCHAR2,
        p_data_stream_desc              IN VARCHAR2 DEFAULT NULL,
        p_active_flag                      IN VARCHAR2 DEFAULT 'T',
        p_use_db_shef_spec_mapping   IN VARCHAR2 DEFAULT 'T',
        p_ignore_nulls                   IN VARCHAR2 DEFAULT 'T',
      p_db_office_id               IN VARCHAR2 DEFAULT NULL);

	PROCEDURE rename_data_stream (
		p_data_stream_id_old   IN VARCHAR2,
		p_data_stream_id_new   IN VARCHAR2,
      p_db_office_id         IN VARCHAR2 DEFAULT NULL);

	PROCEDURE delete_data_feed_shef_specs (
		p_data_feed_id   IN VARCHAR2,
      p_db_office_id   IN VARCHAR2 DEFAULT NULL);

	PROCEDURE delete_data_stream_shef_specs (
		p_data_stream_id	 IN VARCHAR2,
      p_db_office_id     IN VARCHAR2 DEFAULT NULL);

	PROCEDURE delete_data_stream (p_data_stream_id	 IN VARCHAR2,
											p_cascade_all		 IN VARCHAR2 DEFAULT 'F',
                                 p_db_office_id     IN VARCHAR2 DEFAULT NULL);

	PROCEDURE cat_shef_data_streams (
		p_shef_data_streams		 OUT SYS_REFCURSOR,
      p_db_office_id        IN     VARCHAR2 DEFAULT NULL);

	FUNCTION cat_shef_data_streams_tab (
      p_db_office_id IN VARCHAR2 DEFAULT NULL)
		RETURN cat_data_stream_tab_t
		PIPELINED;

	PROCEDURE cat_shef_time_zones (p_shef_time_zones OUT SYS_REFCURSOR);

	FUNCTION cat_shef_time_zones_tab
		RETURN cat_shef_tz_tab_t
		PIPELINED;

	FUNCTION cat_shef_durations_tab
		RETURN cat_shef_dur_tab_t
		PIPELINED;

	FUNCTION cat_shef_units_tab
		RETURN cat_shef_units_tab_t
		PIPELINED;

	FUNCTION cat_shef_extremum_tab
		RETURN cat_shef_extremum_tab_t
		PIPELINED;

   /**
    * [description needed]
    *
    * @param p_db_office_id [description needed]
    *
    * @return [description needed]
    */
	FUNCTION cat_shef_pe_codes_tab (p_db_office_id IN VARCHAR2 DEFAULT NULL)
		RETURN cat_shef_pe_codes_tab_t
		PIPELINED;

   /**
    * [description needed]
    *
    * @param p_data_stream_id   [description needed]
    * @param p_utc_version_date [description needed]
    * @param p_db_office_id     [description needed]
    *
    * @return [description needed]
    */
   FUNCTION get_shef_crit_file (
      p_data_stream_id     IN VARCHAR2,
										  p_utc_version_date   IN DATE DEFAULT NULL,
      p_db_office_id       IN VARCHAR2 DEFAULT NULL)
		RETURN CLOB;

	FUNCTION get_shef_duration_numeric (p_shef_duration_code IN VARCHAR2)
		RETURN VARCHAR2;

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
                                    p_criteria_record      IN     VARCHAR2);

	PROCEDURE cat_shef_crit_lines (
		p_shef_crit_lines 	  OUT SYS_REFCURSOR,
		p_data_stream_id	  IN		VARCHAR2,
      p_db_office_id      IN     VARCHAR2 DEFAULT NULL);

	FUNCTION cat_shef_crit_lines_tab (
		p_data_stream_id	 IN VARCHAR2,
      p_db_office_id     IN VARCHAR2 DEFAULT NULL)
		RETURN cat_shef_crit_lines_tab_t
		PIPELINED;

   FUNCTION cat_shef_crit_lines_tab (p_data_stream_code IN NUMBER)
      RETURN cat_shef_crit_lines_tab_t
      PIPELINED;

   FUNCTION cat_shef_decode_spec_tab (
      p_data_stream_id     IN VARCHAR2,
      p_utc_version_date   IN DATE DEFAULT NULL,
      p_date_rank         IN NUMBER DEFAULT NULL,
      p_db_office_id       IN VARCHAR2 DEFAULT NULL)
      RETURN cat_shef_decode_spec_tab_t
      PIPELINED;

	PROCEDURE store_shef_crit_file (
		p_data_stream_id	 IN VARCHAR2,
      p_db_office_id     IN VARCHAR2 DEFAULT NULL);

   FUNCTION get_data_stream_code (
      p_data_stream_id   IN VARCHAR2,
      p_db_office_id     IN VARCHAR2 DEFAULT NULL)
		RETURN NUMBER;

   FUNCTION is_crit_file_current (
      p_data_stream_id   IN VARCHAR2,
      p_db_office_id     IN VARCHAR2 DEFAULT NULL)
		RETURN BOOLEAN;

	FUNCTION is_data_stream_active (
		p_data_stream_id	 IN VARCHAR2,
      p_db_office_id     IN VARCHAR2 DEFAULT NULL)
		RETURN BOOLEAN;

	FUNCTION create_data_feed (p_data_feed_id 		IN VARCHAR2,
										p_data_feed_prefix	IN VARCHAR2,
										p_data_feed_desc		IN VARCHAR2,
                              p_db_office_id       IN VARCHAR2 DEFAULT NULL)
		RETURN NUMBER;

	PROCEDURE assign_data_feed (
		p_data_stream_id			IN VARCHAR2,
		p_data_feed_id 			IN VARCHAR2,
		p_stream_db_office_id	IN VARCHAR2 DEFAULT NULL,
      p_feed_db_office_id     IN VARCHAR2 DEFAULT NULL);

	PROCEDURE unassign_data_feed (
		p_data_feed_id 		 IN VARCHAR2,
      p_feed_db_office_id   IN VARCHAR2 DEFAULT NULL);

	PROCEDURE delete_data_feed (p_data_feed_id	IN VARCHAR2,
										 p_cascade_all 	IN VARCHAR2 DEFAULT 'F',
                               p_db_office_id   IN VARCHAR2 DEFAULT NULL);

	PROCEDURE cat_shef_data_feeds (
		p_shef_data_feeds 	  OUT SYS_REFCURSOR,
      p_db_office_id      IN     VARCHAR2 DEFAULT NULL);

	FUNCTION cat_shef_data_feeds_tab (p_db_office_id IN VARCHAR2 DEFAULT NULL)
		RETURN cat_data_feed_tab_t
		PIPELINED;

	PROCEDURE set_data_feed_prefix (
		p_data_feed_id 		IN VARCHAR2,
		p_data_feed_prefix	IN VARCHAR2,
      p_db_office_id       IN VARCHAR2 DEFAULT NULL);

	PROCEDURE set_data_feed_desc (p_data_feed_id 	 IN VARCHAR2,
											p_data_feed_desc	 IN VARCHAR2,
                                 p_db_office_id     IN VARCHAR2 DEFAULT NULL);

	PROCEDURE rename_data_feed (p_data_feed_id_old	 IN VARCHAR2,
										 p_data_feed_id_new	 IN VARCHAR2,
                               p_db_office_id       IN VARCHAR2 DEFAULT NULL);

	PROCEDURE convert_data_stream_to_feed (
		p_data_stream_id		IN VARCHAR2,
		p_data_feed_id 		IN VARCHAR2 DEFAULT NULL,
		p_data_feed_prefix	IN VARCHAR2 DEFAULT NULL,
		p_data_feed_desc		IN VARCHAR2 DEFAULT NULL,
      p_db_office_id       IN VARCHAR2 DEFAULT NULL);

	-- DATA STREAMS
	-- DATA FEEDS
	-- MIXED -->reserved for future use when mgt style can be set for each
	--  data stream.

	FUNCTION get_data_stream_mgt_style (
      p_db_office_id IN VARCHAR2 DEFAULT NULL)
		RETURN VARCHAR2;

	FUNCTION get_data_stream_state (
		p_data_stream_id	 IN VARCHAR2,
      p_db_office_id     IN VARCHAR2 DEFAULT NULL)
		RETURN VARCHAR2;

	PROCEDURE set_data_stream_mgt_style (
		p_data_stream_mgt_style   IN VARCHAR2,
      p_db_office_id            IN VARCHAR2 DEFAULT NULL);

	-----------------------------------------------------------------------------
	-- Messaging Routines
	-----------------------------------------------------------------------------
	PROCEDURE notify_data_stream_state (
		p_data_stream_id	 IN VARCHAR2,
		p_new_state 		 IN VARCHAR2,
		p_old_state 		 IN VARCHAR2 DEFAULT NULL,
      p_office_id        IN VARCHAR2 DEFAULT NULL);

	PROCEDURE confirm_data_stream_state (
		p_component 		 IN VARCHAR2,
		p_instance			 IN VARCHAR2,
		p_host				 IN VARCHAR2,
		p_port				 IN INTEGER,
		p_data_stream_id	 IN VARCHAR2,
		p_new_state 		 IN VARCHAR2,
		p_old_state 		 IN VARCHAR2 DEFAULT NULL,
      p_office_id        IN VARCHAR2 DEFAULT NULL);

	PROCEDURE notify_criteria_modified (
		p_data_stream_id	 IN VARCHAR2,
      p_office_id        IN VARCHAR2 DEFAULT NULL);

	PROCEDURE confirm_criteria_reloaded (
		p_component 		 IN VARCHAR2,
		p_instance			 IN VARCHAR2,
		p_host				 IN VARCHAR2,
		p_port				 IN INTEGER,
		p_data_stream_id	 IN VARCHAR2,
      p_office_id        IN VARCHAR2 DEFAULT NULL);

	FUNCTION get_use_db_shef_spec_mapping (
		p_data_stream_id	 IN VARCHAR2,
      p_db_office_id     IN VARCHAR2 DEFAULT NULL)
		RETURN BOOLEAN;

	PROCEDURE set_use_db_shef_spec_mapping (
		p_boolean			 IN BOOLEAN,
		p_data_stream_id	 IN VARCHAR2,
      p_db_office_id     IN VARCHAR2 DEFAULT NULL);

	PROCEDURE get_process_shefit_files (
		p_use_db_crit			 OUT VARCHAR2,
		p_crit_file 			 OUT CLOB,
		p_use_db_otf			 OUT VARCHAR2,
		p_otf_file				 OUT CLOB,
		p_data_stream_id	 IN	  VARCHAR2,
      p_db_office_id     IN     VARCHAR2 DEFAULT NULL);



	PROCEDURE set_ds_state (p_data_stream_id		 IN VARCHAR2,
									p_data_stream_state	 IN VARCHAR2,
                           p_db_office_id        IN VARCHAR2 DEFAULT NULL);

   PROCEDURE set_ds_update_time (p_update_idle_period    IN NUMBER,
                                 p_update_time    IN VARCHAR2 DEFAULT NULL, -- time string e.g 21:15
											p_time_zone 	  IN VARCHAR2 DEFAULT 'UTC', -- time zone of p_update_time
                                 p_db_office_id   IN VARCHAR2 DEFAULT NULL);

	PROCEDURE get_ds_update_time (
      p_update_idle_period       OUT NUMBER,                  -- idle time in minutes
		p_update_time		  OUT VARCHAR2,					-- time string e.g 21:15
		p_time_zone 		  OUT VARCHAR2,			 -- time zone of p_update_time
      p_db_office_id   IN     VARCHAR2 DEFAULT NULL);


   PROCEDURE update_shef_spec_mapping;
   
   PROCEDURE start_update_shef_spec_map_job;
   
END cwms_shef;
/
