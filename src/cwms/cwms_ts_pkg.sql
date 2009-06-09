/* Formatted on 11/16/2008 2:02:38 PM (QP5 v5.115.810.9015) */
CREATE OR REPLACE PACKAGE cwms_ts
AS
   TYPE number_array
   IS
      TABLE OF NUMBER
         INDEX BY BINARY_INTEGER;

   TYPE double_array
   IS
      TABLE OF BINARY_DOUBLE
         INDEX BY BINARY_INTEGER;

   function get_max_open_cursors return integer;
   
   FUNCTION get_cwms_ts_id (p_cwms_ts_id IN varchar2, p_office_id IN varchar2
   )
      RETURN VARCHAR2;

   FUNCTION get_db_unit_id (p_cwms_ts_id IN varchar2)
      RETURN VARCHAR2;

   FUNCTION get_time_on_after_interval (p_datetime IN date,
                                        p_ts_offset IN number,
                                        p_ts_interval IN number
   )
      RETURN DATE;

   FUNCTION get_time_on_before_interval (p_datetime IN date,
                                         p_ts_offset IN number,
                                         p_ts_interval IN number
   )
      RETURN DATE;

   FUNCTION get_parameter_code (p_base_parameter_id IN varchar2,
                                p_sub_parameter_id IN varchar2,
                                p_office_id IN varchar2 DEFAULT NULL ,
                                p_create IN varchar2 DEFAULT 'T'
   )
      RETURN NUMBER;

   FUNCTION get_parameter_code (p_base_parameter_code IN number,
                                p_sub_parameter_id IN varchar2,
                                p_office_code IN number,
                                p_create IN boolean DEFAULT TRUE
   )
      RETURN NUMBER;

   FUNCTION get_parameter_code (p_cwms_ts_code IN number)
      RETURN NUMBER;

   FUNCTION get_base_parameter_code (p_cwms_ts_code IN number)
      RETURN NUMBER;

   FUNCTION get_parameter_type_code (p_cwms_ts_code IN number)
      RETURN NUMBER;

   FUNCTION get_db_office_code (p_cwms_ts_code IN number)
      RETURN NUMBER;

   FUNCTION get_parameter_id (p_cwms_ts_code IN number)
      RETURN VARCHAR2;

   FUNCTION get_base_parameter_id (p_cwms_ts_code IN number)
      RETURN VARCHAR2;

   FUNCTION get_parameter_type_id (p_cwms_ts_code IN number)
      RETURN VARCHAR2;

   FUNCTION get_db_office_id (p_cwms_ts_code IN number)
      RETURN VARCHAR2;

   --   FUNCTION get_ts_ni_hash (
   --      p_parameter_code        IN   NUMBER,
   --      p_parameter_type_code   IN   NUMBER,
   --      p_duration_code         IN   NUMBER
   --   )
   --      RETURN VARCHAR2;

   --   FUNCTION create_ts_ni_hash (
   --      p_parameter_id        IN   VARCHAR2,
   --      p_parameter_type_id   IN   VARCHAR2,
   --      p_duration_id         IN   VARCHAR2,
   --      p_db_office_id        IN   VARCHAR2 DEFAULT NULL
   --   )
   --      RETURN VARCHAR2;
   FUNCTION get_location_id (p_cwms_ts_id IN varchar2,
                             p_db_office_id IN varchar2
   )
      RETURN VARCHAR2;

   FUNCTION get_location_id (p_cwms_ts_code IN number)
      RETURN VARCHAR2;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- DELETE_TS -
   --
   PROCEDURE delete_ts (p_cwms_ts_id IN varchar2,
                        p_delete_action IN VARCHAR2 DEFAULT cwms_util.delete_ts_id
                                                      ,
                        p_db_office_id IN varchar2 DEFAULT NULL
   );

   PROCEDURE delete_ts (p_cwms_ts_id IN varchar2,
                        p_delete_action IN VARCHAR2 DEFAULT cwms_util.delete_ts_id
                                                      ,
                        p_db_office_code IN number DEFAULT NULL
   );

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- SET_TS_TIME_ZONE -
   --
   PROCEDURE set_ts_time_zone (p_ts_code        IN NUMBER,
                               p_time_zone_name IN VARCHAR2
   );

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- SET_TS_TIME_ZONE -
   --
   PROCEDURE set_tsid_time_zone (p_ts_id          IN VARCHAR2,
                                 p_time_zone_name IN VARCHAR2,
                                 p_office_id      IN VARCHAR2 DEFAULT NULL
   );

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- GET_TS_TIME_ZONE -
   --
   FUNCTION get_ts_time_zone (p_ts_code IN NUMBER
   )
   RETURN VARCHAR2;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- GET_TS_TIME_ZONE -
   --
   FUNCTION get_tsid_time_zone (p_ts_id     IN VARCHAR2,
                                p_office_id IN VARCHAR2 DEFAULT NULL
   )
   RETURN VARCHAR2;

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- CREATE_TS -
   --
   --v 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvvvv -
   PROCEDURE create_ts (p_office_id IN varchar2,
                        p_cwms_ts_id IN varchar2,
                        p_utc_offset IN number DEFAULT NULL
   );

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- CREATE_TS -
   --
   PROCEDURE create_ts (p_cwms_ts_id IN varchar2,
                        p_utc_offset IN number DEFAULT NULL ,
                        p_interval_forward IN number DEFAULT NULL ,
                        p_interval_backward IN number DEFAULT NULL ,
                        p_versioned IN varchar2 DEFAULT 'F' ,
                        p_active_flag IN varchar2 DEFAULT 'T' ,
                        p_office_id IN varchar2 DEFAULT NULL
   );

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- CREATE_TS -
   --
   PROCEDURE create_ts_tz (p_cwms_ts_id IN varchar2,
                           p_utc_offset IN number DEFAULT NULL ,
                           p_interval_forward IN number DEFAULT NULL ,
                           p_interval_backward IN number DEFAULT NULL ,
                           p_versioned IN varchar2 DEFAULT 'F' ,
                           p_active_flag IN varchar2 DEFAULT 'T' ,
                           p_time_zone_name IN VARCHAR2 DEFAULT 'UTC',
                           p_office_id IN varchar2 DEFAULT NULL
   );

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- CREATE_TS_CODE - v2.0 -
   --
   PROCEDURE create_ts_code (p_ts_code OUT number,
                             p_cwms_ts_id IN varchar2,
                             p_utc_offset IN number DEFAULT NULL ,
                             p_interval_forward IN number DEFAULT NULL ,
                             p_interval_backward IN number DEFAULT NULL ,
                             p_versioned IN varchar2 DEFAULT 'F' ,
                             p_active_flag IN varchar2 DEFAULT 'T' ,
                             p_fail_if_exists IN varchar2 DEFAULT 'T' ,
                             p_office_id IN varchar2 DEFAULT NULL
   );

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- CREATE_TS_CODE - v2.0 -
   --
   PROCEDURE create_ts_code_tz (p_ts_code OUT number,
                                p_cwms_ts_id IN varchar2,
                                p_utc_offset IN number DEFAULT NULL ,
                                p_interval_forward IN number DEFAULT NULL ,
                                p_interval_backward IN number DEFAULT NULL ,
                                p_versioned IN varchar2 DEFAULT 'F' ,
                                p_active_flag IN varchar2 DEFAULT 'T' ,
                                p_fail_if_exists IN varchar2 DEFAULT 'T' ,
                                p_time_zone_name IN VARCHAR2 DEFAULT 'UTC',
                                p_office_id IN varchar2 DEFAULT NULL
   );

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- RETREIVE_TS_OUT - v2.0 -
   --
   PROCEDURE retrieve_ts_out (p_at_tsv_rc OUT sys_refcursor,
                              p_cwms_ts_id_out OUT varchar2,
                              p_units_out OUT varchar2,
                              p_cwms_ts_id IN varchar2,
                              p_units IN varchar2,
                              p_start_time IN date,
                              p_end_time IN date,
                              p_time_zone IN varchar2 DEFAULT 'UTC' ,
                              p_trim IN varchar2 DEFAULT 'F' ,
                              p_start_inclusive IN varchar2 DEFAULT 'T' ,
                              p_end_inclusive IN varchar2 DEFAULT 'T' ,
                              p_previous IN varchar2 DEFAULT 'F' ,
                              p_next IN varchar2 DEFAULT 'F' ,
                              p_version_date IN date DEFAULT NULL ,
                              p_max_version IN varchar2 DEFAULT 'T' ,
                              p_office_id IN varchar2 DEFAULT NULL
   );

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- RETREIVE_TS - v1.4 -
   --
   PROCEDURE retrieve_ts (p_at_tsv_rc IN OUT sys_refcursor,
                          p_units IN varchar2,
                          p_officeid IN varchar2,
                          p_cwms_ts_id IN varchar2,
                          p_start_time IN date,
                          p_end_time IN date,
                          p_timezone IN varchar2 DEFAULT 'GMT' ,
                          p_trim IN number DEFAULT cwms_util.false_num ,
                          p_inclusive IN number DEFAULT NULL ,
                          p_versiondate IN date DEFAULT NULL ,
                          p_max_version IN number DEFAULT cwms_util.true_num
   );

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- RETREIVE_TS_2 - v1.4 -
   --
   PROCEDURE retrieve_ts_2 (p_at_tsv_rc OUT sys_refcursor,
                            p_units IN varchar2,
                            p_officeid IN varchar2,
                            p_cwms_ts_id IN varchar2,
                            p_start_time IN date,
                            p_end_time IN date,
                            p_timezone IN varchar2 DEFAULT 'GMT' ,
                            p_trim IN number DEFAULT cwms_util.false_num ,
                            p_inclusive IN number DEFAULT NULL ,
                            p_versiondate IN date DEFAULT NULL ,
                            p_max_version IN NUMBER DEFAULT cwms_util.true_num

   );

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- RETREIVE_TS - v2.0 -
   --
   PROCEDURE retrieve_ts (p_at_tsv_rc OUT sys_refcursor,
                          p_cwms_ts_id IN varchar2,
                          p_units IN varchar2,
                          p_start_time IN date,
                          p_end_time IN date,
                          p_time_zone IN varchar2 DEFAULT 'UTC' ,
                          p_trim IN varchar2 DEFAULT 'F' ,
                          p_start_inclusive IN varchar2 DEFAULT 'T' ,
                          p_end_inclusive IN varchar2 DEFAULT 'T' ,
                          p_previous IN varchar2 DEFAULT 'F' ,
                          p_next IN varchar2 DEFAULT 'F' ,
                          p_version_date IN date DEFAULT NULL ,
                          p_max_version IN varchar2 DEFAULT 'T' ,
                          p_office_id IN varchar2 DEFAULT NULL
   );

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- RETREIVE_TS_MULTI - v2.0 -
   --
   PROCEDURE retrieve_ts_multi (p_at_tsv_rc OUT sys_refcursor,
                                p_timeseries_info IN timeseries_req_array,
                                p_time_zone IN varchar2 DEFAULT 'UTC' ,
                                p_trim IN varchar2 DEFAULT 'F' ,
                                p_start_inclusive IN varchar2 DEFAULT 'T' ,
                                p_end_inclusive IN varchar2 DEFAULT 'T' ,
                                p_previous IN varchar2 DEFAULT 'F' ,
                                p_next IN varchar2 DEFAULT 'F' ,
                                p_version_date IN date DEFAULT NULL ,
                                p_max_version IN varchar2 DEFAULT 'T' ,
                                p_office_id IN varchar2 DEFAULT NULL
   );

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- shift_for_localtime
   --
   function shift_for_localtime(
      p_date_time in date, 
      p_tz_name   in varchar2)
      return date;
	--   
	--
	--*******************************************************************   --
	--*******************************************************************   --
	--
	-- CLEAN_QUALITY_CODE -
	--  
		function clean_quality_code (
	      p_quality_code in integer)
	      return integer result_cache;
	      
   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- STORE_TS -
   --
   --v 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvvvv -
   PROCEDURE store_ts (p_office_id IN varchar2,
                       p_cwms_ts_id IN varchar2,
                       p_units IN varchar2,
                       p_timeseries_data IN tsv_array,
                       p_store_rule IN varchar2 DEFAULT NULL ,
                       p_override_prot IN number DEFAULT cwms_util.false_num ,
                       p_versiondate IN date DEFAULT cwms_util.non_versioned
   );

   --^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^^^^ -
   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- STORE_TS -
   --
   PROCEDURE store_ts (p_cwms_ts_id IN varchar2,
                       p_units IN varchar2,
                       p_timeseries_data IN tsv_array,
                       p_store_rule IN varchar2 DEFAULT NULL ,
                       p_override_prot IN varchar2 DEFAULT 'F' ,
                       p_version_date IN date DEFAULT cwms_util.non_versioned ,
                       p_office_id IN varchar2 DEFAULT NULL
   );

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- STORE_TS - This version is for Python/CxOracle
   --
   PROCEDURE store_ts (p_cwms_ts_id IN varchar2,
                       p_units IN varchar2,
                       p_times IN number_array,
                       p_values IN double_array,
                       p_qualities IN number_array,
                       p_store_rule IN varchar2 DEFAULT NULL ,
                       p_override_prot IN varchar2 DEFAULT 'F' ,
                       p_version_date IN date DEFAULT cwms_util.non_versioned ,
                       p_office_id IN varchar2 DEFAULT NULL
   );

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- STORE_TS - This version is for Java/Jython bypassing TIMESTAMPTZ type
   --
   PROCEDURE store_ts (p_cwms_ts_id IN varchar2,
                       p_units IN varchar2,
                       p_times IN number_tab_t,
                       p_values IN number_tab_t,
                       p_qualities IN number_tab_t,
                       p_store_rule IN varchar2 DEFAULT NULL ,
                       p_override_prot IN varchar2 DEFAULT 'F' ,
                       p_version_date IN date DEFAULT cwms_util.non_versioned ,
                       p_office_id IN varchar2 DEFAULT NULL
   );

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- STORE_TS_MULTI -
   --
   PROCEDURE store_ts_multi (p_timeseries_array IN timeseries_array,
                             p_store_rule IN varchar2 DEFAULT NULL ,
                             p_override_prot IN varchar2 DEFAULT 'F' ,
                             p_version_date IN DATE DEFAULT cwms_util.non_versioned
                                                      ,
                             p_office_id IN varchar2 DEFAULT NULL
   );

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   PROCEDURE update_ts_id (p_ts_code IN number,
                           p_interval_utc_offset IN number DEFAULT NULL , -- in minutes.
                           p_snap_forward_minutes IN number DEFAULT NULL ,
                           p_snap_backward_minutes IN number DEFAULT NULL ,
                           p_local_reg_time_zone_id IN varchar2 DEFAULT NULL ,
                           p_ts_active_flag IN varchar2 DEFAULT NULL
   );

   PROCEDURE update_ts_id (p_cwms_ts_id IN varchar2,
                           p_interval_utc_offset IN number DEFAULT NULL , -- in minutes.
                           p_snap_forward_minutes IN number DEFAULT NULL ,
                           p_snap_backward_minutes IN number DEFAULT NULL ,
                           p_local_reg_time_zone_id IN varchar2 DEFAULT NULL ,
                           p_ts_active_flag IN varchar2 DEFAULT NULL ,
                           p_db_office_id IN varchar2 DEFAULT NULL
   );

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- RENAME_TS_JAVA -
   --
   --v 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvv 1.4 vvvvvv -
   PROCEDURE rename_ts (p_office_id IN varchar2,
                        p_timeseries_desc_old IN varchar2,
                        p_timeseries_desc_new IN varchar2
   );

   --^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^ 1.4 ^^^^^^^ -
   --
   PROCEDURE rename_ts (p_cwms_ts_id_old IN varchar2,
                        p_cwms_ts_id_new IN varchar2,
                        p_utc_offset_new IN number DEFAULT NULL ,
                        p_office_id IN varchar2 DEFAULT NULL
   );

   --
   --*******************************************************************   --
   --*******************************************************************   --
   --
   -- PARSE_TS -
   --
   PROCEDURE parse_ts (p_cwms_ts_id IN varchar2,
                       p_base_location_id OUT varchar2,
                       p_sub_location_id OUT varchar2,
                       p_base_parameter_id OUT varchar2,
                       p_sub_parameter_id OUT varchar2,
                       p_parameter_type_id OUT varchar2,
                       p_interval_id OUT varchar2,
                       p_duration_id OUT varchar2,
                       p_version_id OUT varchar2
   );

   PROCEDURE zretrieve_ts (p_at_tsv_rc IN OUT sys_refcursor,
                           p_units IN varchar2,
                           p_cwms_ts_id IN varchar2,
                           p_start_time IN date,
                           p_end_time IN date,
                           p_trim IN varchar2 DEFAULT 'F' ,
                           p_inclusive IN number DEFAULT NULL ,
                           p_version_date IN date DEFAULT NULL ,
                           p_max_version IN varchar2 DEFAULT 'T' ,
                           p_db_office_id IN varchar2 DEFAULT NULL
   );

   PROCEDURE zstore_ts (p_cwms_ts_id IN varchar2,
                        p_units IN varchar2,
                        p_timeseries_data IN ztsv_array,
                        p_store_rule IN varchar2 DEFAULT NULL ,
                        p_override_prot IN varchar2 DEFAULT 'F' ,
                        p_version_date IN DATE DEFAULT cwms_util.non_versioned,
                        p_office_id IN varchar2 DEFAULT NULL
   );

   PROCEDURE zstore_ts_multi (p_timeseries_array IN ztimeseries_array,
                              p_store_rule IN varchar2 DEFAULT NULL ,
                              p_override_prot IN varchar2 DEFAULT 'F' ,
                              p_version_date IN DATE DEFAULT cwms_util.non_versioned,
                              p_office_id IN varchar2 DEFAULT NULL
   );

   PROCEDURE zretrieve_ts_java (p_transaction_time OUT date,
                                p_at_tsv_rc OUT sys_refcursor,
                                p_units_out OUT varchar2,
                                p_cwms_ts_id_out OUT varchar2,
                                p_units_in IN varchar2,
                                p_cwms_ts_id_in IN varchar2,
                                p_start_time IN date,
                                p_end_time IN date,
                                p_trim IN varchar2 DEFAULT 'F' ,
                                p_inclusive IN number DEFAULT NULL ,
                                p_version_date IN date DEFAULT NULL ,
                                p_max_version IN varchar2 DEFAULT 'T' ,
                                p_db_office_id IN varchar2 DEFAULT NULL
   );

   PROCEDURE create_parameter_id (p_parameter_id IN varchar2,
                                  p_db_office_id IN varchar2 DEFAULT NULL
   );

   PROCEDURE delete_parameter_id (p_parameter_id IN varchar2,
                                  p_db_office_id IN varchar2 DEFAULT NULL
   );

   PROCEDURE rename_parameter_id (p_parameter_id_old IN varchar2,
                                  p_parameter_id_new IN varchar2,
                                  p_db_office_id IN varchar2 DEFAULT NULL
   );
   
END;
/
show errors;
COMMIT;
